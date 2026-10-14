# Decompose a single summary variable using Shapley value weights

For each factor, computes the weighted average marginal effect of
switching the factor from 0 (counterfactual) to 1 (observed), averaging
over all combinations of the other factors.

## Usage

``` r
decomp_pair(dt, params, summary_var)
```

## Arguments

- dt:

  A `data.table` with one row per on/off combination of the factors, in
  any order.

- params:

  Parameter list with `decomp_vars` and `decomp_method`.

- summary_var:

  Character, the name of the summary variable column.

## Value

A one-row `data.table` with a `measure` column and one column per
factor.

## Examples

``` r
rt <- make_run_table(c("a", "b"))
rt[, y := 10 + 5 * a + 3 * b + 2 * a * b]
#>    run_id     a     b     y
#>     <int> <int> <int> <num>
#> 1:      1     0     0    10
#> 2:      2     1     0    15
#> 3:      3     0     1    13
#> 4:      4     1     1    20
decomp_pair(rt, list(decomp_vars = c("a", "b"), decomp_method = "shapley"),
            "y")
#>    measure     a     b
#>     <char> <num> <num>
#> 1:       y     6     4
```
