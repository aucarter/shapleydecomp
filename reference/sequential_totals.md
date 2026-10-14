# Total impact per factor at every year from a sequential decomposition

Sums the step attributions of a `future_policies = "off"` run across
decomposition steps: the total impact of factor i at year T is
\\\sum\_{y \le T} \phi_i^{(y)}(T)\\, where \\\phi_i^{(y)}(T)\\ is the
Shapley value at year T of the year-y policy (`extended_decomp`). Summed
over factors this telescopes to (observed) - (all policies off from the
first decomp year) at every T, so it is only meaningful when
`decomp_years` is contiguous.

## Usage

``` r
sequential_totals(result)
```

## Arguments

- result:

  The list returned by
  [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  with `extended = TRUE` and `future_policies = "off"`.

## Value

data.table with one row per group x year x measure and one column per
factor.

## See also

[`shapley_decompose`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md),
whose examples call this function.
