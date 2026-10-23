`click.Path` should be generic on `path_type`
Click 8.5.0 made `click.prompt` and `click.ParamType` generic, so the return type of `click.prompt` is now normally clever enough to reveal the actual type of the value as converted from raw input.

However, `click.Path` has a `path_type` parameter to which the input is converted, but  that information is not reflected in the return type of `click.Path.convert`, so it's always typed as `str | bytes | os.PathLike[str]`, regardless of the value of `path_type`.

```python
# mre.py
import pathlib

from typing_extensions import assert_type

import click

my_type = click.Path(file_okay=False, path_type=pathlib.Path)
path = click.prompt("Enter a name", type=my_type)

# expected: pathlib.Path, actual: str | bytes | os.PathLike[str]
assert_type(path, pathlib.Path)
```

I checked the above MRE with mypy and pyright, as well as ty for completeness, on a local clone of the repo @ `main`:

```console
$ uv run mypy mre.py
mre.py:12: error: Expression is of type "str | bytes | PathLike[str]", not "Path"  [assert-type]
    assert_type(path, pathlib.Path)
    ^
Found 1 error in 1 file (checked 1 source file)
```

```console
$ uv run pyright mre.py
WARNING: there is a new pyright version available (v1.1.408 -> v1.1.411).
Please install the new version or set PYRIGHT_PYTHON_FORCE_VERSION to `latest`

/Users/edgarramirez/Contrib/pallets/click/mre.py
  /Users/edgarramirez/Contrib/pallets/click/mre.py:12:13 - error: "assert_type" mismatch: expected "Path" but received "str | bytes | PathLike[str]" (reportAssertTypeFailure)
1 error, 0 warnings, 0 informations
```

```console
$ uv run ty check mre.py
error[type-assertion-failure]: Argument does not have asserted type `Path`
  --> mre.py:12:1
   |
12 | assert_type(path, pathlib.Path)
   | ^^^^^^^^^^^^----^^^^^^^^^^^^^^^
   |             |
   |             Inferred type is `str | bytes | PathLike[str]`
info: `Path` and `str | bytes | PathLike[str]` are not equivalent types

Found 1 diagnostic
```

I expect the return type of `click.prompt` to match the `path_type` value passed to `click.Path`.

Environment:

- Python version: 3.14
- Click version: 8.5.0
