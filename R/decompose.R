# ============================================================================
# shapleydecomp: decompose.R
#
# Main entry point: orchestrates the full decomposition pipeline.
#
# The shapley_decompose() function:
#   1. Prepares the model (one-time setup)
#   2. Computes baseline values for each factor
#   3. Generates the factorial run table
#   4. Loops over decomposition years:
#      a. Runs all counterfactual combinations (with optional warm starts)
#      b. Collects summaries into a data.table
#      c. Runs the decomposition algebra
#      d. Accumulates step scenarios and extended decomposition
#   5. Returns all outputs in a structured list
# ============================================================================

#' Run a full decomposition analysis
#'
#' This is the main user-facing function. Given a model object that implements
#' the shapleydecomp S3 interface, it performs a complete factorial decomposition
#' of the specified factors across all decomposition years.
#'
#' @param model          An S3 model object. Must have methods for
#'   \code{run_simulation()}, \code{summarize_results()},
#'   \code{build_counterfactual()}, and \code{get_baseline_value()}.
#' @param params         Model parameters (model-specific list/object).
#' @param factors        Character vector of factor names to decompose.
#' @param summary_vars   Character vector of summary variable names (columns
#'   in the output of \code{summarize_results()}).
#' @param decomp_years   Integer vector of years at which to perform
#'   decomposition (e.g., \code{2000:2023}).
#' @param method         Character, decomposition method. Only
#'   \code{"shapley"} (default) is supported. \code{"das_gupta"} is accepted
#'   as a deprecated alias: Das Gupta's symmetric standardization is the
#'   special case of the Shapley value for binary on/off factors, so the
#'   weights are identical.
#' @param cf_type        Character, counterfactual type:
#'   \code{"change_since"} (default) — counterfactual is the value at the
#'   baseline year; or \code{"total_impact"} — counterfactual is zero / no
#'   intervention.
#' @param baseline_year  Integer, the reference year for \code{"change_since"}
#'   counterfactuals. Defaults to \code{min(decomp_years)}.
#' @param decomp_scalar  Numeric, lower bound for the factor levels in the
#'   run table. Default 0 (binary on/off).
#' @param extended       Logical, whether to compute the extended factor
#'   decomposition (effects at all output years >= decomp year). Default TRUE.
#' @param step_scenarios Logical, whether to compute step scenarios (all-on
#'   time series per decomp year). Default TRUE.
#' @param verbose        Logical, print progress messages. Default TRUE.
#' @param future_policies Character, what every factor does AFTER the decomp
#'   year in each coalition run. \code{"off"} is sequential Shapley as specified
#'   (Carter, "Estimating the impact of public health policies ... with Shapley
#'   value decomposition", Algorithm 1): at step y all policies before y are at
#'   their observed values, all policies after y are at their counterfactual,
#'   and only the year-y policy varies across coalitions. The attribution at
#'   step y is then the marginal impact of the year-y policy conditional on the
#'   past and undiluted by the future, and \code{sequential_totals()} sums the
#'   steps into each factor's total impact at every year. This is the
#'   default. \code{"on"} (the behaviour before version 0.2.0, kept for
#'   reproducing old runs) leaves a factor that is "on" in a coalition at its
#'   observed values for ALL years, including after y; its same-year
#'   attribution equals \code{"off"}'s for any causal model, but its
#'   \code{extended_decomp} rows (year > decomp year) include future policies
#'   and must not be summed across steps.
#' @param group_vars     Character vector of columns in the output of
#'   \code{summarize_results()} that identify independent groups, such as
#'   locations or draws, each decomposed separately. Default none.
#' @param n_cores        Integer, number of cores for parallel counterfactual
#'   simulation runs. Default 1 (sequential). Values > 1 use
#'   \code{parallel::mclapply()}. Windows does not support forking, so there
#'   it falls back to sequential with a warning.
#' @param ...            Additional arguments passed to model methods.
#'
#' @return A list with components:
#'   \describe{
#'     \item{decomp}{data.table — standard year-by-year decomposition (one row
#'       per decomp year × measure, factor effects in columns)}
#'     \item{step_scenarios}{data.table — all-on time series per decomp year
#'       (columns: step_year, year, plus summary vars). NULL if
#'       \code{step_scenarios = FALSE}.}
#'     \item{extended_decomp}{data.table — extended decomposition (factor
#'       effects at all years >= decomp year). NULL if \code{extended = FALSE}.}
#'     \item{run_table}{data.table — the factorial design table used.}
#'     \item{params}{List of decomposition parameters used.}
#'   }
#' @seealso \code{vignette("shapleydecomp")} for a worked example, and
#'   \code{\link{validate_model_interface}} to check a model first.
#' @examples
#' # A two-factor SIR model shipped with the package
#' sir <- new.env()
#' sys.source(system.file("examples", "sir_model.R", package = "shapleydecomp"),
#'            envir = sir)
#' model  <- sir$create_sir_model(years = 1990:2010)
#' params <- sir$create_sir_params(years = 1990:2010)
#'
#' res <- shapley_decompose(
#'   model, params,
#'   factors      = c("beta_reduction", "treatment_effect"),
#'   summary_vars = c("infections", "deaths"),
#'   decomp_years = 2000:2010,
#'   cf_type      = "total_impact",
#'   verbose      = FALSE
#' )
#' res$decomp
#'
#' # Each factor's total impact at every year
#' sequential_totals(res)
#' @export
shapley_decompose <- function(model,
                              params,
                              factors,
                              summary_vars,
                              decomp_years,
                              method         = "shapley",
                              cf_type        = CF_CHANGE_SINCE,
                              baseline_year  = min(decomp_years),
                              decomp_scalar  = 0,
                              extended       = TRUE,
                              step_scenarios = TRUE,
                              verbose        = TRUE,
                              n_cores        = 1L,
                              group_vars     = character(),
                              future_policies = c("off", "on"),
                              ...) {

  # ---- Validate inputs ----
  stopifnot(is.character(factors), length(factors) > 0)
  stopifnot(is.character(summary_vars), length(summary_vars) > 0)
  stopifnot(is.numeric(decomp_years), length(decomp_years) > 0)
  stopifnot(cf_type %in% c(CF_CHANGE_SINCE, CF_TOTAL_IMPACT))
  stopifnot(is.character(group_vars))
  method <- normalize_decomp_method(method)
  future_policies <- match.arg(future_policies)

  decomp_years <- sort(as.integer(decomp_years))
  n_cores <- as.integer(max(n_cores, 1L))
  if (n_cores > 1L && .Platform$OS.type == "windows") {
    warning("n_cores > 1 uses forking, which Windows does not support; ",
            "running sequentially.", call. = FALSE)
    n_cores <- 1L
  }

  # ---- Build decomposition parameter bundle ----
  decomp_params <- list(
    decomp_vars   = factors,
    summary_vars  = summary_vars,
    decomp_method = method,
    cf_type       = cf_type,
    baseline_year = baseline_year,
    group_vars    = group_vars,
    future_policies = future_policies
  )

  # ---- Generate run table ----
  run_table <- make_run_table(factors, decomp_scalar)
  all_on_id  <- max(run_table$run_id)
  all_off_id <- min(run_table$run_id)

  if (verbose) {
    message(sprintf(
      "Decomposition: %d factors, %d combinations, %d years, method=%s, cf_type=%s, cores=%d",
      length(factors), nrow(run_table), length(decomp_years), method, cf_type, n_cores
    ))
  }

  # ---- Prepare model (one-time setup) ----
  if (verbose) message("Preparing model...")
  prep <- prepare_decomp(model, params, ...)
  model        <- prep$model
  params       <- prep$params
  full_sim     <- prep$full_sim
  full_summary <- prep$full_summary

  use_warm_start <- supports_warm_start(model, ...)

  # ---- Compute baseline values for all factors ----
  if (verbose) message("Computing baseline values...")
  baseline_values <- list()
  for (fname in factors) {
    baseline_values[[fname]] <- get_baseline_value(
      model, params, fname, cf_type, baseline_year, ...
    )
  }

  # ---- Accumulators ----
  step_list       <- list()
  ext_decomp_list <- list()

  # ---- Main decomposition loop ----
  decomp_by_year <- rbindlist(lapply(decomp_years, function(y) {
    if (verbose) message("  decomp_year: ", y)

    warm_start_year <- y - 1L
    output_years    <- seq(y, max(decomp_years))

    # Run all counterfactual combinations for this decomp year
    run_one_cf <- function(run_id) {
      run_spec <- unlist(as.list(run_table[run_id, factors, with = FALSE]))

      # All-on case: use the pre-computed full simulation. Under
      # future_policies = "off" all-on still has every policy off after y, so
      # it is not the realised run and must be simulated.
      if (all(run_spec == 1) && !is.null(full_summary) &&
          future_policies == "on") {
        return(list(summary = full_summary[year %in% output_years]))
      }

      # Build counterfactual parameters
      params_cf <- params
      if (future_policies == "off") {
        # Every factor to its counterfactual from y + 1: the future is off in
        # every coalition, so only the year-y policy varies below.
        for (fname in factors) {
          params_cf <- build_counterfactual(
            model, params_cf, fname, y + 1L, cf_type, baseline_values, ...
          )
        }
      }
      for (fname in names(run_spec[run_spec == 0])) {
        params_cf <- build_counterfactual(
          model, params_cf, fname, y, cf_type, baseline_values, ...
        )
      }

      # Run simulation (warm start or full)
      if (use_warm_start && !is.null(full_sim)) {
        sim_cf <- run_from_warm_start(
          model, full_sim, params_cf, output_years,
          warm_start_year = warm_start_year, ...
        )
      } else {
        sim_cf <- run_simulation(model, params_cf, ...)
      }

      summary_cf <- summarize_results(model, sim_cf, ...)
      if ("year" %in% names(summary_cf)) {
        summary_cf <- summary_cf[year %in% output_years]
      }

      return(list(summary = summary_cf))
    }

    if (n_cores > 1L) {
      year_sims <- parallel::mclapply(
        run_table$run_id, run_one_cf, mc.cores = n_cores
      )
    } else {
      year_sims <- lapply(run_table$run_id, run_one_cf)
    }

    # ---- Build summary table ----
    summary_dt <- rbindlist(lapply(seq_along(year_sims), function(r) {
      dt <- year_sims[[r]]$summary
      dt$run_id <- run_table$run_id[r]
      return(dt)
    }))
    summary_dt <- merge(run_table, summary_dt, by = "run_id")
    summary_dt[, decomp_year := y]

    # ---- Step scenarios ----
    if (step_scenarios) {
      sv_cols <- intersect(summary_vars, names(summary_dt))
      step_cols <- c(group_vars, "year", sv_cols)

      step_list[[as.character(y)]] <<- cbind(
        data.table(step_year = y),
        summary_dt[run_id == all_on_id, step_cols, with = FALSE]
      )

      # Also save counterfactual baseline from the first decomp year
      if (y == decomp_years[1]) {
        step_list[[as.character(decomp_years[1] - 1L)]] <<- cbind(
          data.table(step_year = decomp_years[1] - 1L),
          summary_dt[run_id == all_off_id, step_cols, with = FALSE]
        )
      }
    }

    # ---- Extended factor decomposition ----
    if (extended) {
      ext_group <- c(group_vars, "year")
      ext <- shapley_values(summary_dt[year >= y], factors,
                            intersect(summary_vars, names(summary_dt)),
                            by = ext_group)
      ext[, decomp_year := y]
      ext_decomp_list[[as.character(y)]] <<- ext
    }

    # ---- Standard decomposition at the decomp year ----
    year_decomp <- run_decomp(summary_dt[year == y], decomp_params)
    return(year_decomp)
  }))

  # ---- Assemble outputs ----
  result <- list(
    decomp          = decomp_by_year,
    step_scenarios  = if (step_scenarios) rbindlist(step_list) else NULL,
    extended_decomp = if (extended) rbindlist(ext_decomp_list) else NULL,
    run_table       = run_table,
    params          = decomp_params
  )

  if (verbose) message("Decomposition complete.")
  return(result)
}


