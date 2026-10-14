# Warm starts

Optional methods that let
[`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
skip re-simulating the years before each decomposition year. Up to year
\\y - 1\\ every coalition run is identical to the observed run, so a
model that can restart from saved state only needs to simulate from
\\y\\ onward.

## Usage

``` r
supports_warm_start(model, ...)

get_warm_start_state(model, sim_output, year, ...)

run_from_warm_start(model, warm_state, params, output_years, ...)
```

## Arguments

- model:

  An S3 model object

- ...:

  Additional arguments.
  [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  passes `warm_start_year` to `run_from_warm_start()` here.

- sim_output:

  Observed simulation output from
  [`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md)

- year:

  Integer, the year whose end-of-year state to extract

- warm_state:

  Observed simulation output to restart from (the `full_sim` element
  returned by
  [`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md))

- params:

  Model parameters (possibly counterfactual)

- output_years:

  Integer vector of years the output must cover

## Value

`supports_warm_start()`: logical. `get_warm_start_state()`: a model
state object in a model-specific format. `run_from_warm_start()`: raw
simulation output in the same format as
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
covering at least `output_years`.

## Details

When `supports_warm_start()` returns `TRUE`,
[`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
calls
`run_from_warm_start(model, warm_state, params, output_years, warm_start_year = y - 1, ...)`
for every counterfactual run instead of
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md).
`warm_state` is the observed simulation output (the `full_sim` returned
by
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md)).
`run_from_warm_start()` extracts the state at the end of
`warm_start_year` from it, typically by calling
`get_warm_start_state(model, warm_state, warm_start_year)`, and
simulates forward with the counterfactual `params`.
[`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
itself never calls `get_warm_start_state()`. It is the conventional
helper for that extraction step.

The default `supports_warm_start()` returns `FALSE`. The default
`get_warm_start_state()` and `run_from_warm_start()` methods throw an
error.

## See also

Other model interface:
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md),
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md),
[`prepare_decomp()`](https://aucarter.github.io/shapleydecomp/reference/prepare_decomp.md),
[`run_simulation()`](https://aucarter.github.io/shapleydecomp/reference/run_simulation.md),
[`summarize_results()`](https://aucarter.github.io/shapleydecomp/reference/summarize_results.md),
[`validate_model_interface()`](https://aucarter.github.io/shapleydecomp/reference/validate_model_interface.md)

## Examples

``` r
# A stock that decays by 20% a year and receives input x:
# s_t = 0.8 * s_{t-1} + x_t
run_simulation.stock_model <- function(model, params, ...) {
  s <- as.numeric(stats::filter(params$x, 0.8, method = "recursive"))
  data.table::data.table(year = params$years, stock = s)
}
summarize_results.stock_model <- function(model, sim_output, ...) sim_output
get_baseline_value.stock_model <- function(model, params, factor_name,
                                           cf_type, baseline_year, ...) {
  list(type = "zero")
}
build_counterfactual.stock_model <- function(model, params, factor_name,
                                             decomp_year, cf_type,
                                             baseline_values, ...) {
  params$x[params$years >= decomp_year] <- 0
  params
}

# Warm start: restart from the observed stock at the end of
# warm_start_year and simulate only the remaining years
supports_warm_start.stock_model <- function(model, ...) TRUE
get_warm_start_state.stock_model <- function(model, sim_output, year, ...) {
  s <- sim_output$stock[sim_output$year == year]
  # Before the first simulated year there is no stock yet
  if (length(s) == 0) 0 else s
}
run_from_warm_start.stock_model <- function(model, warm_state, params,
                                            output_years, warm_start_year,
                                            ...) {
  s0   <- get_warm_start_state(model, warm_state, warm_start_year)
  keep <- params$years > warm_start_year
  s <- as.numeric(stats::filter(params$x[keep], 0.8, method = "recursive",
                                init = s0))
  data.table::data.table(year = params$years[keep], stock = s)
}

for (g in c("run_simulation", "summarize_results", "get_baseline_value",
            "build_counterfactual", "supports_warm_start",
            "get_warm_start_state", "run_from_warm_start")) {
  .S3method(g, "stock_model", get(paste0(g, ".stock_model")))
}

params <- list(years = 2000:2010, x = rep(1, 11))
warm <- shapley_decompose(structure(list(), class = "stock_model"), params,
                          factors = "x", summary_vars = "stock",
                          decomp_years = 2000:2010,
                          cf_type = "total_impact", verbose = FALSE)

# The same model without warm starts gives the same answer
.S3method("supports_warm_start", "stock_cold", function(model, ...) FALSE)
cold <- shapley_decompose(structure(list(), class = c("stock_cold",
                                                      "stock_model")),
                          params, factors = "x", summary_vars = "stock",
                          decomp_years = 2000:2010,
                          cf_type = "total_impact", verbose = FALSE)
all.equal(warm$decomp, cold$decomp)
#> [1] TRUE
```
