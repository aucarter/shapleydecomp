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
  decomp_scalar = 0,
  extended = TRUE,
  step_scenarios = TRUE,
  verbose = TRUE,
  n_cores = 1L,
  future_policies = c("off", "on"),
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

- decomp_scalar:

  Numeric, lower bound for the factor levels in the run table. Default 0
  (binary on/off).

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
  Default 1 (sequential). Values \> 1 use
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html)
  (Unix/Mac only).

- future_policies:

  Character, what every factor does AFTER the decomp year in each
  coalition run. `"off"` is sequential Shapley as specified (Carter,
  "Estimating the impact of public health policies ... with Shapley
  value decomposition", Algorithm 1): at step y all policies before y
  are at their observed values, all policies after y are at their
  counterfactual, and only the year-y policy varies across coalitions.
  The attribution at step y is then the marginal impact of the year-y
  policy conditional on the past and undiluted by the future, and
  [`sequential_totals()`](https://aucarter.github.io/shapleydecomp/reference/sequential_totals.md)
  sums the steps into each factor's total impact at every year. This is
  the default, and matches the published pediatric implementation
  (hiv_decomp run_simmod_mean.R). `"on"` (the pre-2026-09 behaviour,
  kept for reproducing old runs) leaves a factor that is "on" in a
  coalition at its observed values for ALL years, including after y; its
  same-year attribution equals `"off"`'s for any causal model, but its
  `extended_decomp` rows (year \> decomp year) include future policies
  and must not be summed across steps.

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

- params:

  List of decomposition parameters used.

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
#>  1:  2000 infections    -1.98482865       0.00000000
#>  2:  2000     deaths     0.00000000       0.00000000
#>  3:  2001 infections    -2.86518904      -0.59540721
#>  4:  2001     deaths    -0.01984829      -0.01985836
#>  5:  2002 infections    -3.92622649      -1.38933545
#>  6:  2002     deaths    -0.04631687      -0.04634348
#>  7:  2003 infections    -5.18837081      -2.41406979
#>  8:  2003     deaths    -0.08048428      -0.08053602
#>  9:  2004 infections    -6.67529001      -3.70442608
#> 10:  2004     deaths    -0.12351471      -0.12360265
#> 11:  2005 infections    -8.41539243      -5.29842191
#> 12:  2005     deaths    -0.17668099      -0.17681905
#> 13:  2006 infections   -10.44361487      -7.23831458
#> 14:  2006     deaths    -0.24140001      -0.24160541
#> 15:  2007 infections   -12.80345595      -9.57204736
#> 16:  2007     deaths    -0.31928216      -0.31957593
#> 17:  2008 infections   -15.54920984     -12.35512650
#> 18:  2008     deaths    -0.41219568      -0.41260332
#> 19:  2009 infections   -18.74836125     -15.65293347
#> 20:  2009     deaths    -0.52234625      -0.52289856
#> 21:  2010 infections   -22.48411708     -19.54346075
#> 22:  2010     deaths    -0.65237178      -0.65310591
#>      year    measure beta_reduction treatment_effect
#>     <int>     <char>          <num>            <num>
```
