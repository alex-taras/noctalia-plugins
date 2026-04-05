#!/usr/bin/env python3
import subprocess, json, re

result = subprocess.run(["solaar", "show"], capture_output=True, text=True)
devices = []
current = None

for line in result.stdout.splitlines():
    # Device lines have 2-5 leading spaces before "N: Name"
    # Feature lines have 9+ leading spaces — excluded by the range
    m = re.match(r'^[ ]{2,5}\d+:\s+(.+)$', line)
    if m:
        current = {"name": m.group(1).strip(), "kind": None, "battery": None, "status": None}
        devices.append(current)
        continue

    if current is None:
        continue

    stripped = line.strip()

    if re.match(r'^Kind\s*:', stripped):
        current["kind"] = stripped.split(":", 1)[1].strip()
    elif stripped.startswith("Battery:") and current["battery"] is None:
        bm = re.search(r'(\d+)%.*?BatteryStatus\.(\w+)', stripped)
        if bm:
            current["battery"] = int(bm.group(1))
            current["status"] = bm.group(2)

devices = [d for d in devices if d["battery"] is not None]
print(json.dumps({"devices": devices, "count": len(devices)}))
