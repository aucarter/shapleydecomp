# Run a simulation with the given parameters

Execute the discrete-time simulation model and return raw simulation
output. This is called once for each counterfactual combination at each
decomposition year.

## Usage

``` r
run_simulation(model, params, ...)
```

## Arguments

- model:

  An S3 model object (class determines dispatch)

- params:

  Model parameters (possibly modified for counterfactual)

- ...:

  Additional arguments passed to the method

## Value

Raw simulation output (model-specific format). Will be passed to
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md).

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`get_warm_start_state()`](https://aucarter.github.io/shapleydecomp/reference/get_warm_start_state.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_from_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/run_from_warm_start.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`supports_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/supports_warm_start.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)
