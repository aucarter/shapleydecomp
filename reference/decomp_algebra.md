# Decompose all summary variables for a single group

Decompose all summary variables for a single group

## Usage

``` r
decomp_algebra(data, params)
```

## Arguments

- data:

  A `data.table` for a single group × decomp-year with one row per
  on/off combination of the factors, in any order.

- params:

  Parameter list (see `run_decomp`).

## Value

A `data.table` with one row per summary variable: a `measure` column and
one column per factor.

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
# The interaction term is split evenly: a gets 5 + 1, b gets 3 + 1
decomp_algebra(rt, list(summary_vars = "y", decomp_vars = c("a", "b"),
                        decomp_method = "shapley"))
#>    measure     a     b
#>     <char> <num> <num>
#> 1:       y     6     4
```
