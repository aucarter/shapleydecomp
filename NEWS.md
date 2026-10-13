# decomposer 0.2.0

* `decompose()` gains `future_policies`, defaulting to `"off"`: sequential
  Shapley, where each step varies only that year's policy and every later
  policy is held at its counterfactual. `"on"` reproduces earlier runs.
* New `sequential_totals()` sums sequential steps into each factor's total
  impact at every year.
* Decomposition is unified on the Shapley value. `method = "das_gupta"` is a
  deprecated alias that gives identical results.

# decomposer 0.1.0

* Initial version: model-agnostic factorial decomposition through an S3
  interface, with `"change_since"` and `"total_impact"` counterfactuals and
  optional warm starts.
