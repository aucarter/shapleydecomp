# shapleydecomp: Generic Decomposition Framework for Discrete-Time Simulations

A model-agnostic decomposition framework that attributes changes in
simulation outcomes to individual input factors using Shapley value
decomposition. Any calibrated discrete-time simulation model can be
decomposed by implementing a small set of S3 methods: run the model,
summarize outputs, and construct counterfactual inputs. Supports two
counterfactual types: "change_since" (hold factor at baseline-year
value) and "total_impact" (set factor to zero).

## See also

Useful links:

- <https://github.com/aucarter/shapleydecomp>

- <https://aucarter.github.io/shapleydecomp/>

- Report bugs at <https://github.com/aucarter/shapleydecomp/issues>

## Author

**Maintainer**: Austin Carter <aucarter@uw.edu>
