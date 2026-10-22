#!/bin/bash
set -euo pipefail
cd /testbed
git apply -v "$(dirname "$0")/gold.patch"
