# ============================================================================
# shapleydecomp: model_interface.R
#
# S3 generic functions that any discrete-time simulation model must implement
# to use the shapleydecomp framework.
#
# Required methods:
#   - run_simulation()        Run the model with given parameters
#   - summarize_results()     Extract summary measures from simulation output
#   - build_counterfactual()  Construct counterfactual parameters for a factor
#   - get_baseline_value()    Get baseline value for a factor (for change_since)
#
# Optional methods (for performance):
#   - prepare_decomp()        One-time model preparation before decomp loop
#   - supports_warm_start()   Whether the model supports warm starts
#   - get_warm_start_state()  Extract model state at a given year
#   - run_from_warm_start()   Run model from a saved state
# ============================================================================

#' @title Counterfactual type constants
#' @description
#' Two types of counterfactual analysis are supported:
#' \itemize{
#'   \item \code{CF_CHANGE_SINCE}: The counterfactual value is the factor's
#'     value at the baseline year (typically the first decomposition year).
#'     This measures the impact of changes in the factor \emph{since} that
#'     year.
#'   \item \code{CF_TOTAL_IMPACT}: The counterfactual value is zero (or the
#'     model's notion of "no intervention"). This measures the \emph{total}
#'     impact of the factor, not just changes since a reference point.
#' }
#' @return A length-one character string: \code{"change_since"} or
#'   \code{"total_impact"}, the values accepted by the \code{cf_type}
#'   argument of \code{\link{shapley_decompose}}.
#' @name cf_types
#' @examples
#' CF_CHANGE_SINCE
#' CF_TOTAL_IMPACT
#' @export
CF_CHANGE_SINCE <- "change_since"

#' @rdname cf_types
#' @export
CF_TOTAL_IMPACT <- "total_impact"


# ---------------------------------------------------------------------------
#  Required S3 generics
# ---------------------------------------------------------------------------

#' Run a simulation with the given parameters
#'
#' Execute the discrete-time simulation model and return raw simulation output.
#' This is called once for each counterfactual combination at each decomposition
#' year.
#'
#' @param model   An S3 model object (class determines dispatch)
#' @param params  Model parameters (possibly modified for counterfactual)
#' @param ...     Additional arguments passed to the method
#'
#' @return Raw simulation output (model-specific format). Will be passed to
#'   \code{summarize_results()}.
#' @family model interface
#' @export
run_simulation <- function(model, params, ...) {

  UseMethod("run_simulation")
}


#' Summarize simulation output into a data.table
#'
#' Extract summary measures (e.g., deaths, infections) from raw simulation
#' output. Must return a \code{data.table} with at minimum a \code{year}
#' column and one column per summary variable specified in the decomposition.
#'
#' @param model       An S3 model object
#' @param sim_output  Raw simulation output from \code{run_simulation()}
#' @param ...         Additional arguments
#'
#' @return A \code{data.table} with columns: \code{year}, plus one column per
#'   summary variable (e.g., \code{deaths}, \code{infections}).
#' @family model interface
#' @export
summarize_results <- function(model, sim_output, ...) {
  UseMethod("summarize_results")
}


#' Construct counterfactual parameters for a factor
#'
#' Given the observed parameters, produce a modified parameter set where the
#' specified factor is set to its counterfactual value from
#' \code{decomp_year} onward.
#'
#' @param model        An S3 model object
#' @param params       Observed model parameters
#' @param factor_name  Character, name of the factor to modify
#' @param decomp_year  Integer, the year from which the counterfactual applies
#' @param cf_type      Character, one of \code{CF_CHANGE_SINCE} or
#'   \code{CF_TOTAL_IMPACT}
#' @param baseline_values  Named list of baseline values for each factor
#'   (pre-computed by \code{get_baseline_value()})
#' @param ...          Additional arguments
#'
#' @return Modified model parameters with the factor set to its counterfactual
#'   value.
#' @family model interface
#' @export
build_counterfactual <- function(model, params, factor_name, decomp_year,
                                 cf_type, baseline_values, ...) {
  UseMethod("build_counterfactual")
}


