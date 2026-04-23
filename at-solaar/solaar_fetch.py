#!/usr/bin/env python3
import subprocess, json, re, os

CACHE_FILE = os.path.expanduser("~/.cache/at-solaar.json")
MISS_THRESHOLD = 3

# Load existing cache keyed by device name
cached = {}
if os.path.exists(CACHE_FILE):
    try:
        with open(CACHE_FILE) as f:
            for d in json.load(f).get("devices", []):
                cached[d["name"]] = d
    except Exception:
        pass

# Run solaar show and parse live devices
result = subprocess.run(["solaar", "show"], capture_output=True, text=True)
parsed = []
current = None

for line in result.stdout.splitlines():
    m = re.match(r'^[ ]{2,5}\d+:\s+(.+)$', line)
    if m:
        current = {"name": m.group(1).strip(), "codename": None, "kind": None, "battery": None, "status": None}
        parsed.append(current)
        continue

    if current is None:
        continue

    stripped = line.strip()

    if re.match(r'^Codename\s*:', stripped):
        current["codename"] = stripped.split(":", 1)[1].strip()
    elif re.match(r'^Kind\s*:', stripped):
        current["kind"] = stripped.split(":", 1)[1].strip()
    elif stripped.startswith("Battery:") and current["battery"] is None:
        bm = re.search(r'(\d+)%.*?BatteryStatus\.(\w+)', stripped)
        if bm:
            current["battery"] = int(bm.group(1))
            current["status"] = bm.group(2)

for d in parsed:
    d["name"] = d.pop("codename") or d["name"]

live = {d["name"]: d for d in parsed if d["battery"] is not None}

# Merge live into cache: reset misses for seen devices, increment for absent
merged = {}

for name, d in live.items():
    d["misses"] = 0
    merged[name] = d

for name, d in cached.items():
    if name not in merged:
        misses = d.get("misses", 0) + 1
        if misses < MISS_THRESHOLD:
            d["misses"] = misses
            merged[name] = d

# Always write cache (even if empty, so misses accumulate correctly)
os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
with open(CACHE_FILE, "w") as f:
    json.dump({"devices": list(merged.values())}, f)

# Output: strip misses, add absent flag for widget
output = []
for d in merged.values():
    out = {k: v for k, v in d.items() if k != "misses"}
    out["absent"] = d.get("misses", 0) > 0
    output.append(out)

print(json.dumps({"devices": output, "count": len(output)}))
