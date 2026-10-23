#!/bin/bash
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

cd /testbed

# Editable install: no reinstall needed.
git checkout 785e5dcc0d0308ad0dff3f6cc0faa7085ad0375b -- tests/test_i18n.py
git apply -v "$TESTS_DIR/test.patch" || { echo "Failed to apply test.patch"; exit 0; }

# Recompile the gettext catalogs so .po changes take effect (as the project's CI does).
bash scripts/generate-translation-binaries.sh

LOG=/logs/verifier/test_output.log
: '>>>>> Start Test Output'
pytest -rA tests/test_i18n.py 2>&1 | tee "$LOG"
: '>>>>> End Test Output'

git checkout 785e5dcc0d0308ad0dff3f6cc0faa7085ad0375b -- tests/test_i18n.py

python3 - "$LOG" "$TESTS_DIR/tests.json" <<'PY'
import json, re, sys

log_path, spec_path = sys.argv[1], sys.argv[2]
spec = json.load(open(spec_path))
ansi = re.compile(r"\x1b\[[0-9;]*m")
pat = re.compile(r"^(PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS)\s+(\S.*)$")
statuses = {}
with open(log_path, errors="replace") as f:
    for line in f:
        line = ansi.sub("", line.rstrip("\n"))
        m = pat.match(line)
        if not m:
            continue
        status, rest = m.groups()
        if status == "SKIPPED" and rest.startswith("["):
            # "SKIPPED [1] path:line: reason" carries no test id
            continue
        statuses[rest] = status
        if " - " in rest:
            statuses.setdefault(rest.split(" - ", 1)[0], status)

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
