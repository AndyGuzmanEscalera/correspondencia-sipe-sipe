import uuid
from sqlalchemy import select
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from tests.test_correspondence import _create_payload


def test_deactivation_filters_and_history_preserve_references(client, db, admin_headers, document_type, second_org_unit, second_employee, second_user, position):
    created = client.post('/correspondences', headers=admin_headers, json=_create_payload(document_type, 'Historia preservada', unit_id=second_org_unit.id, user_id=second_user.id))
    assert created.status_code == 201, created.text
    correspondence_id = uuid.UUID(created.json()['id'])
    movements_before = list(db.scalars(select(CorrespondenceMovement.id).where(CorrespondenceMovement.correspondence_id == correspondence_id)))
    targets = [
        ('users', second_user.id),
        ('employees', second_employee.id),
        ('organizational-units', second_org_unit.id),
        ('positions', position.id),
        ('document-types', document_type.id),
    ]
    changed = []
    try:
        for resource, item_id in targets:
            response = client.patch(f'/admin/{resource}/{item_id}/active', headers=admin_headers, json={'is_active': False})
            assert response.status_code == 200, response.text
            changed.append((resource, item_id))
            inactive = client.get(f'/admin/{resource}', headers=admin_headers, params={'is_active': 'false', 'page_size': 100})
            active = client.get(f'/admin/{resource}', headers=admin_headers, params={'is_active': 'true', 'page_size': 100})
            assert inactive.status_code == active.status_code == 200, inactive.text
            def ids(response, is_active):
                body = response.json()
                result = {row['id'] for row in body['items']}
                for page in range(2, body['total_pages'] + 1):
                    following = client.get(f'/admin/{resource}', headers=admin_headers, params={'is_active': is_active, 'page_size': 100, 'page': page})
                    assert following.status_code == 200, following.text
                    result.update(row['id'] for row in following.json()['items'])
                return result
            assert str(item_id) in ids(inactive, 'false')
            assert str(item_id) not in ids(active, 'true')
        detail = client.get(f'/correspondences/{correspondence_id}', headers=admin_headers)
        # El creador conserva seguimiento aunque los maestros se desactiven.
        assert detail.status_code == 200, detail.text
        assert detail.json()["current_user_is_active"] is False
        row = db.get(Correspondence, correspondence_id)
        assert row.current_user_id == second_user.id
        assert row.current_unit_id == second_org_unit.id
        db.expire_all()
        assert db.get(Correspondence, correspondence_id) is not None
        assert list(db.scalars(select(CorrespondenceMovement.id).where(CorrespondenceMovement.correspondence_id == correspondence_id))) == movements_before
    finally:
        for resource, item_id in reversed(changed):
            restored = client.patch(f'/admin/{resource}/{item_id}/active', headers=admin_headers, json={'is_active': True})
            assert restored.status_code == 200, restored.text
