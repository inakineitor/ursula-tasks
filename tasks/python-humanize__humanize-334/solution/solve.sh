#!/bin/bash
set -euo pipefail
cd /testbed

cat > /tmp/gold.patch <<'GOLD_PATCH_EOF'
diff --git a/src/humanize/time.py b/src/humanize/time.py
--- a/src/humanize/time.py
+++ b/src/humanize/time.py
@@ -153,6 +153,16 @@ def naturaldelta(
             delta = dt.timedelta(seconds=value)
         except (ValueError, TypeError):
             return str(value)
+        except OverflowError:
+            # `int(value)` raises OverflowError for non-finite floats (inf/-inf),
+            # which, like NaN, are returned unchanged. A too-large *finite* value
+            # (whose OverflowError comes from `timedelta`) is still raised, per
+            # the documented `OverflowError` contract.
+            import math
+
+            if not math.isfinite(value):
+                return str(value)
+            raise
 
     use_months = months
 
GOLD_PATCH_EOF

if git apply --verbose /tmp/gold.patch; then
    echo "gold.patch applied with git apply"
else
    echo "git apply failed; falling back to patch --fuzz=5"
    patch --batch --fuzz=5 -p1 -i /tmp/gold.patch
fi
rm -f /tmp/gold.patch
