# ============================================================================
# tests/testthat/test-decomp-algebra.R
#
# Unit tests for the decomposition algebra (model-agnostic).
# ============================================================================

library(testthat)
library(data.table)

test_that("make_run_table generates correct factorial design", {
  rt <- make_run_table(c("a", "b"), decomp_scalar = 0)
  expect_equal(nrow(rt), 4)  # 2^2
  expect_true("run_id" %in% names(rt))
  expect_true(all(c("a", "b") %in% names(rt)))
  expect_equal(rt$run_id, 1:4)

  rt3 <- make_run_table(c("x", "y", "z"), decomp_scalar = 0)
  expect_equal(nrow(rt3), 8)  # 2^3
})


test_that("decomp_pair correctly decomposes a simple additive example", {
  # Simple additive case: outcome = 10*A + 20*B
  # A=0,B=0 -> 0; A=1,B=0 -> 10; A=0,B=1 -> 20; A=1,B=1 -> 30
  dt <- data.table(
    A = c(0, 1, 0, 1),
    B = c(0, 0, 1, 1),
    outcome = c(0, 10, 20, 30)
  )
  params <- list(
    decomp_vars = c("A", "B"),
    decomp_method = "shapley",
    summary_vars = "outcome"
  )

  result <- decomp_pair(dt, params, "outcome")
  expect_equal(result$A, 10, tolerance = 1e-10)
  expect_equal(result$B, 20, tolerance = 1e-10)
  expect_equal(result$measure, "outcome")
})


test_that("'das_gupta' is accepted as a deprecated alias for Shapley", {
  # Das Gupta's symmetric standardization is the binary special case of the
  # Shapley value, so the alias must produce identical effects.
  set.seed(42)
  rt <- make_run_table(c("f1", "f2", "f3"))
  dt <- copy(rt)
  dt[, outcome := 100 + 30 * f1 + 50 * f2 + 20 * f3 + 10 * f1 * f2 + 5 * f2 * f3]

  alias  <- decomp_algebra(dt, list(decomp_vars = c("f1", "f2", "f3"),
                                    decomp_method = "das_gupta",
                                    summary_vars = "outcome"))
  canon  <- decomp_algebra(dt, list(decomp_vars = c("f1", "f2", "f3"),
                                    decomp_method = "shapley",
                                    summary_vars = "outcome"))
  expect_equal(alias, canon, tolerance = 1e-10)

  total_diff <- dt[f1 == 1 & f2 == 1 & f3 == 1, outcome] -
                dt[f1 == 0 & f2 == 0 & f3 == 0, outcome]
  sum_effects <- alias$f1 + alias$f2 + alias$f3
  expect_equal(sum_effects, total_diff, tolerance = 1e-10)
})


test_that("decomposition effects sum to total difference (Shapley)", {
  rt <- make_run_table(c("f1", "f2", "f3"))
  dt <- copy(rt)
  dt[, outcome := 100 + 30 * f1 + 50 * f2 + 20 * f3 + 10 * f1 * f2 + 5 * f2 * f3]

  params <- list(
    decomp_vars = c("f1", "f2", "f3"),
    decomp_method = "shapley",
    summary_vars = "outcome"
  )

  result <- decomp_algebra(dt, params)

  total_diff <- dt[f1 == 1 & f2 == 1 & f3 == 1, outcome] -
                dt[f1 == 0 & f2 == 0 & f3 == 0, outcome]
  sum_effects <- result$f1 + result$f2 + result$f3
  expect_equal(sum_effects, total_diff, tolerance = 1e-10)
})


test_that("run_decomp handles grouped data", {
  dt <- data.table(
    location = rep(c("AAA", "BBB"), each = 4),
    decomp_year = rep(2020, 8),
    A = rep(c(0, 1, 0, 1), 2),
    B = rep(c(0, 0, 1, 1), 2),
    outcome = c(0, 10, 20, 30, 100, 110, 120, 130)
  )
  params <- list(
    decomp_vars = c("A", "B"),
    decomp_method = "shapley",
    summary_vars = "outcome",
    group_vars = "location"
  )

  result <- run_decomp(dt, params)
  expect_equal(nrow(result), 2)  # one per location
  expect_true(all(result$A == 10))
  expect_true(all(result$B == 20))
})


