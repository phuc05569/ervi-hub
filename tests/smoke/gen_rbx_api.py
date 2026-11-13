"""Turn Roblox's public API-Dump.json into a compact Luau table for the mock engine.

Properties that are ReadOnly, NotScriptable or need elevated write security are marked
read-only, so the smoke test fails if the hub writes them.
"""
import json
import pathlib
import sys

dump = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
out = ["return {", " classes = {"]


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


for cls in dump["Classes"]:
    props, events, methods = [], [], []
    for m in cls.get("Members", []):
        tags = m.get("Tags", []) or []
        if "NotScriptable" in tags:
            continue
        kind = m["MemberType"]
        if kind == "Property":
            sec = m.get("Security", {})
            write = sec.get("Write", "None") if isinstance(sec, dict) else sec
            ro = "ReadOnly" in tags or write != "None"
            props.append(f"[{q(m['Name'])}]={'true' if ro else 'false'}")
        elif kind == "Event":
            events.append(f"[{q(m['Name'])}]=true")
        elif kind in ("Function", "Callback"):
            methods.append(f"[{q(m['Name'])}]=true")
    sup = cls.get("Superclass") or "<<<ROOT>>>"
    out.append(f"  [{q(cls['Name'])}]={{super={q(sup)},props={{{','.join(props)}}},events={{{','.join(events)}}},methods={{{','.join(methods)}}}}},")
out.append(" },")
out.append(" enums = {")
for enum in dump["Enums"]:
    items = ",".join(f"[{q(i['Name'])}]={i['Value']}" for i in enum["Items"])
    out.append(f"  [{q(enum['Name'])}]={{{items}}},")
out.append(" },")
out.append("}")
pathlib.Path(sys.argv[2]).write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
print(f"{len(dump['Classes'])} classes, {len(dump['Enums'])} enums -> {sys.argv[2]}")
