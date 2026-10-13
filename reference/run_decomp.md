# Run decomposition across locations and decomp years

Applies
[`decomp_algebra()`](https://aucarter.github.io/shapleydecomp/reference/decomp_algebra.md)
to each location × decomp-year group in the data.

## Usage

``` r
run_decomp(data, params)
```

## Arguments

- data:

  A `data.table` with columns: `ihme_loc_id`, `decomp_year`, one column
  per decomp variable (0/1 indicator), and one column per summary
  variable.

- params:

  A list with at least:

  summary_vars

  :   Character vector of summary variable column names

  decomp_vars

  :   Character vector of factor column names (0/1 indicators)

  decomp_method

  :   Character, `"shapley"` (`"das_gupta"` accepted as a deprecated
      alias)

## Value

A `data.table` with one row per location × decomp-year × measure, and
one column per factor giving its decomposition effect.

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
rt[, decomp_year := 2000L]
#>    run_id     a     b     y decomp_year
#>     <int> <int> <int> <num>       <int>
#> 1:      1     0     0    10        2000
#> 2:      2     1     0    15        2000
#> 3:      3     0     1    13        2000
#> 4:      4     1     1    20        2000
run_decomp(rt, list(summary_vars = "y", decomp_vars = c("a", "b"),
                    decomp_method = "shapley"))
#>    decomp_year measure     a     b
#>          <int>  <char> <num> <num>
#> 1:        2000       y     6     4
```
