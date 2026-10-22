#!/bin/bash
set -euo pipefail
cd /testbed
git apply --verbose "$(dirname "$0")/gold.patch"
