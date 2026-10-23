Complete the Bengali (bn_BD) translation
The bn_BD catalog hasn't been updated since 2023. The filesize labels (`%d Byte` / `%d Bytes`) added in #294 are missing, and `nonillion`, `decillion` and `googol` are untranslated. `million` is marked fuzzy, so it gets skipped at runtime and `intword(2_000_000)` returns "2.0 million" in English. `1 year, %d day` is also mistranslated, so `naturaldelta(timedelta(days=370))` returns "5 বছর" (5 years).

I'm a native Bengali speaker and would like to send a PR fixing these.
