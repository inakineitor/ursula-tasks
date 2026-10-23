#!/bin/bash
set -uo pipefail

cd /testbed
mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

BASE=2103e157683c5e4cadc8ee1838df526a54bde9a4

if ! python -c 'import click, sys; sys.exit(0 if click.__file__.startswith("/testbed/src/") else 1)' 2>/dev/null; then
    pip install --no-cache-dir --no-deps --no-build-isolation -e . \
        || pip install --no-cache-dir -e .
fi

# Files modified by test.patch are reset; files it adds are removed.
git checkout $BASE -- tests/test_termui.py
rm -f tests/typing/typing_edit.py
git apply --verbose /tests/test.patch || { echo "failed to apply test.patch"; exit 0; }

# tests/typing/typing_edit.py is a static type-checking fixture (mypy/pyright), not a pytest module.
LOG=/logs/verifier/test_output.log
: '>>>>> Start Test Output'
pytest -rA -v -p no:cacheprovider tests/test_termui.py 2>&1 | tee "$LOG"
: '>>>>> End Test Output'

python3 - "$LOG" <<'PY'
import json, os, re, sys

STATUSES = ("PASSED", "FAILED", "ERROR", "SKIPPED", "XFAIL", "XPASS")
summary = {}
verbose = {}
in_summary = False
summary_re = re.compile(r"^(PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS) (.+)$")
verbose_re = re.compile(
    r"^(\S+?\.py::.+?) (PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS)(?: \(.*\))?(?:\s+\[\s*\d+%\])?$"
)
for raw in open(sys.argv[1], errors="replace"):
    line = raw.rstrip("\n")
    if re.match(r"^=+ short test summary info =+$", line):
        in_summary = True
        continue
    if in_summary:
        m = summary_re.match(line)
        if m:
            st, rest = m.groups()
            if rest.startswith("["):  # "SKIPPED [1] file:line: reason" has no id
                continue
            if st in ("FAILED", "ERROR", "XFAIL", "XPASS") and " - " in rest:
                rest = rest.split(" - ", 1)[0]
            summary[rest.rstrip()] = st
        continue
    m = verbose_re.match(line)
    if m:
        tid, st = m.groups()
        verbose.setdefault(tid, st)

statuses = dict(verbose)
statuses.update(summary)
json.dump(statuses, open("/logs/verifier/statuses.json", "w"), indent=2, sort_keys=True)
print(f"parsed {len(statuses)} test statuses")

spec_path = "/tests/tests.json"
if not os.path.exists(spec_path):
    open("/logs/verifier/reward.txt", "w").write("0\n")
    sys.exit(0)
spec = json.load(open(spec_path))
ok = True
for t in spec.get("FAIL_TO_PASS", []):
    if statuses.get(t) not in ("PASSED", "XFAIL"):
        print(f"FAIL_TO_PASS failed: {t} -> {statuses.get(t)}")
        ok = False
for t in spec.get("PASS_TO_PASS", []):
    if statuses.get(t) not in ("PASSED", "XFAIL", "SKIPPED"):
        print(f"PASS_TO_PASS failed: {t} -> {statuses.get(t)}")
        ok = False
print("RESULT:", "PASS" if ok else "FAIL")
open("/logs/verifier/reward.txt", "w").write("1\n" if ok else "0\n")
PY
cat /logs/verifier/reward.txt
