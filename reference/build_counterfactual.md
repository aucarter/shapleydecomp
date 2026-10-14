# Construct counterfactual parameters for a factor

Given the observed parameters, produce a modified parameter set where
the specified factor is set to its counterfactual value from
`decomp_year` onward.

## Usage

``` r
build_counterfactual(
  model,
  params,
  factor_name,
  decomp_year,
  cf_type,
  baseline_values,
  ...
)
```

## Arguments

- model:

  An S3 model object

- params:

  Observed model parameters

- factor_name:

  Character, name of the factor to modify

- decomp_year:

  Integer, the year from which the counterfactual applies

- cf_type:

  Character, one of `CF_CHANGE_SINCE` or `CF_TOTAL_IMPACT`

- baseline_values:

  Named list of baseline values for each factor (pre-computed by
  [`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md))

- ...:

  Additional arguments

## Value

Modified model parameters with the factor set to its counterfactual
value.

## See also

Other model interface:
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md),
[`warm_start`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md)
