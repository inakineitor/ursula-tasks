naturaldelta() raises OverflowError on float('inf') instead of returning it unchanged
### Summary
`naturaldelta()` documents that a non-finite float value is "returned unchanged." `nan` is handled (its `int()` raises `ValueError`, which is caught), but `float('inf')`/`float('-inf')` raise an uncaught `OverflowError` from `int(value)`, because the `except (ValueError, TypeError)` clause omits `OverflowError`. The behavior is asymmetric and contradicts the docstring.

### Reproduction
```python
import humanize
print(humanize.naturaldelta(float("nan")))   # 'nan'   (handled)
print(humanize.naturaldelta(float("inf")))   # OverflowError: cannot convert float infinity to integer
```

### Expected
`naturaldelta(float("inf"))` returns the value unchanged (symmetric with `nan`), per the docstring.

### Actual
Uncaught `OverflowError`.

### Fix sketch
Include `OverflowError` in the caught exceptions around the `int(value)` guard (time.py ~L149).

### Environment
humanize 4.15.1.dev (main @ c2c410c), Python 3.12.

