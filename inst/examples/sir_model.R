# ============================================================================
# sir_model.R
#
# Example: implementing the decomposer interface for a simple discrete-time
# SIR model. Shipped with the package so that examples, tests and vignettes
# can share one worked model:
#
#   source(system.file("examples", "sir_model.R", package = "decomposer"))
#
# Model: SIR with two decomposable factors:
#   - beta_reduction   (proportional reduction in transmission, e.g. from
#                       prevention interventions)
#   - treatment_effect (additive increase in the recovery rate from treatment)
#
# The model runs in discrete yearly time steps.
# ============================================================================

# ---------------------------------------------------------------------------
#  1. Define the model
# ---------------------------------------------------------------------------

# Create an SIR model object (an S3 object of class "sir_model").
create_sir_model <- function(population = 100000, years = 1990:2020) {
  model <- list(
    population = population,
    years      = years,
    S0         = population - 10,  # Initial susceptible
    I0         = 10,               # Initial infected
    R0         = 0                 # Initial recovered
  )
  class(model) <- "sir_model"
  model
}

# Create SIR model parameters. beta_reduction and treatment_effect are named
# numeric vectors (year -> value); by default both scale up linearly.
create_sir_params <- function(years = 1990:2020,
                              base_beta = 0.3,
                              gamma = 0.1,
                              beta_reduction = NULL,
                              treatment_effect = NULL) {
  n <- length(years)
  yr_names <- as.character(years)

  if (is.null(beta_reduction)) {
    beta_reduction <- stats::setNames(seq(0, 0.5, length.out = n), yr_names)
  }
  if (is.null(treatment_effect)) {
    treatment_effect <- stats::setNames(seq(0, 0.15, length.out = n), yr_names)
  }

  list(
    years            = years,
    base_beta        = base_beta,
    gamma            = gamma,
    beta_reduction   = beta_reduction,
    treatment_effect = treatment_effect
  )
}


# ---------------------------------------------------------------------------
#  2. Implement the decomposer S3 interface
# ---------------------------------------------------------------------------

run_simulation.sir_model <- function(model, params, ...) {
  years <- model$years
  n     <- length(years)
  N     <- model$population

  S <- numeric(n); I <- numeric(n); R <- numeric(n)
  new_infections <- numeric(n); deaths <- numeric(n)

  S[1] <- model$S0; I[1] <- model$I0; R[1] <- model$R0

  for (t in 2:n) {
    yr <- as.character(years[t])
    beta  <- params$base_beta * (1 - params$beta_reduction[[yr]])
    gamma <- params$gamma + params$treatment_effect[[yr]]

    new_inf <- beta * S[t - 1] * I[t - 1] / N
    new_rec <- gamma * I[t - 1]
    disease_deaths <- 0.01 * I[t - 1]  # 1% disease mortality

    S[t] <- S[t - 1] - new_inf
    I[t] <- I[t - 1] + new_inf - new_rec - disease_deaths
    R[t] <- R[t - 1] + new_rec

    new_infections[t] <- new_inf
    deaths[t] <- disease_deaths
  }

  data.table::data.table(
    year       = years,
    S          = S,
    I          = I,
    R          = R,
    infections = new_infections,
    deaths     = deaths
  )
}

summarize_results.sir_model <- function(model, sim_output, ...) {
  sim_output[, c("year", "infections", "deaths"), with = FALSE]
}

get_baseline_value.sir_model <- function(model, params, factor_name, cf_type,
                                         baseline_year, ...) {
  if (cf_type == decomposer::CF_TOTAL_IMPACT) {
    return(list(type = "zero"))
  }
  if (!factor_name %in% c("beta_reduction", "treatment_effect")) {
    stop(sprintf("Unknown factor: %s", factor_name))
  }
  # CF_CHANGE_SINCE: hold at the baseline-year value
  list(type  = "change_since",
       value = params[[factor_name]][[as.character(baseline_year)]])
}

build_counterfactual.sir_model <- function(model, params, factor_name,
                                           decomp_year, cf_type,
                                           baseline_values, ...) {
  idx <- which(params$years >= decomp_year)
  if (cf_type == decomposer::CF_TOTAL_IMPACT) {
    params[[factor_name]][idx] <- 0
  } else {
    params[[factor_name]][idx] <- baseline_values[[factor_name]]$value
  }
  params
}


# ---------------------------------------------------------------------------
#  3. Register the methods
#
#  Methods defined at the top level of a script you source() are found by
#  ordinary S3 dispatch. Registering them explicitly makes this file work
#  wherever it is evaluated (inside a function, a vignette chunk, or an
#  example). In a package, declare them with S3method() in NAMESPACE (roxygen:
#  @export on the method) instead.
# ---------------------------------------------------------------------------

.S3method("run_simulation",       "sir_model", run_simulation.sir_model)
.S3method("summarize_results",    "sir_model", summarize_results.sir_model)
.S3method("get_baseline_value",   "sir_model", get_baseline_value.sir_model)
.S3method("build_counterfactual", "sir_model", build_counterfactual.sir_model)
