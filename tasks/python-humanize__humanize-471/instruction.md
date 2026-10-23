Complete the Bengali (bn_BD) translation
The bn_BD catalog hasn't been updated since 2023. The filesize labels (`%d Byte` / `%d Bytes`) added in #294 are missing, and `nonillion`, `decillion` and `googol` are untranslated. `million` is marked fuzzy, so it gets skipped at runtime and `intword(2_000_000)` returns "2.0 million" in English. `1 year, %d day` is also mistranslated, so `naturaldelta(timedelta(days=370))` returns "5 বছর" (5 years).

I'm a native Bengali speaker and would like to send a PR fixing these.

## Clarifications

The fixed bn_BD catalog is expected to produce these Bengali strings:

- `nonillion` → `ননিলিয়ন`, `decillion` → `ডেসিলিয়ন`, `googol` → `গুগল` (e.g. `intword(10**100)` returns `1.0 গুগল`); `million` keeps its existing translation `মিলিয়ন`.
- `%d Byte` / `%d Bytes` → `%d বাইট` (e.g. `naturalsize(42)` returns `42 বাইট`).
- `1 year, %d day` / `1 year, %d days` → `1 বছর, %d দিন` (e.g. `naturaldelta(timedelta(days=370))` returns `1 বছর, 5 দিন`; the leading `1` may be written with an ASCII or a Bengali digit).
