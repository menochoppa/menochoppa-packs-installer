"""Regression tests without installing ComfyUI or downloading models."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("bootstrap_menochoppa_packs.sh")
BASH = r"C:\Program Files\Git\bin\bash.exe" if os.name == "nt" else shutil.which("bash")


def shell_path(path):
    path = Path(path).resolve().as_posix()
    return "/" + path[0].lower() + path[2:] if os.name == "nt" else path


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.base = self.root / "comfy"
        self.checkout = self.base / "arrakis_start"
        self.checkout.mkdir(parents=True)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        interpreter = '#!/usr/bin/env bash\nexec "' + shell_path(sys.executable) + '" "$@"\n'
        for target in (self.bin / "python3", self.checkout / ".venv/bin/python"):
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(interpreter, newline="\n")
            target.chmod(0o755)
        (self.checkout / "start.py").write_text(
            'import json, pathlib\n'
            'presets = list(pathlib.Path("presets").glob("*.json"))\n'
            'assert len(presets) == 6\n'
            'print("SELECTOR_STARTED_AFTER_SIX_PRESETS")\n'
        )
        for args in (("init",), ("config", "user.name", "Test"),
                     ("config", "user.email", "test@example.invalid"),
                     ("add", "start.py"), ("commit", "-m", "fixture")):
            subprocess.run(["git", "-C", str(self.checkout), *args], check=True, capture_output=True)
        # Real Git stash reproduces the original failure if injection happens early.
        self.upstream = self.root / "upstream.sh"
        self.upstream.write_text('''#!/usr/bin/env bash
set -euo pipefail
main() {
    ARRAKIS_DIR="$COMFY_BASE/arrakis_start"
    ARRAKIS_PYTHON="$ARRAKIS_DIR/.venv/bin/python"
    git -C "$ARRAKIS_DIR" stash push --include-untracked -m fixture >/dev/null
    echo SETUP_FINISHED
    exec "$ARRAKIS_PYTHON" start.py --web-only
}
main "$@"
''', newline="\n")
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            self.port = probe.getsockname()[1]
        self.env = os.environ.copy()
        self.env.pop("HF_TOKEN", None)
        self.env.update(COMFY_BASE=shell_path(self.base),
                        ARRAKIS_DIR=shell_path(self.checkout),
                        UPSTREAM_BOOTSTRAP_URL=self.upstream.as_uri(),
                        WEB_PORT=str(self.port), VALIDATE_HF_ASSETS="0")
        self.env["PATH"] = str(self.bin) + os.pathsep + self.env["PATH"]

    def run_wrapper(self):
        return subprocess.run([BASH, shell_path(SCRIPT)], env=self.env,
                              capture_output=True, text=True, timeout=30)

    def test_setup_then_injection_and_repeat_survives_stash(self):
        # Put the interpreter outside Git so the fixture's real stash preserves it.
        exclude = self.checkout / ".git/info/exclude"
        with exclude.open("a") as stream:
            stream.write("\n.venv/\n")
        for _ in range(2):
            result = self.run_wrapper()
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertLess(result.stdout.index("SETUP_FINISHED"), result.stdout.index("Preset injected"))
            self.assertIn("SELECTOR_STARTED_AFTER_SIX_PRESETS", result.stdout)
            presets = list((self.checkout / "presets").glob("*.json"))
            self.assertEqual(len(presets), 6)
            names = {json.loads(p.read_text())["name"] for p in presets}
            self.assertIn("MEITANIME", names)
        ignored = subprocess.run(["git", "-C", str(self.checkout), "check-ignore",
                                  "presets/meitabuu.json", "presets/meitanime.json"],
                                 capture_output=True, text=True)
        self.assertEqual(ignored.returncode, 0)

    def test_failed_setup_does_not_inject_or_launch(self):
        self.upstream.write_text('''main() {
    exit 23
    exec "$ARRAKIS_PYTHON" start.py --web-only
}
main "$@"
''')
        result = self.run_wrapper()
        self.assertEqual(result.returncode, 23, result.stdout + result.stderr)
        self.assertFalse((self.checkout / "presets").exists())

    def test_impact_hook_patches_on_start_and_survives_update(self):
        (self.checkout / ".git/info/exclude").write_text(".venv/\n")
        impact = self.base / "ComfyUI/custom_nodes/ComfyUI-Impact-Pack/js/impact-pack.js"
        impact.parent.mkdir(parents=True)
        old = b"node.connect(link_info.origin_slot, node.id, 'input1');"
        new = b"node.connect(link_info.origin_slot, node, 'input1');"
        original = b"// upstream\n" + old + b"\n"
        impact.write_bytes(original)
        result = self.run_wrapper()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(impact.read_bytes(), original.replace(old, new))
        backups = list(impact.parent.glob("*.menochoppa-backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), original)
        hook = self.base / "ComfyUI/custom_nodes/menochoppa_impact_compat/__init__.py"
        subprocess.run([sys.executable, str(hook)], check=True, capture_output=True)
        self.assertEqual(len(list(impact.parent.glob("*.menochoppa-backup-*"))), 1)
        updated = b"// updated upstream\n" + old + b"\n"
        impact.write_bytes(updated)
        subprocess.run([sys.executable, str(hook)], check=True, capture_output=True)
        self.assertEqual(impact.read_bytes(), updated.replace(old, new))
        self.assertEqual(len(list(impact.parent.glob("*.menochoppa-backup-*"))), 2)
        unknown = b"// future upstream with a different implementation\n"
        impact.write_bytes(unknown)
        subprocess.run([sys.executable, str(hook)], check=True, capture_output=True)
        self.assertEqual(impact.read_bytes(), unknown)

    def test_unknown_upstream_aborts_before_execution(self):
        self.upstream.write_text('echo SHOULD_NOT_EXECUTE\n')
        result = self.run_wrapper()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("SHOULD_NOT_EXECUTE", result.stdout)
        self.assertIn("nao reconhecida", result.stderr)
        self.assertFalse((self.checkout / "presets").exists())

    def test_other_service_is_preserved(self):
        (self.checkout / ".git/info/exclude").write_text(".venv/\n")
        with socket.socket() as service:
            service.bind(("0.0.0.0", self.port))
            service.listen()
            result = self.run_wrapper()
            self.assertNotEqual(result.returncode, 0)
            # Windows may report EACCES rather than EADDRINUSE for another socket.
            expected = "Nao foi possivel verificar" if os.name == "nt" else "Nenhum processo foi encerrado"
            self.assertIn(expected, result.stderr)
            self.assertNotIn("SELECTOR_STARTED_AFTER_SIX_PRESETS", result.stdout)
            self.assertEqual(service.getsockname()[1], self.port)

    @unittest.skipIf(os.name == "nt", "Real /proc ownership needs Linux")
    def test_running_selector_is_reused(self):
        (self.checkout / ".git/info/exclude").write_text(".venv/\n")
        (self.checkout / "start.py").write_text(
            'from http.server import HTTPServer, BaseHTTPRequestHandler\n'
            f'HTTPServer(("0.0.0.0", {self.port}), BaseHTTPRequestHandler).serve_forever()\n'
        )
        server = subprocess.Popen([sys.executable, "start.py", "--web-only"], cwd=self.checkout)
        try:
            for _ in range(100):
                try:
                    with socket.create_connection(("127.0.0.1", self.port), timeout=0.1):
                        break
                except OSError:
                    time.sleep(0.02)
            else:
                self.fail("Fixture selector did not start")
            result = self.run_wrapper()
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("Arrakis ja esta rodando", result.stdout)
            self.assertNotIn("SELECTOR_STARTED_AFTER_SIX_PRESETS", result.stdout)
            self.assertIsNone(server.poll())
            self.assertEqual(len(list((self.checkout / "presets").glob("*.json"))), 6)
        finally:
            server.terminate()
            server.wait(timeout=5)

    def test_existing_selector_is_recognized_from_proc(self):
        # Exercise Linux /proc ownership detection even on a Windows test host.
        source = SCRIPT.read_text().split('"$WEB_PORT" "$ARRAKIS_DIR" <<\'PY\'\n')[1].split("\nPY")[0]
        process = Path("/proc/456")
        original_read_bytes = Path.read_bytes

        def read_bytes(path):
            if path == process / "cmdline":
                return b"python\x00start.py\x00--web-only\x00"
            return original_read_bytes(path)

        def resolve(path, *args, **kwargs):
            return Path("/fixture") if path == process / "cwd" else path

        def iterdir(path):
            return iter([process] if path == Path("/proc") else [process / "fd/7"])

        with patch("sys.argv", ["-", "8090", "/fixture"]), \
             patch("socket.socket") as probe, \
             patch.object(Path, "read_text", return_value="header\n0: 00000000:1F9A 00000000:0000 0A 0 0 0 0 0 123\n"), \
             patch.object(Path, "read_bytes", read_bytes), \
             patch.object(Path, "resolve", resolve), \
             patch.object(Path, "iterdir", iterdir), \
             patch("os.readlink", return_value="socket:[123]"):
            probe.return_value.__enter__.return_value.bind.side_effect = OSError(98, "busy")
            # Windows errno.EADDRINUSE differs from Linux's value.
            with patch("errno.EADDRINUSE", 98), self.assertRaises(SystemExit) as exited:
                exec(compile(source, "port-check", "exec"), {})
            self.assertEqual(exited.exception.code, 10)


if __name__ == "__main__":
    unittest.main()