#' Get the baseline value for a factor
#'
#' Returns the value of a factor at the baseline year (for
#' \code{CF_CHANGE_SINCE}) or the zero/null value (for
#' \code{CF_TOTAL_IMPACT}). Called once per factor before the decomposition
#' loop begins.
#'
#' @param model     An S3 model object
#' @param params    Observed model parameters
#' @param factor_name  Character, name of the factor
#' @param cf_type   Character, \code{CF_CHANGE_SINCE} or \code{CF_TOTAL_IMPACT}
#' @param baseline_year  Integer, the reference year for \code{CF_CHANGE_SINCE}
#' @param ...       Additional arguments
#'
#' @return The baseline value for the factor (format is model-specific).
#' @family model interface
#' @export
get_baseline_value <- function(model, params, factor_name, cf_type,
                               baseline_year, ...) {
  UseMethod("get_baseline_value")
}


# ---------------------------------------------------------------------------
#  Optional S3 generics (with defaults)
# ---------------------------------------------------------------------------

#' Prepare the model for decomposition
#'
#' One-time preparation step called before the decomposition loop. Use this
#' for expensive setup operations like running an initial simulation to extract
#' denominators, converting counts to percentages, etc.
#'
#' The default method returns the model and params unchanged.
#'
#' @param model   An S3 model object
#' @param params  Model parameters
#' @param ...     Additional arguments
#'
#' @return A list with components:
#'   \item{model}{Possibly modified model object}
#'   \item{params}{Possibly modified parameters}
#'   \item{full_sim}{Optional: output of a full (observed) simulation, used
#'     for warm starts and as the "all-on" reference}
#'   \item{full_summary}{Optional: summary of the full simulation}
#' @family model interface
#' @export
prepare_decomp <- function(model, params, ...) {
  UseMethod("prepare_decomp")
}

#' @export
prepare_decomp.default <- function(model, params, ...) {
  sim <- run_simulation(model, params, ...)
  summary <- summarize_results(model, sim, ...)
  list(
    model        = model,
    params       = params,
    full_sim     = sim,
    full_summary = summary
  )
}


