# ============================================================================
# shapleydecomp: run_table.R
#
# Generate the factorial design table for decomposition. Each row is one
# combination of n factors, each 0 (counterfactual) or 1 (observed): 2^n rows.
# ============================================================================

#' Generate the factorial run table for decomposition
#'
#' Creates a \code{data.table} with one row per counterfactual combination.
#' Each factor column contains 0 (counterfactual) or 1 (observed), encoding
#' whether that factor is "on" or "off" for that run.
#'
#' @param factors  Character vector of factor names.
#'
#' @return A \code{data.table} with 2^n rows: \code{run_id} (integer), and one
#'   column per factor with values 0 or 1.
#' @examples
#' make_run_table(c("treatment", "prevention", "demography"))
#' @export
make_run_table <- function(factors) {
  run_table <- data.table::data.table(
    expand.grid(replicate(length(factors), list(0L:1L)))
  )
  names(run_table) <- factors
  run_table[, run_id := .I]
  data.table::setcolorder(
    run_table, c(ncol(run_table), seq_len(ncol(run_table) - 1))
  )
  run_table[]
}
