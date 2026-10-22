#!/bin/bash
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

cd /testbed

git checkout 7ee9ceb71e868944a46e1ff00b506772a53a4f1d -- tests/test_blueprints.py
git apply --verbose "$TESTS_DIR/test.patch" || { echo "failed to apply test.patch"; exit 0; }

LOG=/logs/verifier/test_output.log
: '>>>>> Start Test Output'
pytest -rA tests/test_blueprints.py 2>&1 | tee "$LOG"
: '>>>>> End Test Output'

git checkout 7ee9ceb71e868944a46e1ff00b506772a53a4f1d -- tests/test_blueprints.py

python3 - "$TESTS_DIR/tests.json" "$LOG" <<'PY'
import json, re, sys

spec = json.load(open(sys.argv[1]))
status = {}
pat = re.compile(r"^(PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS)\s+(\S+)")
for line in open(sys.argv[2], errors="replace"):
    m = pat.match(line.strip())
    if m:
        st, tid = m.groups()
        if st == "SKIPPED" and tid.startswith("["):
            continue
        status[tid] = st

ok = True
for t in spec["FAIL_TO_PASS"]:
    if status.get(t) not in ("PASSED", "XFAIL"):
        print(f"FAIL_TO_PASS failed: {t} -> {status.get(t)}")
        ok = False
for t in spec["PASS_TO_PASS"]:
    if status.get(t) not in ("PASSED", "XFAIL", "SKIPPED"):
        print(f"PASS_TO_PASS failed: {t} -> {status.get(t)}")
        ok = False
print("RESULT:", "PASS" if ok else "FAIL")
open("/logs/verifier/reward.txt", "w").write("1\n" if ok else "0\n")
PY
cat /logs/verifier/reward.txt
