# Prepare the model for decomposition

One-time preparation step called before the decomposition loop. Use this
for expensive setup operations like running an initial simulation to
extract denominators, converting counts to percentages, etc.

## Usage

``` r
prepare_decomp(model, params, ...)
```

## Arguments

- model:

  An S3 model object

- params:

  Model parameters

- ...:

  Additional arguments

## Value

A list with components:

- model:

  Possibly modified model object

- params:

  Possibly modified parameters

- full_sim:

  Optional: output of a full (observed) simulation, used for warm starts
  and as the "all-on" reference

- full_summary:

  Optional: summary of the full simulation

## Details

The default method returns the model and params unchanged.

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`get_warm_start_state()`](https://aucarter.github.io/shapleydecomp/reference/get_warm_start_state.md),
[`run_from_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/run_from_warm_start.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`supports_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/supports_warm_start.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)
