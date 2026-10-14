# Validate that a model implements the shapleydecomp interface

Checks that the required S3 methods exist for the given model class and
runs a minimal smoke test if parameters and factors are provided.

## Usage

``` r
validate_model_interface(
  model,
  params = NULL,
  factors = NULL,
  summary_vars = NULL,
  baseline_year = NULL,
  verbose = TRUE
)
```

## Arguments

- model:

  An S3 model object

- params:

  Optional: model parameters for smoke test

- factors:

  Optional: character vector of factor names

- summary_vars:

  Optional: character vector of summary variable names

- baseline_year:

  Optional: integer baseline year

- verbose:

  Logical, print diagnostic messages

## Value

Invisible TRUE if all checks pass; stops with an error otherwise.

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`warm_start`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md)

## Examples

``` r
sir <- new.env()
sys.source(system.file("examples", "sir_model.R", package = "shapleydecomp"),
           envir = sir)
validate_model_interface(
  sir$create_sir_model(),
  sir$create_sir_params(),
  factors       = c("beta_reduction", "treatment_effect"),
  summary_vars  = c("infections", "deaths"),
  baseline_year = 2000
)
#> Validating shapleydecomp interface for class 'sir_model'
#>   [OK] run_simulation.sir_model
#>   [OK] summarize_results.sir_model
#>   [OK] build_counterfactual.sir_model
#>   [OK] get_baseline_value.sir_model
#>   [--] prepare_decomp.sir_model (optional)
#>   [--] supports_warm_start.sir_model (optional)
#>   [--] get_warm_start_state.sir_model (optional)
#>   [--] run_from_warm_start.sir_model (optional)
#> Running smoke test...
#>   [OK] run_simulation + summarize_results
#>   [OK] get_baseline_value('beta_reduction')
#>   [OK] get_baseline_value('treatment_effect')
#>   [OK] build_counterfactual('beta_reduction')
#> Smoke test passed.
#> Validation complete.
```
