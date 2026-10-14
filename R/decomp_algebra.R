# ============================================================================
# shapleydecomp: decomp_algebra.R
#
# Model-agnostic Shapley value decomposition algebra.
#
# These functions operate on a summary data.table that holds simulation
# outputs for all 2^n on/off combinations of n factors. They are purely
# mathematical and have no knowledge of the underlying model.
#
# For a fixed set of factors the Shapley value is a linear map: with one
# outcome per coalition in a vector v (length 2^n), phi = t(W) %*% v, where
# W depends only on n. So every group, year and measure is decomposed with a
# single matrix product, and rows are matched to coalitions by their factor
# values rather than by position.
#
# Note: "Das Gupta" decomposition is the special case of the Shapley value for
# binary on/off factors and produces identical weights, so it is treated as an
# alias of Shapley throughout (see normalize_decomp_method()).
# ============================================================================

#' Normalize a decomposition method string to the canonical Shapley value
#'
#' Shapley is the only supported method. \code{"das_gupta"} is accepted as a
#' deprecated alias because Das Gupta's symmetric standardization is the
#' special case of the Shapley value for binary on/off factors, yielding
#' identical weights.
#'
#' @param method Character method name.
#' @return The canonical method string \code{"shapley"}.
#' @keywords internal
#' @noRd
normalize_decomp_method <- function(method) {
  if (identical(method, "das_gupta")) {
    return("shapley")
  }
  if (!identical(method, "shapley")) {
    stop(sprintf(
      paste0("Unknown decomp_method: '%s'. Use 'shapley' ",
             "(or the deprecated alias 'das_gupta')."),
      method))
  }
  "shapley"
}


#' Shapley weight matrix for n binary factors
#'
#' Row c (1-based) is the coalition whose factor i is on when bit i - 1 of
#' c - 1 is set. Entry [c, i] is +w_k if factor i is on in c and -w_k if it is
#' off, where k is the number of *other* factors on and
#' w_k = 1 / (n * choose(n - 1, k)). Then phi_i = sum_c W[c, i] * v(c).
#'
#' @param n Number of factors.
#' @return A 2^n x n numeric matrix.
#' @keywords internal
#' @noRd
shapley_weight_matrix <- function(n) {
  m <- 2^n
  bits <- outer(seq_len(m) - 1, 2^(seq_len(n) - 1), function(c, p) (c %/% p) %% 2)
  k <- rowSums(bits) - bits
  w <- 1 / (n * choose(n - 1, 0:(n - 1)))
  ifelse(bits == 1, 1, -1) * matrix(w[k + 1], m, n)
}


#' Shapley values for every group in a long table of coalition outcomes
#'
#' @param data          data.frame with one row per group x coalition.
#' @param factors       Factor columns, each 0 (counterfactual) or 1 (observed).
#' @param summary_vars  Outcome columns to decompose.
#' @param by            Columns identifying independent groups.
#' @return data.table: the \code{by} columns, \code{measure}, and one column per
#'   factor. Groups appear in order of first appearance, measures in the
#'   order of \code{summary_vars}.
#' @keywords internal
#' @noRd
shapley_values <- function(data, factors, summary_vars, by = character()) {
  data <- as.data.table(data)
  n <- length(factors)
  m <- 2^n
  missing_cols <- setdiff(c(factors, summary_vars, by), names(data))
  if (length(missing_cols) > 0) {
    stop("Columns not found: ", paste(missing_cols, collapse = ", "))
  }

  fac <- as.matrix(data[, factors, with = FALSE])
  if (!all(fac == 0 | fac == 1)) {
    stop("Factor columns must be 0 (counterfactual) or 1 (observed).")
  }
  coalition <- as.integer(drop(fac %*% 2^(seq_len(n) - 1)) + 1)

  group <- if (length(by) > 0) {
    data[, list(i = .I, g = .GRP), by = by][order(i), g]
  } else {
    rep(1L, nrow(data))
  }
  n_groups <- max(group, 0L)
  ord <- order(group, coalition)
  if (!identical(as.integer(group[ord]), rep(seq_len(n_groups), each = m)) ||
      !identical(coalition[ord], rep(seq_len(m), n_groups))) {
    stop(sprintf(paste0(
      "Each group needs exactly one row per on/off combination of the %d ",
      "factors (%d rows). Check for missing or duplicated runs, or for ",
      "grouping columns (such as a year or location) not listed in the ",
      "grouping."), n, m))
  }

  W <- shapley_weight_matrix(n)
  ids <- data[ord[seq(1L, by = m, length.out = n_groups)], by, with = FALSE]
  out <- rbindlist(lapply(seq_along(summary_vars), function(j) {
    v <- matrix(data[[summary_vars[j]]][ord], nrow = m)
    phi <- crossprod(v, W)
    colnames(phi) <- factors
    cbind(ids, measure = summary_vars[j], .g = seq_len(n_groups), .j = j,
          as.data.table(phi))
  }))
  setorderv(out, c(".g", ".j"))
  out[, c(".g", ".j") := NULL]
  out[]
}


