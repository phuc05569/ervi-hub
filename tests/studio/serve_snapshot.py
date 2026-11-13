"""Read-only localhost source snapshot for the owned, unpublished Studio fixture.

Only /snapshot is served. Nothing is executed, written, or accepted from HTTP.
"""
import http.server
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2]


class Snapshot(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/snapshot":
            self.send_error(404)
            return
        modules = {
            p.stem: p.read_text(encoding="utf-8")
            for p in (ROOT / "src").glob("*.luau")
            if p.stem != "Loader"
        }
        modules["ErviBenchBaseline"] = subprocess.check_output(
            ["git", "show", "f577e07:src/Visuals.luau"], cwd=ROOT
        ).decode("utf-8")
        build = json.loads((ROOT / "build/Ervi_Hub.luau.map.json").read_text())["build"]
        modules["Build"] = 'return {version=' + json.dumps(build.split("+")[0]) + ',id=' + json.dumps(build) + '}\n'
        for name, source in modules.items():
            modules[name] = re.sub(
                r'require\("([\w.]+)"\)',
                r'require(script.Parent:WaitForChild("\1"))', source
            )
        body = json.dumps({"build": build, "modules": modules}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_):
        pass


if __name__ == "__main__":
    http.server.HTTPServer(("127.0.0.1", 18765), Snapshot).serve_forever()
