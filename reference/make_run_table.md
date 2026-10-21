# Generate the factorial run table for decomposition

Creates a `data.table` with one row per counterfactual combination. Each
factor column contains 0 (counterfactual) or 1 (observed), encoding
whether that factor is "on" or "off" for that run.

## Usage

``` r
make_run_table(factors)
```

## Arguments

- factors:

  Character vector of factor names.

## Value

A `data.table` with 2^n rows: `run_id` (integer), and one column per
factor with values 0 or 1.

## Examples

``` r
make_run_table(c("treatment", "prevention", "demography"))
#>    run_id treatment prevention demography
#>     <int>     <int>      <int>      <int>
#> 1:      1         0          0          0
#> 2:      2         1          0          0
#> 3:      3         0          1          0
#> 4:      4         1          1          0
#> 5:      5         0          0          1
#> 6:      6         1          0          1
#> 7:      7         0          1          1
#> 8:      8         1          1          1
```
