import uuid
from datetime import date, datetime, timezone
from types import SimpleNamespace

from app.main import app
from app.modules.rrhh.attendance_service import summary_status
from app.modules.rrhh.attendance_source import get_attendance_source
from app.modules.rrhh.evaluation_models import ContractCatalog, ContractOption, DayStatus
from app.modules.rrhh.models import Sync
from .test_integration import auth, device


def test_catalog_and_latest_require_authentication(client):
    assert client.get('/rrhh/attendance/contracts').status_code == 401
    assert client.get('/rrhh/biometric/syncs/latest').status_code == 401


def test_unconfigured_contracts_are_empty_and_informative(client, db):
    headers = auth(db)
    result = client.get('/rrhh/attendance/contracts', headers=headers)
    assert result.status_code == 200 and result.json()['items'] == []
    assert 'employee_contract_assignment' in result.json()['pending_configuration']


def test_catalog_uses_confirmed_source_without_fabricating_names(client, db):
    headers = auth(db)
    contract_id = uuid.uuid4()
    class Source:
        def contracts(self, db):
            return ContractCatalog(items=(ContractOption(id=contract_id, name='Synthetic confirmed contract'),))
    app.dependency_overrides[get_attendance_source] = Source
    result = client.get('/rrhh/attendance/contracts', headers=headers)
    assert result.status_code == 200
    assert result.json()['items'] == [{'id':str(contract_id),'name':'Synthetic confirmed contract'}]


def test_latest_sync_static_route_precedes_uuid_route_and_reports_real_job(client, db):
    headers = auth(db)
    assert client.get('/rrhh/biometric/syncs/latest', headers=headers).json() == {'sync':None}
    device(db)
    old = Sync(device_id='test-clock',requested_start_date=date(2026,10,1),requested_end_date=date(2026,10,2),
               status='completed',created_at=datetime(2026,10,1,tzinfo=timezone.utc),downloaded_records=100000,new_records=1)
    active = Sync(device_id='test-clock',requested_start_date=date(2026,10,1),requested_end_date=date(2026,10,2),
                  status='queued',created_at=datetime(2026,10,2,tzinfo=timezone.utc))
    db.add_all([old,active]); db.commit()
    result = client.get('/rrhh/biometric/syncs/latest', headers=headers)
    assert result.status_code == 200 and result.json()['sync']['id'] == str(active.id)
    assert result.json()['sync']['status'] == 'queued'
    assert client.get(f'/rrhh/biometric/syncs/{old.id}',headers=headers).status_code == 200


def test_summary_status_is_computed_by_backend():
    assert summary_status(None) == DayStatus.NO_DATA
    assert summary_status(SimpleNamespace(days_evaluated=0)) == DayStatus.NO_DATA
    assert summary_status(SimpleNamespace(days_evaluated=1,anomaly_days=1,observation_days=0)) == DayStatus.ANOMALY
    assert summary_status(SimpleNamespace(days_evaluated=1,anomaly_days=0,observation_days=1)) == DayStatus.OBSERVATION
    assert summary_status(SimpleNamespace(days_evaluated=1,anomaly_days=0,observation_days=0)) == DayStatus.NORMAL