test_that("unknown decomp method raises error", {
  dt <- data.table(A = c(0, 1), outcome = c(10, 20))
  params <- list(
    decomp_vars = "A",
    decomp_method = "unknown",
    summary_vars = "outcome"
  )
  expect_error(decomp_pair(dt, params, "outcome"), "Unknown decomp_method")
})


# ---------------------------------------------------------------------------
#  Shapley values against the textbook definition
# ---------------------------------------------------------------------------

# phi_i = sum over S not containing i of |S|! (n-|S|-1)! / n! * (v(S+i) - v(S))
shapley_by_definition <- function(v, factors) {
  n <- length(factors)
  rt <- make_run_table(factors)
  key <- function(on) paste(as.integer(factors %in% on), collapse = "")
  val <- setNames(v, apply(as.matrix(rt[, factors, with = FALSE]), 1, paste, collapse = ""))
  vapply(factors, function(f) {
    others <- setdiff(factors, f)
    subsets <- unlist(lapply(0:length(others), function(k) combn(others, k, simplify = FALSE)),
                      recursive = FALSE)
    sum(vapply(subsets, function(S) {
      k <- length(S)
      factorial(k) * factorial(n - k - 1) / factorial(n) *
        (val[[key(c(S, f))]] - val[[key(S)]])
    }, numeric(1)))
  }, numeric(1))
}

test_that("decomp_algebra matches the Shapley definition with interactions", {
  set.seed(1)
  f <- paste0("f", 1:4)
  rt <- make_run_table(f)
  rt[, y := 10 + 3 * f1 - 2 * f2 * f3 + 5 * f1 * f2 * f4 + rnorm(.N)]
  p <- list(decomp_vars = f, decomp_method = "shapley", summary_vars = "y")
  res <- decomp_algebra(rt, p)
  expect_equal(unlist(res[, f, with = FALSE]), shapley_by_definition(rt$y, f),
               tolerance = 1e-12)
})

test_that("row order does not change the decomposition", {
  set.seed(2)
  f <- c("a", "b", "c")
  rt <- make_run_table(f)
  rt[, y := 10 + 5 * a + 3 * b + 2 * a * c - 4 * b * c]
  p <- list(decomp_vars = f, decomp_method = "shapley", summary_vars = "y")
  expect_equal(decomp_algebra(rt[sample(.N)], p), decomp_algebra(rt, p))
  expect_equal(decomp_pair(rt[sample(.N)], p, "y"), decomp_pair(rt, p, "y"))
})

test_that("run_decomp handles several groups and measures in any order", {
  set.seed(3)
  f <- c("a", "b")
  rt <- make_run_table(f)
  dt <- rbindlist(lapply(c("X", "Y", "Z"), function(loc) {
    cbind(location = loc, decomp_year = 2001L, rt)
  }))
  dt[, y1 := rnorm(.N)][, y2 := rnorm(.N)]
  p <- list(decomp_vars = f, decomp_method = "shapley",
            summary_vars = c("y1", "y2"), group_vars = "location")
  res <- run_decomp(dt[sample(.N)], p)
  expect_equal(nrow(res), 6)
  for (loc in c("X", "Y", "Z")) for (v in c("y1", "y2")) {
    expect_equal(unlist(res[location == loc & measure == v, f, with = FALSE]),
                 shapley_by_definition(dt[location == loc][order(run_id)][[v]], f),
                 tolerance = 1e-12)
  }
})

test_that("incomplete or ungrouped input is an error, not a wrong answer", {
  rt <- make_run_table(c("a", "b"))
  rt[, y := 1:4]
  p <- list(decomp_vars = c("a", "b"), decomp_method = "shapley", summary_vars = "y")
  expect_error(decomp_algebra(rt[-2], p), "exactly one row per on/off")
  expect_error(decomp_algebra(rbind(rt, rt), p), "exactly one row per on/off")
  bad <- copy(rt)[, a := a * 2]
  expect_error(decomp_algebra(bad, p), "must be 0")
})
