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
#' @param extended       Logical, whether to compute the extended factor
#'   decomposition (effects at all output years >= decomp year). Default TRUE.
#' @param step_scenarios Logical, whether to compute step scenarios (all-on
#'   time series per decomp year). Default TRUE.
#' @param verbose        Logical, print progress messages. Default TRUE.
#' @param group_vars     Character vector of columns in the output of
#'   \code{summarize_results()} that identify independent groups, such as
#'   locations or draws, each decomposed separately. Default none.
#' @param n_cores        Integer, number of cores for parallel counterfactual
#'   simulation runs. Default 1 (sequential). Values > 1 run every
#'   counterfactual simulation, across all decomp years, in one
#'   \code{parallel::mclapply()} map, so that more cores than the 2^n runs of
#'   a single year can be used. Windows does not support forking, so there
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
#'     \item{run_summary}{data.table — per decomp year: the number of
#'       coalition runs, how many were simulated, how many were reused from
#'       the previous step, and the factors that were null players (their
#'       counterfactual left the params unchanged, so their effect is 0).}
#'     \item{params}{List of decomposition parameters used.}
#'   }
#' @details
#' The decomposition is sequential (Carter 2025, \emph{Quantifying averted
#' burden from infectious disease control policies}, PhD dissertation,
#' University of Washington, \url{https://hdl.handle.net/1773/53310}). At
#' each decomp year y, every policy before y is at its observed value, every
#' policy after y is at its counterfactual, and only the year-y policy varies
#' across the 2^n coalitions. The attribution at step y is therefore the
#' marginal impact of the year-y policy, conditional on the past and undiluted
#' by the future. \code{extended_decomp} records that impact at every later
#' year, and \code{sequential_totals()} sums the steps into each factor's
#' total impact at every year.
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
                              extended       = TRUE,
                              step_scenarios = TRUE,
                              verbose        = TRUE,
                              n_cores        = 1L,
                              group_vars     = character(),
                              ...) {

  # ---- Validate inputs ----
  stopifnot(is.character(factors), length(factors) > 0)
  stopifnot(is.character(summary_vars), length(summary_vars) > 0)
  stopifnot(is.numeric(decomp_years), length(decomp_years) > 0)
  stopifnot(cf_type %in% c(CF_CHANGE_SINCE, CF_TOTAL_IMPACT))
  stopifnot(is.character(group_vars))
  method <- normalize_decomp_method(method)

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
    group_vars    = group_vars
  )

  # ---- Generate run table ----
  run_table <- make_run_table(factors)
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

  use_warm_start <- supports_warm_start(model, ...)

  # ---- Compute baseline values for all factors ----
  if (verbose) message("Computing baseline values...")
  baseline_values <- list()
  for (fname in factors) {
    baseline_values[[fname]] <- get_baseline_value(
      model, params, fname, cf_type, baseline_year, ...
    )
  }

  # ---- Plan every coalition run ----
  # All |decomp_years| x 2^n runs depend only on the observed params, so they
  # are mapped in one pass (one parallel map when n_cores > 1). Two kinds of
  # run are not simulated:
  #   * The all-off run at step y (counterfactual from y) is the same scenario
  #     as the all-on run at step y - 1, so it is copied from that run.
  #   * A factor whose counterfactual leaves the step's params unchanged (e.g. a
  #     programme that has not started yet) is a null player at that step:
  #     switching it on or off gives the same run. Coalitions that differ only
  #     in null factors are grouped and simulated once. Each worker confirms
  #     with identical() that a grouped coalition's params really are the same
  #     before reusing a run, and simulates it otherwise.

  # Params with every factor at its counterfactual from y + 1: identical for
  # every coalition at step y.
  make_future_off <- function(y) {
    p <- params
    for (fname in factors) {
      p <- build_counterfactual(
        model, p, fname, y + 1L, cf_type, baseline_values, ...
      )
    }
    p
  }
  # Each process builds the step base once per year
  base_cache <- new.env()
  cached_base <- function(y) {
    if (!identical(base_cache$year, y)) {
      base_cache$year   <- y
      base_cache$params <- make_future_off(y)
    }
    base_cache$params
  }

  null_by_year <- lapply(decomp_years, function(y) {
    base <- cached_base(y)
    factors[vapply(factors, function(fname) {
      identical(build_counterfactual(model, base, fname, y, cf_type,
                                     baseline_values, ...), base)
    }, logical(1))]
  })
  names(null_by_year) <- decomp_years

  bits <- as.matrix(run_table[, factors, with = FALSE])
  code_of <- function(b) drop(b %*% 2^(seq_along(factors) - 1)) + 1
  run_of_code <- run_table$run_id[order(code_of(bits))]

  tasks <- rbindlist(lapply(decomp_years, function(y) {
    b <- bits
    b[, factors %in% null_by_year[[as.character(y)]]] <- 1
    data.table(decomp_year = y, run_id = run_table$run_id,
               canonical = run_of_code[code_of(b)])
  }))
  tasks[, how := "simulate"]
  tasks[run_id == all_off_id & (decomp_year - 1L) %in% decomp_years,
        how := "previous_all_on"]
  groups <- unique(tasks[how == "simulate", list(decomp_year, canonical)])
  members <- split(tasks[how == "simulate"],
                   by = c("decomp_year", "canonical"), keep.by = FALSE)

  run_group <- function(g) {
    y   <- groups$decomp_year[g]
    can <- groups$canonical[g]
    ids <- members[[paste(y, can, sep = ".")]]$run_id
    ids <- c(can, setdiff(ids, can))
    output_years <- seq(y, max(decomp_years))

    # Runs already done in this group: params and summary
    done <- list()
    out <- vector("list", length(ids))
    n_sim <- 0L
    for (j in seq_along(ids)) {
      off <- factors[bits[match(ids[j], run_table$run_id), ] == 0]
      params_cf <- cached_base(y)
      for (fname in off) {
        params_cf <- build_counterfactual(
          model, params_cf, fname, y, cf_type, baseline_values, ...
        )
      }
      hit <- Position(function(d) identical(d$params, params_cf), done)
      if (is.na(hit)) {
        if (use_warm_start && !is.null(full_sim)) {
          sim_cf <- run_from_warm_start(
            model, full_sim, params_cf, output_years,
            warm_start_year = y - 1L, ...
          )
        } else {
          sim_cf <- run_simulation(model, params_cf, ...)
        }
        summary_cf <- as.data.table(summarize_results(model, sim_cf, ...))
        done[[length(done) + 1L]] <- list(
          params = params_cf, summary = summary_cf[year %in% output_years]
        )
        hit <- length(done)
        n_sim <- n_sim + 1L
      }
      out[[j]] <- done[[hit]]$summary
    }
    list(run_id = ids, summary = out, n_sim = n_sim)
  }

  if (verbose) {
    message(sprintf(
      "Planned %d runs: %d to simulate at most, %d reused across steps, %d grouped with a null factor...",
      nrow(tasks), nrow(groups), sum(tasks$how == "previous_all_on"),
      sum(tasks$how == "simulate") - nrow(groups)))
  }

  if (n_cores > 1L) {
    sims <- parallel::mclapply(seq_len(nrow(groups)), run_group,
                               mc.cores = n_cores)
  } else {
    sims <- lapply(seq_len(nrow(groups)), run_group)
  }
  failed <- which(vapply(sims, inherits, logical(1), what = "try-error"))
  if (length(failed) > 0) {
    stop(sprintf("Simulation failed for decomp_year %d, run_id %d: %s",
                 groups$decomp_year[failed[1]], groups$canonical[failed[1]],
                 conditionMessage(attr(sims[[failed[1]]], "condition"))),
         call. = FALSE)
  }
  lookup <- new.env()
  for (g in seq_along(sims)) {
    for (j in seq_along(sims[[g]]$run_id)) {
      assign(paste(groups$decomp_year[g], sims[[g]]$run_id[j]),
             sims[[g]]$summary[[j]], envir = lookup)
    }
  }
  get_sim <- function(y, rid) get(paste(y, rid), envir = lookup)

  run_summary <- tasks[, list(runs = .N,
                           reused_across_steps = sum(how == "previous_all_on")),
                       by = decomp_year]
  run_summary[, simulated := vapply(decomp_year, function(y) {
    sum(vapply(sims[groups$decomp_year == y], `[[`, integer(1), "n_sim"))
  }, integer(1))]
  run_summary[, null_factors := vapply(as.character(decomp_year), function(y) {
    paste(null_by_year[[y]], collapse = ", ")
  }, character(1))]

  # ---- Decompose each step ----
  steps <- lapply(decomp_years, function(y) {
    if (verbose) message("  decomp_year: ", y)
    output_years <- seq(y, max(decomp_years))

    year_tasks <- tasks[decomp_year == y]
    summary_dt <- rbindlist(lapply(seq_len(nrow(year_tasks)), function(r) {
      rid <- year_tasks$run_id[r]
      s <- switch(year_tasks$how[r],
        simulate        = get_sim(y, rid),
        previous_all_on = get_sim(y - 1L, all_on_id)[year %in% output_years]
      )
      cbind(run_id = rid, s)
    }))
    summary_dt <- merge(run_table, summary_dt, by = "run_id")
    summary_dt[, decomp_year := y]
    sv_cols <- intersect(summary_vars, names(summary_dt))

    out <- list(decomp = run_decomp(summary_dt[year == y], decomp_params))

    if (step_scenarios) {
      step_cols <- c(group_vars, "year", sv_cols)
      out$step <- cbind(
        data.table(step_year = y),
        summary_dt[run_id == all_on_id, step_cols, with = FALSE]
      )
      # The counterfactual baseline: all factors off from the first decomp year
      if (y == decomp_years[1]) {
        out$step <- rbind(
          cbind(data.table(step_year = y - 1L),
                summary_dt[run_id == all_off_id, step_cols, with = FALSE]),
          out$step
        )
      }
    }

    if (extended) {
      out$ext <- shapley_values(summary_dt[year >= y], factors, sv_cols,
                                by = c(group_vars, "year"))
      out$ext[, decomp_year := y]
    }
    out
  })

  collect <- function(part) rbindlist(lapply(steps, `[[`, part))

  # ---- Assemble outputs ----
  result <- list(
    decomp          = collect("decomp"),
    step_scenarios  = if (step_scenarios) collect("step") else NULL,
    extended_decomp = if (extended) collect("ext") else NULL,
    run_table       = run_table,
    run_summary     = run_summary,
    params          = decomp_params
  )

  if (verbose) message("Decomposition complete.")
  return(result)
}


