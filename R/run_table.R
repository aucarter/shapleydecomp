# ============================================================================
# shapleydecomp: run_table.R
#
# Generate the factorial design table for decomposition. Each row is one
# counterfactual combination. Factor levels run over decomp_scalar:1, so the
# default decomp_scalar = 0 gives 2^n binary on/off rows for n factors.
# ============================================================================

#' Generate the factorial run table for decomposition
#'
#' Creates a \code{data.table} with one row per counterfactual combination.
#' Each factor column contains 0 (counterfactual) or 1 (observed), encoding
#' whether that factor is "on" or "off" for that run.
#'
#' @param factors        Character vector of factor names.
#' @param decomp_scalar  Numeric, the lower bound of the factor scale.
#'   Default is 0 (binary: 0 = off, 1 = on).
#'
#' @return A \code{data.table} with columns: \code{run_id} (integer), and one
#'   column per factor with values in \code{decomp_scalar:1}.
#' @examples
#' make_run_table(c("treatment", "prevention", "demography"))
#' @export
make_run_table <- function(factors, decomp_scalar = 0) {
  run_table <- data.table::data.table(
    expand.grid(
      replicate(length(factors), list(decomp_scalar:1))
    )
  )
  names(run_table) <- factors
  run_table[, run_id := .I]
  data.table::setcolorder(
    run_table, c(ncol(run_table), seq_len(ncol(run_table) - 1))
  )
  run_table[]
}
