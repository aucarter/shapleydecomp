# Generate the factorial run table for decomposition

Creates a `data.table` with one row per counterfactual combination. Each
factor column contains 0 (counterfactual) or 1 (observed), encoding
whether that factor is "on" or "off" for that run.

## Usage

``` r
make_run_table(factors, decomp_scalar = 0)
```

## Arguments

- factors:

  Character vector of factor names.

- decomp_scalar:

  Numeric, the lower bound of the factor scale. Default is 0 (binary: 0
  = off, 1 = on).

## Value

A `data.table` with columns: `run_id` (integer), and one column per
factor with values in `decomp_scalar:1`.

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
