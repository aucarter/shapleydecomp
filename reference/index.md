# Package index

## Run a decomposition

The entry point and its companions.

- [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  : Run a full decomposition analysis
- [`sequential_totals()`](https://aucarter.github.io/shapleydecomp/reference/sequential_totals.md)
  : Total impact per factor at every year from a sequential
  decomposition
- [`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)
  : Validate that a model implements the shapleydecomp interface
- [`CF_CHANGE_SINCE`](https://aucarter.github.io/shapleydecomp/reference/cf_types.md)
  [`CF_TOTAL_IMPACT`](https://aucarter.github.io/shapleydecomp/reference/cf_types.md)
  : Counterfactual type constants

## The model interface

S3 generics your model implements. The first four are required; the rest
are optional and speed things up.

- [`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md)
  : Run a simulation with the given parameters
- [`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md)
  : Summarize simulation output into a data.table
- [`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md)
  : Get the baseline value for a factor
- [`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md)
  : Construct counterfactual parameters for a factor
- [`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md)
  : Prepare the model for decomposition
- [`supports_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md)
  [`get_warm_start_state()`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md)
  [`run_from_warm_start()`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md)
  : Warm starts

## Decomposition algebra

Model-free building blocks. Use them directly if you already have
outcomes for every on/off combination.

- [`make_run_table()`](https://aucarter.github.io/shapleydecomp/reference/make_run_table.md)
  : Generate the factorial run table for decomposition
- [`run_decomp()`](https://aucarter.github.io/shapleydecomp/reference/run_decomp.md)
  : Run decomposition across groups and decomp years
- [`decomp_algebra()`](https://aucarter.github.io/shapleydecomp/reference/decomp_algebra.md)
  : Decompose all summary variables for a single group
- [`decomp_pair()`](https://aucarter.github.io/shapleydecomp/reference/decomp_pair.md)
  : Decompose a single summary variable using Shapley value weights
