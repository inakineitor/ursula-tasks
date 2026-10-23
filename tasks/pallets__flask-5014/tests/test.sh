#!/bin/bash
set -uo pipefail

BASE=7ee9ceb71e868944a46e1ff00b506772a53a4f1d
TEST_FILES=(tests/test_blueprints.py)

cd /testbed
mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

if ! python -c "import flask, sys; sys.exit(0 if flask.__file__.startswith('/testbed/src/') else 1)" 2>/dev/null; then
    pip install --no-cache-dir --no-deps --no-build-isolation -e .
fi

# Files modified by test.patch: reset to base. Files added by it: none.
git checkout "$BASE" -- tests/test_blueprints.py
if ! git apply --verbose /tests/test.patch; then
    echo "failed to apply test.patch"
    echo '{}' > /logs/verifier/statuses.json
    exit 0
fi

LOG=/logs/verifier/test_output.log
: '>>>>> Start Test Output'
pytest -rA "${TEST_FILES[@]}" 2>&1 | tee "$LOG"
: '>>>>> End Test Output'

COLLECTED=/logs/verifier/collected.txt
pytest --collect-only -q "${TEST_FILES[@]}" > "$COLLECTED" 2>&1

python3 - "$LOG" "$COLLECTED" <<'PY'
import json, os, re, sys

collected = {
    l.rstrip("\n") for l in open(sys.argv[2], errors="replace") if "::" in l
}

STATUSES = ("PASSED", "FAILED", "ERROR", "SKIPPED", "XFAIL", "XPASS")
ansi = re.compile(r"\x1b\[[0-9;]*m")
summary = re.compile(r"^(%s) (.+)$" % "|".join(STATUSES))
statuses = {}
in_summary = False
for raw in open(sys.argv[1], errors="replace"):
    line = ansi.sub("", raw.rstrip("\n"))
    if re.match(r"^=+ short test summary info =+$", line):
        in_summary = True
        continue
    if not in_summary:
        continue
    if re.match(r"^=+ .* =+$", line):
        in_summary = False
        continue
    m = summary.match(line)
    if not m:
        continue
    status, rest = m.groups()
    if status == "SKIPPED" and rest.startswith("["):
        # "SKIPPED [n] path:line: reason" carries no test id.
        continue
    if status != "PASSED":
        # Drop a trailing " - message" without truncating ids that contain
        # spaces: prefer the longest collected id that prefixes the line.
        known = [t for t in collected if rest == t or rest.startswith(t + " - ")]
        if known:
            rest = max(known, key=len)
        elif " - " in rest:
            rest = rest.split(" - ", 1)[0]
    statuses[rest.strip()] = status

with open("/logs/verifier/statuses.json", "w") as f:
    json.dump(statuses, f, indent=2, sort_keys=True)
print(f"parsed {len(statuses)} test statuses")

reward = 0
spec_path = "/tests/tests.json"
if os.path.exists(spec_path):
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
    reward = 1 if ok else 0
with open("/logs/verifier/reward.txt", "w") as f:
    f.write(f"{reward}\n")
print("reward:", reward)
PY