#' Total impact per factor at every year from a sequential decomposition
#'
#' Sums the step attributions of a \code{shapley_decompose()} run across
#' decomposition steps: the total impact of factor i at year T is
#' \eqn{\sum_{y \le T} \phi_i^{(y)}(T)}, where \eqn{\phi_i^{(y)}(T)} is the
#' Shapley value at year T of the year-y policy (\code{extended_decomp}). Summed
#' over factors this telescopes to (observed) - (all policies off from the first
#' decomp year) at every T, so it is only meaningful when \code{decomp_years}
#' is contiguous.
#'
#' @param result The list returned by \code{shapley_decompose()} with
#'   \code{extended = TRUE}.
#' @return data.table with one row per group x year x measure and one column
#'   per factor.
#' @seealso \code{\link{shapley_decompose}}, whose examples call this function.
#' @export
sequential_totals <- function(result) {
  if (is.null(result$extended_decomp))
    stop("sequential_totals() needs extended = TRUE")
  yrs <- sort(unique(result$extended_decomp$decomp_year))
  if (!identical(yrs, seq(min(yrs), max(yrs))))
    stop("sequential_totals() needs contiguous decomp_years")
  vars <- result$params$decomp_vars
  by <- c(result$params$group_vars, "year", "measure")
  result$extended_decomp[, lapply(.SD, sum), by = by, .SDcols = vars]
}
