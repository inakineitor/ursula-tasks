naturaldelta() raises OverflowError on float('inf') instead of returning it unchanged
### Summary
`naturaldelta()` documents that a non-finite float value is "returned unchanged." `nan` is handled and returned as `'nan'`, but `float('inf')`/`float('-inf')` raise an uncaught `OverflowError`. The behavior is asymmetric and contradicts the docstring.

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

### Environment
humanize 4.15.1.dev (main @ c2c410c), Python 3.12.

### Clarifications
- Like `nan`, which yields the string `'nan'`, `float("inf")` and `float("-inf")` should produce the strings `'inf'` and `'-inf'`.
- Finite values that are too large to convert to `datetime.timedelta` (e.g. `1e30`) should still raise `OverflowError`, as documented.
