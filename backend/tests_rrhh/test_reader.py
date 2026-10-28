import csv
import json
import socket
import tempfile
import threading
import unittest
from datetime import datetime
from pathlib import Path
from struct import pack, unpack
from types import SimpleNamespace
from unittest.mock import Mock, patch

from zk import const
from zk.attendance import Attendance
from app.modules.rrhh.reader.config import Config
from app.modules.rrhh.reader.connection import DeviceError, Reader, _BoundedZK, tcp_probe
from app.modules.rrhh.reader.monitor import monitor
from app.modules.rrhh.reader.records import attendance_record, filter_records, user_record
from app.modules.rrhh.reader.storage import Store, export_records


def record(day=1, user="001"):
    return attendance_record(Attendance(user, datetime(2026, 10, day, 8), 1, 0, 4), "test")


class RecordsTests(unittest.TestCase):
    def test_dates_sort_inclusive_and_validation(self):
        self.assertEqual(filter_records([record(3), record(1), record(2)], "2026-10-01", "2026-10-02"),
                         [record(1), record(2)])
        with self.assertRaises(ValueError):
            filter_records([], "2026-10-04", "2026-10-01")
        with self.assertRaises(ValueError):
            filter_records([], "fecha")

    def test_persistent_dedup_and_device_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "test.sqlite3"
            store = Store(path)
            self.assertEqual(len(store.add([record(), record()])), 1)
            self.assertEqual(Store(path).add([record()]), [])
            self.assertEqual(len(store.all("test")), 1)
            self.assertEqual(store.all("otro"), [])

    def test_exports_roundtrip_and_formula_guard(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            export_records([record()], path / "a.json", "json")
            self.assertEqual(json.loads((path / "a.json").read_text("utf-8")), [record()])
            export_records([record(user="=1+1")], path / "a.csv", "csv")
            with (path / "a.csv").open(encoding="utf-8-sig", newline="") as handle:
                self.assertEqual(next(csv.DictReader(handle))["user_id"], "'=1+1")
            with self.assertRaises(FileExistsError):
                export_records([], path / "a.json", "json")

    def test_user_password_not_exported(self):
        output = user_record(SimpleNamespace(user_id="0007", name="José", password="secreto", template=b"x"))
        self.assertEqual(output["user_id"], "0007")
        self.assertNotIn("password", output)
        self.assertNotIn("template", output)

    def test_config_invalid(self):
        for kwargs in ({"port": 0}, {"timeout": 0}, {"timeout": float("nan")},
                       {"password": -1}, {"poll_interval": 0}, {"transport": "other"}):
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError):
                Config("127.0.0.1", **kwargs)


class ConnectionTests(unittest.TestCase):
    def test_incomplete_download_stops_on_eof(self):
        client = _BoundedZK("127.0.0.1", ommit_ping=True)
        client.close_socket()
        client._ZK__sock = Mock()
        client._ZK__sock.recv.side_effect = [b"ab", b""]
        with self.assertRaisesRegex(DeviceError, "incompleta"):
            client._ZK__recieve_raw_data(4)

    def test_real_pyzk_udp_against_local_protocol_simulator(self):
        # Solo loopback: sesión real de pyzk contra respuestas sintéticas mínimas.
        commands = []
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as server:
            server.bind(("127.0.0.1", 0))
            server.settimeout(2)
            def serve():
                while True:
                    packet, address = server.recvfrom(1024)
                    command, _, _, reply = unpack("<4H", packet[:8])
                    commands.append(command)
                    payload = pack("20i", *([0] * 20)) if command == const.CMD_GET_FREE_SIZES else b""
                    server.sendto(pack("<4H", const.CMD_ACK_OK, 0, 1, reply) + payload, address)
                    if command == const.CMD_EXIT:
                        break
            worker = threading.Thread(target=serve, daemon=True)
            worker.start()
            cfg = Config("127.0.0.1", port=server.getsockname()[1], transport="udp", timeout=1)
            with Reader(cfg).session() as connection:
                self.assertEqual(connection.get_users(), [])
                self.assertEqual(connection.get_attendance(), [])
            worker.join(3)
            self.assertFalse(worker.is_alive())
        self.assertEqual(commands, [const.CMD_CONNECT, const.CMD_GET_FREE_SIZES,
                                    const.CMD_GET_FREE_SIZES, const.CMD_EXIT])

    def test_tcp_loopback(self):
        with socket.socket() as server:
            server.bind(("127.0.0.1", 0))
            server.listen()
            cfg = Config("127.0.0.1", port=server.getsockname()[1], timeout=0.2)
            self.assertTrue(tcp_probe(cfg)[0])
        self.assertFalse(tcp_probe(cfg)[0])

    def test_socket_cleanup_on_error(self):
        client = Mock()
        client.connect.return_value = client
        with patch("app.modules.rrhh.reader.connection._BoundedZK", return_value=client):
            with self.assertRaises(DeviceError):
                with Reader(Config("127.0.0.1", transport="udp")).session():
                    raise OSError("timed out")
        client.disconnect.assert_called_once()
        client.close_socket.assert_called_once()

    def test_failed_auth_does_not_fallback(self):
        client = Mock()
        client.connect.side_effect = RuntimeError("Unauthenticated")
        with patch("app.modules.rrhh.reader.connection._BoundedZK", return_value=client) as factory, patch(
                "app.modules.rrhh.reader.connection.tcp_probe", return_value=(True, "OK")):
            with self.assertRaisesRegex(DeviceError, "Autenticación"):
                with Reader(Config("127.0.0.1")).session():
                    pass
        self.assertEqual(factory.call_count, 1)
        client.close_socket.assert_called_once()

    def test_auto_falls_back_udp(self):
        client = Mock()
        client.connect.return_value = client
        reader = Reader(Config("127.0.0.1"))
        with patch("app.modules.rrhh.reader.connection._BoundedZK", return_value=client), patch(
                "app.modules.rrhh.reader.connection.tcp_probe", return_value=(False, "closed")):
            with reader.session():
                self.assertEqual(reader.last_transport, "UDP")

    def test_readonly_guard_blocks_writes_and_templates(self):
        client = _BoundedZK("127.0.0.1", ommit_ping=True)
        try:
            for method in (client.disable_device, client.enable_device, client.restart,
                           client.clear_attendance, client.clear_data):
                with self.subTest(method=method.__name__), self.assertRaises(DeviceError):
                    method()
            with self.assertRaises(DeviceError):
                client._ZK__send_command(1503, pack("<bhii", 1, const.CMD_USERTEMP_RRQ, 2, 0))
        finally:
            client.close_socket()

    def test_polling_recovers_and_deduplicates(self):
        stop = threading.Event()
        reader = Mock()
        reader.attendance.side_effect = [DeviceError("timeout"), [record()], [record()]]
        messages = []
        def emit(message):
            messages.append(message)
            if reader.attendance.call_count == 3:
                stop.set()
        with tempfile.TemporaryDirectory() as directory:
            store = Store(Path(directory) / "test.db")
            monitor(reader, store, 0.001, emit, stop)
            self.assertEqual(len(store.all("test")), 1)
            self.assertEqual(sum(isinstance(m, dict) for m in messages), 1)


if __name__ == "__main__":
    unittest.main()
