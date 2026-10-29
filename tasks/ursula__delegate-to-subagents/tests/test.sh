#!/bin/bash
set -uo pipefail

mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt

errors=$(cat /app/answers/errors.txt 2>/dev/null | tr -d '[:space:]')
total=$(cat /app/answers/total.txt 2>/dev/null | tr -d '[:space:]')
echo "errors.txt: ${errors:-<missing>} (expected 21)"
echo "total.txt: ${total:-<missing>} (expected 38848.83)"

if [ "$errors" = "21" ] && [ "$total" = "38848.83" ]; then
    echo 1 > /logs/verifier/reward.txt
fi
