#!/bin/bash
set -uo pipefail

cd /testbed
mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

if ! pip show click 2>/dev/null | grep "^Editable project location: /testbed" >/dev/null; then
    pip install --no-cache-dir --no-deps --no-build-isolation -e . \
        || pip install --no-cache-dir -e .
fi

pip install --no-cache-dir "mypy==1.20.0" "mypy-extensions==1.1.0" \
    "pathspec==1.0.4" "librt==0.8.1"

BASE=7944461a80b780d060899c8835acab3c273a04a6
git checkout $BASE -- tests/test_types/test_Path.py
rm -f tests/typing/typing_path.py
git apply --verbose /tests/test.patch || patch --batch --fuzz=5 -p1 -i /tests/test.patch \
    || echo "failed to apply test.patch"

LOG=/logs/verifier/test_output.log
: '>>>>> Start Test Output'
pytest -rA tests/test_types/test_Path.py 2>&1 | tee "$LOG"
: '>>>>> End Test Output'

python3 - "$LOG" <<'PY'
import json, os, re, sys

statuses = {}
pat = re.compile(r"^(PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS) (.+?)(?: - .*)?$")
in_summary = False
for raw in open(sys.argv[1], errors="replace"):
    line = raw.rstrip("\n")
    if re.match(r"^=+ short test summary info =+$", line):
        in_summary = True
        continue
    if not in_summary:
        continue
    if re.match(r"^=+ .* =+$", line):
        in_summary = False
        continue
    m = pat.match(line)
    if not m:
        continue
    st, tid = m.groups()
    if st == "SKIPPED" and tid.startswith("["):
        # "SKIPPED [n] path:line: reason" lines carry no test id
        continue
    statuses[tid] = st

with open("/logs/verifier/statuses.json", "w") as f:
    json.dump(statuses, f, indent=2)

reward = 0
spec_path = "/tests/tests.json"
if os.path.exists(spec_path):
    spec = json.load(open(spec_path))
    ok = True
    for tid in spec.get("FAIL_TO_PASS", []):
        if statuses.get(tid) not in ("PASSED", "XFAIL"):
            print(f"FAIL_TO_PASS failed: {tid} -> {statuses.get(tid)}")
            ok = False
    for tid in spec.get("PASS_TO_PASS", []):
        if statuses.get(tid) not in ("PASSED", "XFAIL", "SKIPPED"):
            print(f"PASS_TO_PASS failed: {tid} -> {statuses.get(tid)}")
            ok = False
    reward = 1 if ok else 0
with open("/logs/verifier/reward.txt", "w") as f:
    f.write(f"{reward}\n")
PY
cat /logs/verifier/reward.txt
