# Get the baseline value for a factor

Returns the value of a factor at the baseline year (for
`CF_CHANGE_SINCE`) or the zero/null value (for `CF_TOTAL_IMPACT`).
Called once per factor before the decomposition loop begins.

## Usage

``` r
get_baseline_value(model, params, factor_name, cf_type, baseline_year, ...)
```

## Arguments

- model:

  An S3 model object

- params:

  Observed model parameters

- factor_name:

  Character, name of the factor

- cf_type:

  Character, `CF_CHANGE_SINCE` or `CF_TOTAL_IMPACT`

- baseline_year:

  Integer, the reference year for `CF_CHANGE_SINCE`

- ...:

  Additional arguments

## Value

The baseline value for the factor (format is model-specific).

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_warm_start_state()`](https://aucarter.github.io/shapleydecomp/reference/get_warm_start_state.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_from_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/run_from_warm_start.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`supports_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/supports_warm_start.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)
