import asyncio
import hashlib
import uuid
from io import BytesIO
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers
from app.modules.correspondence import attachment_service as module
from app.modules.correspondence.attachment_service import CorrespondenceAttachmentService
from app.modules.correspondence.initial_attachments import issue_grant, verify_grant

PAYLOAD = b"%PDF-1.4 test"

def manifest(name="test.pdf", payload=PAYLOAD):
    return [{"filename": name, "size": len(payload), "sha256": hashlib.sha256(payload).hexdigest()}]

@pytest.mark.parametrize("change", ["user", "document", "filename", "bytes", "signature", "expired"])
def test_grant_rejects_changed_scope(change, monkeypatch):
    from app.modules.correspondence import initial_attachments as grants
    token = issue_grant("u", "d", manifest())
    user, doc, name, data = "u", "d", "test.pdf", PAYLOAD
    if change == "user": user = "other"
    if change == "document": doc = "other"
    if change == "filename": name = "other.pdf"
    if change == "bytes": data += b"x"
    if change == "signature": token += "x"
    if change == "expired": monkeypatch.setattr(grants.time, "time", lambda: 99999999999)
    with pytest.raises(HTTPException) as error:
        verify_grant(token, user, doc, name, data)
    assert error.value.status_code == 403

def test_grant_accepts_only_declared_files():
    verify_grant(issue_grant("u", "d", manifest()), "u", "d", "test.pdf", PAYLOAD)

@pytest.fixture
def context(monkeypatch):
    db = Mock()
    user = SimpleNamespace(id=uuid.uuid4())
    doc = SimpleNamespace(id=uuid.uuid4(), document_type_id=uuid.uuid4(),
        created_by_user_id=user.id, status="ACTIVE", created_at=SimpleNamespace(year=2026))
    service = CorrespondenceAttachmentService(db)
    monkeypatch.setattr(service, "_get_correspondence_or_404", lambda *a, **k: doc)
    db.get.return_value = SimpleNamespace(behavior="ROUTE_SHEET")
    db.scalar.return_value = None
    storage = Mock()
    storage.exists.return_value = False
    monkeypatch.setattr(module, "get_storage_service", lambda: storage)
    monkeypatch.setattr(module, "get_settings", lambda: SimpleNamespace(max_attachment_size_bytes=32,
        max_attachment_size_mb=1, attachment_allowed_mime_types_list=["application/pdf"]))
    monkeypatch.setattr(service, "_to_response", lambda row: row)
    monkeypatch.setattr(module, "require_operation", Mock())
    monkeypatch.setattr(module.CorrespondenceService, "assert_current_unit_operator", Mock())
    return db, user, doc, service, storage

def upload(ctx, *, data=PAYLOAD, mime="application/pdf", token=None):
    db, user, doc, service, storage = ctx
    file = UploadFile(filename="test.pdf", file=BytesIO(data), headers=Headers({"content-type": mime}))
    return asyncio.run(service.upload_attachment(user, doc.id, file, initial_token=token))

@pytest.mark.parametrize("data,mime,status", [(b"", "application/pdf", 422),
    (b"x"*33,"application/pdf",413), (PAYLOAD,"pdf",422), (PAYLOAD,"text/html",422)])
def test_upload_validation(context, data, mime, status):
    with pytest.raises(HTTPException) as error: upload(context, data=data, mime=mime)
    assert error.value.status_code == status
    context[-1].put.assert_not_called()

def test_initial_grant_bypasses_only_operational_assignment(context):
    db,user,doc,service,storage = context
    module.CorrespondenceService.assert_current_unit_operator.side_effect=HTTPException(403)
    token=issue_grant(user.id,doc.id,manifest())
    row=upload(context,token=token)
    assert row.sha256 == hashlib.sha256(PAYLOAD).hexdigest()
    module.CorrespondenceService.assert_current_unit_operator.assert_not_called()
    storage.put.assert_called_once()
    with pytest.raises(HTTPException): upload(context)

def test_initial_grant_rejects_other_creator(context):
    db,user,doc,service,storage=context
    token=issue_grant(user.id,doc.id,manifest())
    doc.created_by_user_id=uuid.uuid4()
    with pytest.raises(HTTPException): upload(context,token=token)
    storage.put.assert_not_called()

@pytest.mark.parametrize("cleanup_fails", [False,True])
def test_failed_metadata_compensates_and_preserves_error(context,cleanup_fails):
    db,user,doc,service,storage=context
    original=RuntimeError("metadata failed")
    db.commit.side_effect=original
    if cleanup_fails: storage.delete.side_effect=RuntimeError("cleanup failed")
    with pytest.raises(RuntimeError) as error: upload(context)
    assert error.value is original
    db.rollback.assert_called_once()
    storage.delete.assert_called_once_with(storage.put.call_args.args[0])

def test_initial_retry_returns_existing_without_writing(context):
    db,user,doc,service,storage=context
    existing=SimpleNamespace(id=uuid.uuid4())
    db.scalar.return_value=existing
    assert upload(context,token=issue_grant(user.id,doc.id,manifest())) is existing
    storage.put.assert_not_called()
    db.commit.assert_not_called()


def test_collision_never_overwrites_existing_storage(context):
    context[-1].exists.return_value = True
    with pytest.raises(HTTPException) as error: upload(context)
    assert error.value.status_code == 409
    context[-1].put.assert_not_called()
    context[-1].delete.assert_not_called()

@pytest.mark.parametrize("behavior", ["GENERIC", "EDIE", "FUTURE"])
def test_initial_grant_rejects_unsupported_behavior(context, behavior):
    db,user,doc,service,storage=context
    db.get.return_value.behavior = behavior
    with pytest.raises(HTTPException): upload(context,token=issue_grant(user.id,doc.id,manifest()))
    storage.put.assert_not_called()


@pytest.mark.parametrize("behavior", ["ROUTE_SHEET", "INTERNAL_COMMUNICATION", "REPORT", "MEMORANDUM", "CIRCULAR"])
def test_creation_issues_file_bound_capability(behavior):
    from app.modules.correspondence.router import create_correspondence
    from app.modules.correspondence.schemas import CreateCorrespondenceRequest
    user=SimpleNamespace(id=uuid.uuid4())
    doc=SimpleNamespace(id=uuid.uuid4())
    service=Mock()
    service._db.get.return_value=SimpleNamespace(behavior=behavior)
    service.create_correspondence.return_value=doc
    body=CreateCorrespondenceRequest(correspondence_type="INTERNAL", document_type_id=uuid.uuid4(),
        priority="LOW", initial_attachments=manifest())
    result=create_correspondence(body,user,service)
    verify_grant(result.initial_attachment_token,user.id,doc.id,"test.pdf",PAYLOAD)
    service.create_correspondence.assert_called_once_with(user,body)
