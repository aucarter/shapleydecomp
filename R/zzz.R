# ============================================================================
# shapleydecomp: zzz.R
#
# Package-level documentation and imports
# ============================================================================

#' @keywords internal
#' @import data.table
#' @importFrom utils getS3method
"_PACKAGE"

# data.table non-standard evaluation columns
utils::globalVariables(c("decomp_year", "run_id", "year", "i", "g"))
