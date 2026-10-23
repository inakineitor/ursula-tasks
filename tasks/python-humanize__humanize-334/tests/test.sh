#!/bin/bash
set -uo pipefail

BASE_COMMIT=08cf2c3026cfd7c553e397e1d91ea069eb2a4978
TEST_FILES=(tests/test_time.py)

cd /testbed
mkdir -p /logs/verifier

# Re-install if the project isn't installed in editable mode.
PIP_SHOW="$(pip show humanize 2>/dev/null || true)"
if ! grep -q '^Editable project location: /testbed' <<<"$PIP_SHOW"; then
    export SETUPTOOLS_SCM_PRETEND_VERSION="${SETUPTOOLS_SCM_PRETEND_VERSION:-4.16.1.dev13}"
    pip install --no-build-isolation -e ".[tests]"
fi

# Reset the files test.patch modifies (it adds none), then apply it.
git checkout "$BASE_COMMIT" -- "${TEST_FILES[@]}"
git apply -v /tests/test.patch || echo "WARNING: failed to apply /tests/test.patch"

LOG=/logs/verifier/test_output.log
: '>>>>> Start Test Output'
python -m pytest -rA -v -p no:cacheprovider "${TEST_FILES[@]}" 2>&1 | tee "$LOG"
: '>>>>> End Test Output'

python3 - "$LOG" <<'PY'
import json, os, re, sys

log_path = sys.argv[1]
ansi = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
states = "PASSED|FAILED|ERROR|SKIPPED|XFAIL|XPASS"
summary_re = re.compile(rf"^({states}) (.+)$")
verbose_re = re.compile(rf"^(\S.*?) ({states})(?: \[\s*\d+%\])?$")

lines = [ansi.sub("", l.rstrip("\n")) for l in open(log_path, errors="replace")]

# Full ids from the verbose progress lines ("<id> PASSED [ 10%]").
known = set()
for line in lines:
    m = verbose_re.match(line)
    if m and "::" in m.group(1):
        known.add(m.group(1))

def strip_reason(rest):
    # "<id> - <message>": keep the longest prefix that's a known full id.
    if rest in known:
        return rest
    best = None
    for kid in known:
        if rest.startswith(kid + " - ") and (best is None or len(kid) > len(best)):
            best = kid
    if best:
        return best
    return rest.split(" - ", 1)[0] if " - " in rest else rest

statuses = {}
in_summary = False
for line in lines:
    if re.match(r"^=+ short test summary info =+$", line):
        in_summary = True
        continue
    if not in_summary:
        continue
    m = summary_re.match(line)
    if not m:
        continue
    status, rest = m.groups()
    if status == "SKIPPED" and rest.startswith("["):
        # "SKIPPED [1] path:line: reason" carries no test id
        continue
    statuses[strip_reason(rest)] = status

# Fall back to the verbose lines for anything missing from the summary.
for line in lines:
    m = verbose_re.match(line)
    if m and "::" in m.group(1):
        statuses.setdefault(m.group(1), m.group(2))

with open("/logs/verifier/statuses.json", "w") as f:
    json.dump(statuses, f, indent=2, sort_keys=True)
print(f"Parsed {len(statuses)} test statuses")

reward = 0
spec_path = "/tests/tests.json"
if os.path.exists(spec_path):
    spec = json.load(open(spec_path))
    ok = True
    for t in spec.get("FAIL_TO_PASS", []):
        s = statuses.get(t)
        if s not in ("PASSED", "XFAIL"):
            print(f"FAIL_TO_PASS not passing: {t} -> {s}")
            ok = False
    for t in spec.get("PASS_TO_PASS", []):
        s = statuses.get(t)
        if s not in ("PASSED", "XFAIL", "SKIPPED"):
            print(f"PASS_TO_PASS not passing: {t} -> {s}")
            ok = False
    reward = 1 if ok else 0
else:
    print("No /tests/tests.json; reward 0")

with open("/logs/verifier/reward.txt", "w") as f:
    f.write(f"{reward}\n")
print("reward:", reward)
PY
