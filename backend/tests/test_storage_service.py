from pathlib import Path

import pytest

from app.core.storage.local_filesystem_storage import LocalFilesystemStorage
from app.core.storage.storage_service import validate_storage_key


@pytest.fixture()
def storage(tmp_path: Path) -> LocalFilesystemStorage:
    return LocalFilesystemStorage(tmp_path)


def test_put_read_exists_delete(storage: LocalFilesystemStorage) -> None:
    key = "correspondence/2026/corr-1/chaining/file.pdf"
    payload = b"%PDF-1.4 test"

    storage.put(key, payload)
    assert storage.exists(key)
    assert storage.read(key) == payload

    stream = storage.open(key)
    assert stream.read() == payload

    assert storage.delete(key) is True
    assert storage.delete(key) is False
    assert not storage.exists(key)


def test_nested_keys(storage: LocalFilesystemStorage) -> None:
    storage.put("a/b/c.txt", b"nested")
    assert storage.read("a/b/c.txt") == b"nested"


def test_missing_read_raises(storage: LocalFilesystemStorage) -> None:
    with pytest.raises(FileNotFoundError):
        storage.read("missing/file.pdf")


def test_rejects_parent_traversal(storage: LocalFilesystemStorage) -> None:
    with pytest.raises(ValueError):
        storage.put("../escape.txt", b"x")


def test_rejects_absolute_key(storage: LocalFilesystemStorage) -> None:
    with pytest.raises(ValueError):
        validate_storage_key("/absolute/path.pdf")


def test_rejects_empty_key() -> None:
    with pytest.raises(ValueError):
        validate_storage_key("   ")


def test_resolved_path_stays_under_root(
    storage: LocalFilesystemStorage,
    tmp_path: Path,
) -> None:
    storage.put("safe/nested/file.bin", b"123")
    target = (tmp_path / "safe/nested/file.bin").resolve()
    assert target.is_file()
    assert tmp_path.resolve() in target.parents
