# shapleydecomp: Shapley Value Decomposition for Discrete-Time Simulation Models

Attributes changes in the outcomes of a discrete-time simulation model
to its input factors using Shapley values (Shapley 1953)
[doi:10.1515/9781400881970-018](https://doi.org/10.1515/9781400881970-018)
, which for binary factors coincide with the symmetric standardization
of Das Gupta (1993)
<https://www2.census.gov/library/publications/1993/demographics/p23-186.pdf>.
Any calibrated model can be decomposed by implementing four S3 methods
that run the model, summarize its output, and construct counterfactual
inputs. Counterfactuals either remove a factor entirely or hold it at
its value in a baseline year, and a sequential decomposition attributes
each year's policy conditional on the past.

## See also

Useful links:

- <https://github.com/aucarter/shapleydecomp>

- <https://aucarter.github.io/shapleydecomp/>

- Report bugs at <https://github.com/aucarter/shapleydecomp/issues>

## Author

**Maintainer**: Austin Carter <aucarter@uw.edu>
