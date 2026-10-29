#!/bin/bash
set -euo pipefail
mkdir -p /app/answers
awk '$2 == "ERROR"' /app/logs/*.log | wc -l | tr -d ' ' > /app/answers/errors.txt
python3 - <<'PY'
import csv
from decimal import Decimal
with open("/app/data/sales.csv") as handle:
    total = sum(Decimal(row["amount"]) for row in csv.DictReader(handle))
open("/app/answers/total.txt", "w").write(f"{total:.2f}\n")
PY
