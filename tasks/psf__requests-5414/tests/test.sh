#!/bin/bash
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

cd /testbed

# Editable install: no reinstall needed.
git checkout 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e -- tests/test_requests.py
git apply -v "$TESTS_DIR/test.patch" || { echo "Failed to apply test.patch"; exit 0; }

LOG=/logs/verifier/test_output.log
: '>>>>> Start Test Output'
pytest -rA tests/test_requests.py 2>&1 | tee "$LOG"
: '>>>>> End Test Output'

git checkout 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e -- tests/test_requests.py

python3 - "$LOG" "$TESTS_DIR/tests.json" <<'PY'
import json, re, sys

log_path, spec_path = sys.argv[1], sys.argv[2]
statuses = {}
pat = re.compile(r"^(PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS)\s+(\S.*)$")
with open(log_path, errors="replace") as f:
    for line in f:
        line = line.rstrip("\n")
        m = pat.match(line)
        if not m:
            continue
        status, rest = m.groups()
        if status in ("FAILED", "ERROR") and " - " in rest:
            rest = rest.split(" - ", 1)[0]
        if status == "SKIPPED":
            # "SKIPPED [1] path:line: reason" carries no test id
            continue
        statuses[rest.strip()] = status

spec = json.load(open(spec_path))
ok = True
for t in spec["FAIL_TO_PASS"]:
    s = statuses.get(t)
    if s not in ("PASSED", "XFAIL"):
        print(f"FAIL_TO_PASS not passing: {t} -> {s}")
        ok = False
for t in spec["PASS_TO_PASS"]:
    s = statuses.get(t)
    if s not in ("PASSED", "XFAIL", "SKIPPED"):
        print(f"PASS_TO_PASS not passing: {t} -> {s}")
        ok = False

print("RESULT:", "PASS" if ok else "FAIL")
open("/logs/verifier/reward.txt", "w").write("1\n" if ok else "0\n")
PY
cat /logs/verifier/reward.txt
