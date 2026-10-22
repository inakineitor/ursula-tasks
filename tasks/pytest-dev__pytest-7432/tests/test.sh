#!/bin/bash
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_COMMIT=e6e300e729dd33956e5448d8be9a0b1540b4e53a
TEST_FILES="testing/test_skipping.py"

mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

cd /testbed

# pytest is installed in editable mode, so no reinstall is needed.
git checkout "$BASE_COMMIT" -- $TEST_FILES
git apply --verbose "$TESTS_DIR/test.patch" || { echo "Failed to apply test.patch"; exit 0; }

LOG=/logs/verifier/test_output.log
{
: '>>>>> Start Test Output'
pytest -rA $TEST_FILES
: '>>>>> End Test Output'
} 2>&1 | tee "$LOG"

python3 - "$TESTS_DIR/tests.json" "$LOG" <<'PY'
import json, re, sys

spec = json.load(open(sys.argv[1]))
log = open(sys.argv[2], errors="replace").read()

statuses = {}
pattern = re.compile(r"^(PASSED|FAILED|SKIPPED|ERROR|XFAIL|XPASS) (.+)$")
for line in log.splitlines():
    m = pattern.match(line.rstrip())
    if not m:
        continue
    status, rest = m.groups()
    if status != "PASSED":
        rest = rest.split(" - ", 1)[0]
    test = rest.strip()
    if test.startswith("testing/test_skipping.py"):
        statuses[test] = status

ok = True
for t in spec["FAIL_TO_PASS"]:
    s = statuses.get(t, "MISSING")
    if s not in ("PASSED", "XFAIL"):
        print(f"FAIL_TO_PASS failed: {t} -> {s}")
        ok = False
for t in spec["PASS_TO_PASS"]:
    s = statuses.get(t, "MISSING")
    if s not in ("PASSED", "XFAIL", "SKIPPED"):
        print(f"PASS_TO_PASS failed: {t} -> {s}")
        ok = False

print("RESULT:", "PASS" if ok else "FAIL")
open("/logs/verifier/reward.txt", "w").write("1\n" if ok else "0\n")
PY
exit 0
