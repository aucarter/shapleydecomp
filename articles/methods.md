# Methods

## Setup

Take a simulation whose outcome at time t depends on n factors, Y_t =
f_t(x_1, \ldots, x_n). Each factor has an **observed** trajectory x_i^1,
the one the calibrated model uses, and a **counterfactual** trajectory
x_i^0. The goal is to split the total difference

\Delta Y_t = f_t(x_1^1, \ldots, x_n^1) - f_t(x_1^0, \ldots, x_n^0)

into contributions \delta_i with \sum_i \delta_i = \Delta Y_t exactly.

## Factorial design

For n factors there are 2^n on/off combinations.
[`make_run_table()`](https://aucarter.github.io/shapleydecomp/reference/make_run_table.md)
enumerates them, and
[`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
runs the model once per row.

``` r

make_run_table(c("a", "b", "c"))
#>    run_id     a     b     c
#>     <int> <int> <int> <int>
#> 1:      1     0     0     0
#> 2:      2     1     0     0
#> 3:      3     0     1     0
#> 4:      4     1     1     0
#> 5:      5     0     0     1
#> 6:      6     1     0     1
#> 7:      7     0     1     1
#> 8:      8     1     1     1
```

## Shapley values

Treat the set S of factors held at their observed values as a coalition,
with value v(S) = f_t(x_S^1, x\_{N \setminus S}^0). The Shapley value of
factor i is its marginal effect averaged over every coalition of the
other factors:

\phi_i = \sum\_{S \subseteq N \setminus \\i\\} \frac{\|S\|!\\(n -
\|S\| - 1)!}{n!}\\\bigl\[v(S \cup \\i\\) - v(S)\bigr\].

It is the only allocation that is **efficient** (the shares sum to
\Delta Y_t), **symmetric** (interchangeable factors get equal shares),
**additive**, and gives zero to a factor that never changes the outcome.

Interactions are split evenly. In the example below, the outcome is 10 +
5a + 3b + 2ab. Factor `a` gets its main effect plus half of the
interaction, and factor `b` gets the same treatment:

``` r

rt <- make_run_table(c("a", "b"))
rt[, y := 10 + 5 * a + 3 * b + 2 * a * b]
decomp_algebra(rt, list(summary_vars = "y", decomp_vars = c("a", "b"),
                        decomp_method = "shapley"))
#>    measure     a     b
#>     <char> <num> <num>
#> 1:       y     6     4
```

### Das Gupta’s standardization is the same thing

Das Gupta’s symmetric standardization, the classical demographic tool,
weights each marginal effect by 1 / \bigl\[n \binom{n-1}{k}\bigr\],
where k = \|S\|. Expanding the binomial gives

\frac{1}{n \binom{n-1}{k}} = \frac{k!\\(n-1-k)!}{n \cdot (n-1)!} =
\frac{k!\\(n-k-1)!}{n!},

which is the Shapley weight. For binary factors the two methods are
identical, so the package implements one weight formula.
`method = "das_gupta"` is accepted as a deprecated alias for
`"shapley"`.

## Counterfactual types

What x_i^0 is determines the question being answered.

| `cf_type` | x_i^0(t) | Question |
|----|----|----|
| `"total_impact"` | 0 (no programme) | How much did this factor avert, in total? |
| `"change_since"` | x_i(t_0), held at `baseline_year` | How much of the change since t_0 is due to this factor? |

Your
[`get_baseline_value()`](https://aucarter.github.io/shapleydecomp/reference/get_baseline_value.md)
and
[`build_counterfactual()`](https://aucarter.github.io/shapleydecomp/reference/build_counterfactual.md)
methods implement these definitions for your model’s parameters. For
example, “zero” for a coverage factor might mean no coverage, while for
a rate it might mean a reference rate.

## Decomposing over time: sequential Shapley

Simulations carry state forward. Infections averted in 2005 change the
susceptible pool in 2010. A single decomposition at a late year would
credit every past policy at once, so
[`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
works year by year.

At each decomposition year y, with the default
`future_policies = "off"`:

- every policy **before** y is at its observed value;
- every policy **after** y is at its counterfactual;
- only the year-y policy varies across the 2^n coalitions.

The Shapley value at step y is therefore the marginal impact of the
year-y policy, conditional on the past and undiluted by the future.
Because the model is simulated forward from y, `extended_decomp` records
that step’s effect at every later year T \ge y, written \phi_i^{(y)}(T).
[`sequential_totals()`](https://aucarter.github.io/shapleydecomp/reference/sequential_totals.md)
sums the steps:

\text{total}\_i(T) = \sum\_{y \le T} \phi_i^{(y)}(T).

Summed over factors, this telescopes to *observed minus all-off from the
first decomposition year* at every T, so the totals stay exact. That
only holds when `decomp_years` is contiguous, and
[`sequential_totals()`](https://aucarter.github.io/shapleydecomp/reference/sequential_totals.md)
checks it.

`future_policies = "on"` reproduces runs made before version 0.2.0. A
factor that is “on” stays at its observed values after y as well. Its
same-year attributions match `"off"` for any causal model, but its
`extended_decomp` rows include future policies, so they must not be
summed across steps.

## Reference

Carter A. *A model-agnostic framework for factorial decomposition of
discrete-time simulation outcomes, with a proof of equivalence between
Das Gupta and Shapley value decomposition.* Manuscript in preparation.