#' Warm starts
#'
#' Optional methods that let \code{shapley_decompose()} skip re-simulating
#' the years before each decomposition year. Up to year \eqn{y - 1} every
#' coalition run is identical to the observed run, so a model that can
#' restart from saved state only needs to simulate from \eqn{y} onward.
#'
#' When \code{supports_warm_start()} returns \code{TRUE},
#' \code{shapley_decompose()} calls
#' \code{run_from_warm_start(model, warm_state, params, output_years,
#' warm_start_year = y - 1, ...)} for every counterfactual run instead of
#' \code{run_simulation()}. \code{warm_state} is the observed simulation
#' output (the \code{full_sim} returned by \code{prepare_decomp()}).
#' \code{run_from_warm_start()} extracts the state at the end of
#' \code{warm_start_year} from it, typically by calling
#' \code{get_warm_start_state(model, warm_state, warm_start_year)}, and
#' simulates forward with the counterfactual \code{params}.
#' \code{shapley_decompose()} itself never calls \code{get_warm_start_state()}.
#' It is the conventional helper for that extraction step.
#'
#' The default \code{supports_warm_start()} returns \code{FALSE}. The default
#' \code{get_warm_start_state()} and \code{run_from_warm_start()} methods
#' throw an error.
#'
#' @param model         An S3 model object
#' @param sim_output    Observed simulation output from \code{run_simulation()}
#' @param year          Integer, the year whose end-of-year state to extract
#' @param warm_state    Observed simulation output to restart from (the
#'   \code{full_sim} element returned by \code{prepare_decomp()})
#' @param params        Model parameters (possibly counterfactual)
#' @param output_years  Integer vector of years the output must cover
#' @param ...           Additional arguments. \code{shapley_decompose()}
#'   passes \code{warm_start_year} to \code{run_from_warm_start()} here.
#'
#' @return \code{supports_warm_start()}: logical.
#'   \code{get_warm_start_state()}: a model state object in a model-specific
#'   format. \code{run_from_warm_start()}: raw simulation output in the same
#'   format as \code{run_simulation()}, covering at least
#'   \code{output_years}.
#' @family model interface
#' @name warm_start
#' @examples
#' # A stock that decays by 20% a year and receives input x:
#' # s_t = 0.8 * s_{t-1} + x_t
#' run_simulation.stock_model <- function(model, params, ...) {
#'   s <- as.numeric(stats::filter(params$x, 0.8, method = "recursive"))
#'   data.table::data.table(year = params$years, stock = s)
#' }
#' summarize_results.stock_model <- function(model, sim_output, ...) sim_output
#' get_baseline_value.stock_model <- function(model, params, factor_name,
#'                                            cf_type, baseline_year, ...) {
#'   list(type = "zero")
#' }
#' build_counterfactual.stock_model <- function(model, params, factor_name,
#'                                              decomp_year, cf_type,
#'                                              baseline_values, ...) {
#'   params$x[params$years >= decomp_year] <- 0
#'   params
#' }
#'
#' # Warm start: restart from the observed stock at the end of
#' # warm_start_year and simulate only the remaining years
#' supports_warm_start.stock_model <- function(model, ...) TRUE
#' get_warm_start_state.stock_model <- function(model, sim_output, year, ...) {
#'   s <- sim_output$stock[sim_output$year == year]
#'   # Before the first simulated year there is no stock yet
#'   if (length(s) == 0) 0 else s
#' }
#' run_from_warm_start.stock_model <- function(model, warm_state, params,
#'                                             output_years, warm_start_year,
#'                                             ...) {
#'   s0   <- get_warm_start_state(model, warm_state, warm_start_year)
#'   keep <- params$years > warm_start_year
#'   s <- as.numeric(stats::filter(params$x[keep], 0.8, method = "recursive",
#'                                 init = s0))
#'   data.table::data.table(year = params$years[keep], stock = s)
#' }
#'
#' for (g in c("run_simulation", "summarize_results", "get_baseline_value",
#'             "build_counterfactual", "supports_warm_start",
#'             "get_warm_start_state", "run_from_warm_start")) {
#'   .S3method(g, "stock_model", get(paste0(g, ".stock_model")))
#' }
#'
#' params <- list(years = 2000:2010, x = rep(1, 11))
#' warm <- shapley_decompose(structure(list(), class = "stock_model"), params,
#'                           factors = "x", summary_vars = "stock",
#'                           decomp_years = 2000:2010,
#'                           cf_type = "total_impact", verbose = FALSE)
#'
#' # The same model without warm starts gives the same answer
#' .S3method("supports_warm_start", "stock_cold", function(model, ...) FALSE)
#' cold <- shapley_decompose(structure(list(), class = c("stock_cold",
#'                                                       "stock_model")),
#'                           params, factors = "x", summary_vars = "stock",
#'                           decomp_years = 2000:2010,
#'                           cf_type = "total_impact", verbose = FALSE)
#' all.equal(warm$decomp, cold$decomp)
NULL

#' @rdname warm_start
#' @export
supports_warm_start <- function(model, ...) {
  UseMethod("supports_warm_start")
}

#' @export
supports_warm_start.default <- function(model, ...) {
  FALSE
}


#' @rdname warm_start
#' @export
get_warm_start_state <- function(model, sim_output, year, ...) {
  UseMethod("get_warm_start_state")
}

#' @export
get_warm_start_state.default <- function(model, sim_output, year, ...) {
  stop(
    "get_warm_start_state() not implemented for class '",
    paste(class(model), collapse = "', '"),
    "'. Set supports_warm_start() to return TRUE and implement this method."
  )
}


#' @rdname warm_start
#' @export
run_from_warm_start <- function(model, warm_state, params, output_years, ...) {
  UseMethod("run_from_warm_start")
}

#' @export
run_from_warm_start.default <- function(model, warm_state, params,
                                        output_years, ...) {
  stop(
    "run_from_warm_start() not implemented for class '",
    paste(class(model), collapse = "', '"),
    "'. Set supports_warm_start() to return TRUE and implement this method."
  )
}
