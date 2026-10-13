# shapleydecomp 0.3.0

* The package is renamed from `decomposer` to `shapleydecomp`. CRAN already
  hosts `DecomposeR`, and CRAN package names are case-insensitive. The API
  is otherwise unchanged: replace `library(decomposer)` / `decomposer::` with
  `shapleydecomp`.
* `decompose()` is renamed `shapley_decompose()`, so it no longer masks
  `stats::decompose()`. The arguments and return value are unchanged.
* All exported functions are documented with examples. There are two new
  vignettes, *Get started* and *Methods*, and a pkgdown site.
* New `group_vars` argument to `shapley_decompose()` (and `group_vars` in
  `run_decomp()` params) names the columns, such as a location, that identify
  independent groups. It replaces the hard-coded `ihme_loc_id` grouping.
* The warm-start methods are documented together under `?warm_start`, with
  a runnable example. The documentation now describes the actual contract:
  `run_from_warm_start()` receives the observed simulation and
  `warm_start_year`.
* `n_cores > 1` on Windows falls back to sequential with a warning instead of
  failing.
* `make_run_table()` now prints when called at top level.
* `shapley_decompose()` reports progress with `message()` instead of `cat()`.

# decomposer 0.2.0

* `decompose()` gains `future_policies`, defaulting to `"off"`: sequential
  Shapley, where each step varies only that year's policy and every later
  policy is held at its counterfactual. `"on"` reproduces earlier runs.
* New `sequential_totals()` sums sequential steps into each factor's total
  impact at every year.
* Decomposition is unified on the Shapley value. `method = "das_gupta"` is a
  deprecated alias that gives identical results.

# decomposer 0.1.0

* Initial version: model-agnostic factorial decomposition through an S3
  interface, with `"change_since"` and `"total_impact"` counterfactuals and
  optional warm starts.
