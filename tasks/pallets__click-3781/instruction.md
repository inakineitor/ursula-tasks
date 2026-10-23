Support pathlib.Path in edit filename
Would you welcome a PR to avoid this?

```
Argument of type "Path" cannot be assigned to parameter "filename" of type "str | None" in function "edit"
  Type "Path" is not assignable to type "str | None"
    "Path" is not assignable to "str"
    "Path" is not assignable to "None"Pylance[reportArgumentType](https://github.com/microsoft/pyright/blob/main/docs/configuration.md#reportArgumentType)
```

Easy workaround with:
```py
click.edit(filename=str(export_common.path))
```

but would be nice if didn't need `str`.

## Clarifications

- Static type checkers (e.g. mypy, Pyright/Pylance) must accept `click.edit(filename=...)` when `filename` is a `str`, a `pathlib.Path` (any `os.PathLike[str]`), or an iterable mixing `str` and path-like values, and such calls must still be typed as returning `None`.
- At runtime, passing a single path-like `filename` must edit that file, just as a `str` does.
