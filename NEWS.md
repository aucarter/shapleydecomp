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
* The Shapley algebra is now a single weight-matrix product over all
  groups, years and measures (#8). With 200 draws as groups, a full
  `shapley_decompose()` run is 5-7x faster and the decomposition step alone
  about 130x faster, with results identical to rounding.
* `shapley_decompose()` does less work for the same result (#9):
  - all counterfactual runs, across all decomp years, go through one
    parallel map, so a decomposition is no longer limited to 2^n cores at a
    time or held up by the slowest run of each year;
  - with `future_policies = "off"`, the all-off run at step y is reused from
    the all-on run at step y - 1 rather than simulated again (one run fewer
    per contiguous year);
  - the "every factor off from y + 1" parameters are built once per year
    (per worker) rather than once per run.
  Outputs are identical to the previous version.
* A failed simulation inside `n_cores > 1` now stops with the decomp year and
  run that failed, instead of a later, unrelated-looking error.
* `summarize_results()` (and `prepare_decomp()`'s `full_summary`) may return
  any data.frame. It is converted to a `data.table` on the way in (#6).
* `run_decomp()`, `decomp_algebra()` and `decomp_pair()` match rows to on/off
  combinations by their factor values, so row order no longer matters (#7).
  Incomplete or duplicated combinations, or factor values other than 0/1,
  are now an error instead of a silently wrong result.
* `decomp_pair()` returns a `data.table` with `measure` first, like
  `decomp_algebra()` (#4).
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
