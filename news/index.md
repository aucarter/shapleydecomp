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
- New `group_vars` argument to
  [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  (and `group_vars` in
  [`run_decomp()`](https://aucarter.github.io/shapleydecomp/reference/run_decomp.md)
  params) names the columns, such as a location, that identify
  independent groups. It replaces the hard-coded `ihme_loc_id` grouping.
- The warm-start methods are documented together under
  [`?warm_start`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md),
  with a runnable example. The documentation now describes the actual
  contract:
  [`run_from_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md)
  receives the observed simulation and `warm_start_year`.
- `n_cores > 1` on Windows falls back to sequential with a warning
  instead of failing.
- The Shapley algebra is now a single weight-matrix product over all
  groups, years and measures
  ([\#8](https://github.com/aucarter/shapleydecomp/issues/8)). With 200
  draws as groups, a full
  [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  run is 5-7x faster and the decomposition step alone about 130x faster,
  with results identical to rounding.
- [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  does less work for the same result
  ([\#9](https://github.com/aucarter/shapleydecomp/issues/9)):
  - all counterfactual runs, across all decomp years, go through one
    parallel map, so a decomposition is no longer limited to 2^n cores
    at a time or held up by the slowest run of each year;
  - with `future_policies = "off"`, the all-off run at step y is reused
    from the all-on run at step y - 1 rather than simulated again (one
    run fewer per contiguous year);
  - the “every factor off from y + 1” parameters are built once per year
    (per worker) rather than once per run. Outputs are identical to the
    previous version.
- Factors whose counterfactual leaves a step’s parameters unchanged,
  such as a programme that has not started yet, are detected as null
  players. Their effect at that step is 0, and coalitions that differ
  only in null factors are simulated once
  ([\#10](https://github.com/aucarter/shapleydecomp/issues/10)). A run
  is reused only after confirming its parameters are
  [`identical()`](https://rdrr.io/r/base/identical.html), so a model
  whose counterfactuals interact loses the saving, never correctness.
  The new `run_summary` output reports, per decomp year, the runs
  simulated and reused and the null factors.
- A failed simulation inside `n_cores > 1` now stops with the decomp
  year and run that failed, instead of a later, unrelated-looking error.
- [`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md)
  (and
  [`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md)’s
  `full_summary`) may return any data.frame. It is converted to a
  `data.table` on the way in
  ([\#6](https://github.com/aucarter/shapleydecomp/issues/6)).
- [`run_decomp()`](https://aucarter.github.io/shapleydecomp/reference/run_decomp.md),
  [`decomp_algebra()`](https://aucarter.github.io/shapleydecomp/reference/decomp_algebra.md)
  and
  [`decomp_pair()`](https://aucarter.github.io/shapleydecomp/reference/decomp_pair.md)
  match rows to on/off combinations by their factor values, so row order
  no longer matters
  ([\#7](https://github.com/aucarter/shapleydecomp/issues/7)).
  Incomplete or duplicated combinations, or factor values other than
  0/1, are now an error instead of a silently wrong result.
- [`decomp_pair()`](https://aucarter.github.io/shapleydecomp/reference/decomp_pair.md)
  returns a `data.table` with `measure` first, like
  [`decomp_algebra()`](https://aucarter.github.io/shapleydecomp/reference/decomp_algebra.md)
  ([\#4](https://github.com/aucarter/shapleydecomp/issues/4)).
- [`make_run_table()`](https://aucarter.github.io/shapleydecomp/reference/make_run_table.md)
  now prints when called at top level.
- [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  reports progress with
  [`message()`](https://rdrr.io/r/base/message.html) instead of
  [`cat()`](https://rdrr.io/r/base/cat.html).
