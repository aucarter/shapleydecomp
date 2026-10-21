# Counterfactual type constants

Two types of counterfactual analysis are supported:

- `CF_CHANGE_SINCE`: The counterfactual value is the factor's value at
  the baseline year (typically the first decomposition year). This
  measures the impact of changes in the factor *since* that year.

- `CF_TOTAL_IMPACT`: The counterfactual value is zero (or the model's
  notion of "no intervention"). This measures the *total* impact of the
  factor, not just changes since a reference point.

## Usage

``` r
CF_CHANGE_SINCE

CF_TOTAL_IMPACT
```

## Format

An object of class `character` of length 1.

An object of class `character` of length 1.

## Value

A length-one character string: `"change_since"` or `"total_impact"`, the
values accepted by the `cf_type` argument of
[`shapley_decompose`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md).

## Examples

``` r
CF_CHANGE_SINCE
#> [1] "change_since"
CF_TOTAL_IMPACT
#> [1] "total_impact"
```
