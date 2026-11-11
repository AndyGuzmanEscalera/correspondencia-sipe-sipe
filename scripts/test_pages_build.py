"""Serve the prepared frontend with Wrangler Pages locally; never deploy/login.

Uses an isolated cwd and temporary ports; no backend API or municipal DB calls.
"""
import hashlib
from contextlib import contextmanager
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.160.1"


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, newurl):
        return None


@contextmanager
def isolated_directory():
    folder = Path(tempfile.mkdtemp(prefix="corr-pages-local-")).resolve()
    assert folder.parent == Path(tempfile.gettempdir()).resolve()
    assert folder.name.startswith("corr-pages-local-")
    try:
        yield str(folder)
    finally:
        # Workerd can release SQLite handles just after the Windows process tree
        # exits. Retry only this directory owned by this test.
        for attempt in range(40):
            try:
                shutil.rmtree(folder)
                break
            except PermissionError:
                if attempt == 39:
                    raise
                time.sleep(0.25)


def main():
    build = ROOT / "build/web"
    assert (build / "index.html").is_file() and (build / "_redirects").is_file()
    assert not (build / "404.html").exists()
    npx = shutil.which("npx.cmd" if os.name == "nt" else "npx")
    assert npx, "npx is required"
    port, inspector = free_port(), free_port()
    env = {k: v for k, v in os.environ.items() if not k.startswith(("CLOUDFLARE_", "CF_API_"))}
    env.update(CI="true", WRANGLER_SEND_METRICS="false")
    with isolated_directory() as folder:
        logpath = Path(folder) / "wrangler.log"
        with logpath.open("w", encoding="utf-8") as log:
            process = subprocess.Popen(
                [npx, "--yes", "wrangler@" + VERSION, "pages", "dev", str(build),
                 "--ip", "127.0.0.1", "--port", str(port), "--inspector-port", str(inspector),
                 "--compatibility-date", "2026-11-11", "--show-interactive-dev-session=false"],
                cwd=folder, env=env, stdout=log, stderr=subprocess.STDOUT,
            )
            try:
                base = "http://127.0.0.1:" + str(port)
                print("Starting local Wrangler Pages (no account/project deployment)...", flush=True)
                deadline = time.monotonic() + 180
                while True:
                    try:
                        with urllib.request.urlopen(base + "/login", timeout=2):
                            break
                    except (OSError, urllib.error.URLError):
                        if process.poll() is not None or time.monotonic() > deadline:
                            raise RuntimeError(logpath.read_text(encoding="utf-8", errors="replace")[-5000:])
                        time.sleep(1)
                html = (build / "index.html").read_bytes()
                for path in ("/", "/login", "/consulta", "/correspondencia/home", "/synthetic/deep/link"):
                    with urllib.request.urlopen(base + path, timeout=8) as response:
                        assert response.status == 200
                        assert response.read() == html, path
                opener = urllib.request.build_opener(NoRedirect)
                for old, canonical in (("/correspondencia/login", "/login"),
                                       ("/correspondencia/consulta", "/consulta"),
                                       ("/consulta-publica", "/consulta")):
                    try:
                        opener.open(base + old, timeout=8)
                        raise AssertionError("Missing redirect: " + old)
                    except urllib.error.HTTPError as response:
                        assert response.code == 301
                        target = urllib.request.urljoin(base + old, response.headers["Location"])
                        assert target == base + canonical
                    with urllib.request.urlopen(base + old, timeout=8) as response:
                        assert response.geturl() == base + canonical
                        assert response.read() == html
                for path in ("/main.dart.js", "/flutter_bootstrap.js",
                             "/assets/AssetManifest.json", "/sipe-sipe-32.png"):
                    with urllib.request.urlopen(base + path, timeout=10) as response:
                        body = response.read()
                        assert hashlib.sha256(body).digest() == hashlib.sha256((build / path.lstrip("/")).read_bytes()).digest()
                        assert body != html, "SPA fallback swallowed real asset: " + path
                print("PASS: Wrangler local SPA/deep links, canonical 301s, no loops, real assets intact.", flush=True)
            finally:
                if process.poll() is None:
                    if os.name == "nt":
                        subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
                    else:
                        process.terminate()
                    process.wait(timeout=20)
                print("Only the locally started Wrangler process was stopped.", flush=True)


if __name__ == "__main__":
    main()
