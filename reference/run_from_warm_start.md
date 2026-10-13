# Run a simulation from a saved warm-start state

Run a simulation from a saved warm-start state

## Usage

``` r
run_from_warm_start(model, warm_state, params, output_years, ...)
```

## Arguments

- model:

  An S3 model object

- warm_state:

  State object from
  [`get_warm_start_state()`](https://aucarter.github.io/shapleydecomp/reference/get_warm_start_state.md)

- params:

  Model parameters (possibly counterfactual)

- output_years:

  Integer vector of years to produce output for

- ...:

  Additional arguments

## Value

Raw simulation output (same format as
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md))

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`get_warm_start_state()`](https://aucarter.github.io/shapleydecomp/reference/get_warm_start_state.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`supports_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/supports_warm_start.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)
