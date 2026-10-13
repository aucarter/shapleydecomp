# Changelog

## shapleydecomp 0.3.0

- The package is renamed from `decomposer` to `shapleydecomp`. CRAN
  already hosts `DecomposeR`, and CRAN package names are
  case-insensitive. The API is otherwise unchanged: replace
  [`library(decomposer)`](https://rdrr.io/r/base/library.html) /
  `decomposer::` with `shapleydecomp`.
- [`decompose()`](https://rdrr.io/r/stats/decompose.html) is renamed
  [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md),
  so it no longer masks
  [`stats::decompose()`](https://rdrr.io/r/stats/decompose.html). The
  arguments and return value are unchanged.
- All exported functions are documented with examples. There are two new
  vignettes, *Get started* and *Methods*, and a pkgdown site.
- [`make_run_table()`](https://aucarter.github.io/shapleydecomp/reference/make_run_table.md)
  now prints when called at top level.
- [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  reports progress with
  [`message()`](https://rdrr.io/r/base/message.html) instead of
  [`cat()`](https://rdrr.io/r/base/cat.html).
