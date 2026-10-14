# Run decomposition across groups and decomp years

Applies the Shapley decomposition to each group × decomp-year in the
data.

## Usage

``` r
run_decomp(data, params)
```

## Arguments

- data:

  A `data.table` with one column per decomp variable (0/1 indicator),
  one column per summary variable, and optionally a `decomp_year` column
  and the `group_vars` columns. Each group must have exactly one row per
  on/off combination; row order does not matter.

- params:

  A list with at least:

  summary_vars

  :   Character vector of summary variable column names

  decomp_vars

  :   Character vector of factor column names (0/1 indicators)

  decomp_method

  :   Character, `"shapley"` (`"das_gupta"` accepted as a deprecated
      alias)

  group_vars

  :   Optional character vector of grouping columns, such as a location
      identifier

## Value

A `data.table` with one row per group × decomp-year × measure, and one
column per factor giving its decomposition effect.

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
