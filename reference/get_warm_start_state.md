# Extract model state at a given year for warm restart

Extract model state at a given year for warm restart

## Usage

``` r
get_warm_start_state(model, sim_output, year, ...)
```

## Arguments

- model:

  An S3 model object

- sim_output:

  Full simulation output from
  [`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md)

- year:

  Integer, the year at which to extract state

- ...:

  Additional arguments

## Value

A model state object (model-specific format)

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_from_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/run_from_warm_start.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`supports_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/supports_warm_start.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)
