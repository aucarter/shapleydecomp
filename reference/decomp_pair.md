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

  A `data.table` with one row per counterfactual combination.

- params:

  Parameter list with `decomp_vars` and `decomp_method`.

- summary_var:

  Character, the name of the summary variable column.

## Value

A one-row `data.frame` with one column per factor (named by factor) plus
a `measure` column.

## Examples

``` r
# Outcomes for every on/off combination of two factors, where the
# factors interact: y = 10 + 5a + 3b + 2ab
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
#>   a b measure
#> 1 6 4       y
```
