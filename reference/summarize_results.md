# Summarize simulation output into a data.table

Extract summary measures (e.g., deaths, infections) from raw simulation
output. Must return a `data.table` with at minimum a `year` column and
one column per summary variable specified in the decomposition.

## Usage

``` r
summarize_results(model, sim_output, ...)
```

## Arguments

- model:

  An S3 model object

- sim_output:

  Raw simulation output from
  [`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md)

- ...:

  Additional arguments

## Value

A `data.table` with columns: `year`, plus one column per summary
variable (e.g., `deaths`, `infections`).

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md),
[`warm_start`](https://aucarter.github.io/shapleydecomp/reference/warm_start.md)