#' Run decomposition across groups and decomp years
#'
#' Applies the Shapley decomposition to each group × decomp-year in the data.
#'
#' @param data   A \code{data.table} with one column per decomp variable (0/1
#'   indicator), one column per summary variable, and optionally a
#'   \code{decomp_year} column and the \code{group_vars} columns. Each group
#'   must have exactly one row per on/off combination; row order does not
#'   matter.
#' @param params A list with at least:
#'   \describe{
#'     \item{summary_vars}{Character vector of summary variable column names}
#'     \item{decomp_vars}{Character vector of factor column names (0/1 indicators)}
#'     \item{decomp_method}{Character, \code{"shapley"} (\code{"das_gupta"}
#'       accepted as a deprecated alias)}
#'     \item{group_vars}{Optional character vector of grouping columns,
#'       such as a location identifier}
#'   }
#'
#' @return A \code{data.table} with one row per group × decomp-year ×
#'   measure, and one column per factor giving its decomposition effect.
#' @examples
#' # Outcomes for every on/off combination of two factors, where the
#' # factors interact: y = 10 + 5a + 3b + 2ab
#' rt <- make_run_table(c("a", "b"))
#' rt[, y := 10 + 5 * a + 3 * b + 2 * a * b]
#' rt[, decomp_year := 2000L]
#' run_decomp(rt, list(summary_vars = "y", decomp_vars = c("a", "b"),
#'                     decomp_method = "shapley"))
#' @export
run_decomp <- function(data, params) {
  normalize_decomp_method(params$decomp_method)
  by <- c(params$group_vars, intersect("decomp_year", names(data)))
  shapley_values(data, params$decomp_vars,
                 intersect(params$summary_vars, names(data)), by = by)
}


#' Decompose all summary variables for a single group
#'
#' @param data   A \code{data.table} for a single group × decomp-year with
#'   one row per on/off combination of the factors, in any order.
#' @param params Parameter list (see \code{run_decomp}).
#'
#' @return A \code{data.table} with one row per summary variable: a
#'   \code{measure} column and one column per factor.
#' @examples
#' # Outcomes for every on/off combination of two factors, where the
#' # factors interact: y = 10 + 5a + 3b + 2ab
#' rt <- make_run_table(c("a", "b"))
#' rt[, y := 10 + 5 * a + 3 * b + 2 * a * b]
#' # The interaction term is split evenly: a gets 5 + 1, b gets 3 + 1
#' decomp_algebra(rt, list(summary_vars = "y", decomp_vars = c("a", "b"),
#'                         decomp_method = "shapley"))
#' @export
decomp_algebra <- function(data, params) {
  normalize_decomp_method(params$decomp_method)
  shapley_values(data, params$decomp_vars,
                 intersect(params$summary_vars, names(data)))
}


#' Decompose a single summary variable using Shapley value weights
#'
#' For each factor, computes the weighted average marginal effect of switching
#' the factor from 0 (counterfactual) to 1 (observed), averaging over all
#' combinations of the other factors.
#'
#' @param dt           A \code{data.table} with one row per on/off combination
#'   of the factors, in any order.
#' @param params       Parameter list with \code{decomp_vars} and
#'   \code{decomp_method}.
#' @param summary_var  Character, the name of the summary variable column.
#'
#' @return A one-row \code{data.table} with a \code{measure} column and one
#'   column per factor.
#' @examples
#' rt <- make_run_table(c("a", "b"))
#' rt[, y := 10 + 5 * a + 3 * b + 2 * a * b]
#' decomp_pair(rt, list(decomp_vars = c("a", "b"), decomp_method = "shapley"),
#'             "y")
#' @export
decomp_pair <- function(dt, params, summary_var) {
  normalize_decomp_method(params$decomp_method)
  shapley_values(dt, params$decomp_vars, summary_var)
}