#' Total impact per factor at every year from a sequential decomposition
#'
#' Sums the step attributions of a \code{future_policies = "off"} run across
#' decomposition steps: the total impact of factor i at year T is
#' \eqn{\sum_{y \le T} \phi_i^{(y)}(T)}, where \eqn{\phi_i^{(y)}(T)} is the
#' Shapley value at year T of the year-y policy (\code{extended_decomp}). Summed
#' over factors this telescopes to (observed) - (all policies off from the first
#' decomp year) at every T, so it is only meaningful when \code{decomp_years}
#' is contiguous.
#'
#' @param result The list returned by \code{shapley_decompose()} with
#'   \code{extended = TRUE} and \code{future_policies = "off"}.
#' @return data.table with one row per group x year x measure and one column
#'   per factor.
#' @seealso \code{\link{shapley_decompose}}, whose examples call this function.
#' @export
sequential_totals <- function(result) {
  if (!identical(result$params$future_policies, "off"))
    stop("sequential_totals() needs a shapley_decompose(future_policies = \"off\") ",
         "result: with future policies on, the steps overlap and summing them ",
         "double-counts.")
  if (is.null(result$extended_decomp))
    stop("sequential_totals() needs extended = TRUE")
  yrs <- sort(unique(result$extended_decomp$decomp_year))
  if (!identical(yrs, seq(min(yrs), max(yrs))))
    stop("sequential_totals() needs contiguous decomp_years")
  vars <- result$params$decomp_vars
  by <- c(result$params$group_vars, "year", "measure")
  result$extended_decomp[, lapply(.SD, sum), by = by, .SDcols = vars]
}
