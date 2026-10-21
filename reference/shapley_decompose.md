# Run a full decomposition analysis

This is the main user-facing function. Given a model object that
implements the shapleydecomp S3 interface, it performs a complete
factorial decomposition of the specified factors across all
decomposition years.

## Usage

``` r
shapley_decompose(
  model,
  params,
  factors,
  summary_vars,
  decomp_years,
  method = "shapley",
  cf_type = CF_CHANGE_SINCE,
  baseline_year = min(decomp_years),
  extended = TRUE,
  step_scenarios = TRUE,
  verbose = TRUE,
  n_cores = 1L,
  group_vars = character(),
  ...
)
```

## Arguments

- model:

  An S3 model object. Must have methods for
  [`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
  [`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
  [`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
  and
  [`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md).

- params:

  Model parameters (model-specific list/object).

- factors:

  Character vector of factor names to decompose.

- summary_vars:

  Character vector of summary variable names (columns in the output of
  [`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md)).

- decomp_years:

  Integer vector of years at which to perform decomposition (e.g.,
  `2000:2023`).

- method:

  Character, decomposition method. Only `"shapley"` (default) is
  supported. `"das_gupta"` is accepted as a deprecated alias: Das
  Gupta's symmetric standardization is the special case of the Shapley
  value for binary on/off factors, so the weights are identical.

- cf_type:

  Character, counterfactual type: `"change_since"` (default) —
  counterfactual is the value at the baseline year; or `"total_impact"`
  — counterfactual is zero / no intervention.

- baseline_year:

  Integer, the reference year for `"change_since"` counterfactuals.
  Defaults to `min(decomp_years)`.

- extended:

  Logical, whether to compute the extended factor decomposition (effects
  at all output years \>= decomp year). Default TRUE.

- step_scenarios:

  Logical, whether to compute step scenarios (all-on time series per
  decomp year). Default TRUE.

- verbose:

  Logical, print progress messages. Default TRUE.

- n_cores:

  Integer, number of cores for parallel counterfactual simulation runs.
  Default 1 (sequential). Values \> 1 run every counterfactual
  simulation, across all decomp years, in one
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  map, so that more cores than the 2^n runs of a single year can be
  used. Windows does not support forking, so there it falls back to
  sequential with a warning.

- group_vars:

  Character vector of columns in the output of
  [`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md)
  that identify independent groups, such as locations or draws, each
  decomposed separately. Default none.

- ...:

  Additional arguments passed to model methods.

## Value

A list with components:

- decomp:

  data.table — standard year-by-year decomposition (one row per decomp
  year × measure, factor effects in columns)

- step_scenarios:

  data.table — all-on time series per decomp year (columns: step_year,
  year, plus summary vars). NULL if `step_scenarios = FALSE`.

- extended_decomp:

  data.table — extended decomposition (factor effects at all years \>=
  decomp year). NULL if `extended = FALSE`.

- run_table:

  data.table — the factorial design table used.

- run_summary:

  data.table — per decomp year: the number of coalition runs, how many
  were simulated, how many were reused from the previous step, and the
  factors that were null players (their counterfactual left the params
  unchanged, so their effect is 0).

- params:

  List of decomposition parameters used.

## Details

The decomposition is sequential (Carter 2025, *Quantifying averted
burden from infectious disease control policies*, PhD dissertation,
University of Washington, <https://hdl.handle.net/1773/53310>). At each
decomp year y, every policy before y is at its observed value, every
policy after y is at its counterfactual, and only the year-y policy
varies across the 2^n coalitions. The attribution at step y is therefore
the marginal impact of the year-y policy, conditional on the past and
undiluted by the future. `extended_decomp` records that impact at every
later year, and
[`sequential_totals()`](https://aucarter.github.io/shapleydecomp/reference/sequential_totals.md)
sums the steps into each factor's total impact at every year.

## See also

[`vignette("shapleydecomp")`](https://aucarter.github.io/shapleydecomp/articles/shapleydecomp.md)
for a worked example, and
[`validate_model_interface`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)
to check a model first.

## Examples

``` r
# A two-factor SIR model shipped with the package
sir <- new.env()
sys.source(system.file("examples", "sir_model.R", package = "shapleydecomp"),
           envir = sir)
model  <- sir$create_sir_model(years = 1990:2010)
params <- sir$create_sir_params(years = 1990:2010)

res <- shapley_decompose(
  model, params,
  factors      = c("beta_reduction", "treatment_effect"),
  summary_vars = c("infections", "deaths"),
  decomp_years = 2000:2010,
  cf_type      = "total_impact",
  verbose      = FALSE
)
res$decomp
#>     decomp_year    measure beta_reduction treatment_effect
#>           <int>     <char>          <num>            <num>
#>  1:        2000 infections      -1.984829                0
#>  2:        2000     deaths       0.000000                0
#>  3:        2001 infections      -2.270260                0
#>  4:        2001     deaths       0.000000                0
#>  5:        2002 infections      -2.538106                0
#>  6:        2002     deaths       0.000000                0
#>  7:        2003 infections      -2.776584                0
#>  8:        2003     deaths       0.000000                0
#>  9:        2004 infections      -2.974630                0
#> 10:        2004     deaths       0.000000                0
#> 11:        2005 infections      -3.122727                0
#> 12:        2005     deaths       0.000000                0
#> 13:        2006 infections      -3.213661                0
#> 14:        2006     deaths       0.000000                0
#> 15:        2007 infections      -3.243109                0
#> 16:        2007     deaths       0.000000                0
#> 17:        2008 infections      -3.210005                0
#> 18:        2008     deaths       0.000000                0
#> 19:        2009 infections      -3.116622                0
#> 20:        2009     deaths       0.000000                0
#> 21:        2010 infections      -2.968382                0
#> 22:        2010     deaths       0.000000                0
#>     decomp_year    measure beta_reduction treatment_effect
#>           <int>     <char>          <num>            <num>

# Each factor's total impact at every year
sequential_totals(res)
#>      year    measure beta_reduction treatment_effect
#>     <int>     <char>          <num>            <num>
#>  1:  2000 infections    -1.98482865     4.440892e-16
#>  2:  2000     deaths     0.00000000     0.000000e+00
#>  3:  2001 infections    -2.86518904    -5.954072e-01
#>  4:  2001     deaths    -0.01984829    -1.985836e-02
#>  5:  2002 infections    -3.92622649    -1.389335e+00
#>  6:  2002     deaths    -0.04631687    -4.634348e-02
#>  7:  2003 infections    -5.18837081    -2.414070e+00
#>  8:  2003     deaths    -0.08048428    -8.053602e-02
#>  9:  2004 infections    -6.67529001    -3.704426e+00
#> 10:  2004     deaths    -0.12351471    -1.236027e-01
#> 11:  2005 infections    -8.41539243    -5.298422e+00
#> 12:  2005     deaths    -0.17668099    -1.768191e-01
#> 13:  2006 infections   -10.44361487    -7.238315e+00
#> 14:  2006     deaths    -0.24140001    -2.416054e-01
#> 15:  2007 infections   -12.80345595    -9.572047e+00
#> 16:  2007     deaths    -0.31928216    -3.195759e-01
#> 17:  2008 infections   -15.54920984    -1.235513e+01
#> 18:  2008     deaths    -0.41219568    -4.126033e-01
#> 19:  2009 infections   -18.74836125    -1.565293e+01
#> 20:  2009     deaths    -0.52234625    -5.228986e-01
#> 21:  2010 infections   -22.48411708    -1.954346e+01
#> 22:  2010     deaths    -0.65237178    -6.531059e-01
#>      year    measure beta_reduction treatment_effect
#>     <int>     <char>          <num>            <num>
```
