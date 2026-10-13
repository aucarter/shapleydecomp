# ============================================================================
# tests/testthat/test-sequential.R
#
# Sequential Shapley (future_policies = "off") on a model WITH memory: each
# year's policies add to a decaying protective stock, and the two factors
# interact, so the year-y policy's effect persists into later years and depends
# on the other factor. A memoryless model cannot tell the algorithms apart.
# ============================================================================

library(testthat)
library(data.table)

mem_years <- 2000:2010

create_mem_params <- function() {
  list(a = setNames(seq(0.1, 0.6, length.out = length(mem_years)), mem_years),
       b = setNames(seq(0.3, 0.1, length.out = length(mem_years)), mem_years),
       years = mem_years)
}

# stock_t = 0.7 * stock_{t-1} + a_t + b_t + a_t * b_t ; burden_t = 100 * exp(-stock_t)
run_simulation.mem_model <- function(model, params, ...) {
  s <- 0; out <- numeric(length(params$years))
  for (t in seq_along(params$years)) {
    a <- params$a[t]; b <- params$b[t]
    s <- 0.7 * s + a + b + a * b
    out[t] <- 100 * exp(-s)
  }
  data.table(year = params$years, burden = out)
}
summarize_results.mem_model <- function(model, sim_output, ...) sim_output
get_baseline_value.mem_model <- function(model, params, factor_name, cf_type,
                                         baseline_year, ...) list(type = "zero")
build_counterfactual.mem_model <- function(model, params, factor_name,
                                           decomp_year, cf_type,
                                           baseline_values, ...) {
  params[[factor_name]][params$years >= decomp_year] <- 0
  params
}
for (g in c("run_simulation", "summarize_results", "get_baseline_value",
            "build_counterfactual")) {
  .S3method(g, "mem_model", get(paste0(g, ".mem_model")))
}

run_mem <- function(future) {
  m <- structure(list(), class = "mem_model")
  shapley_decompose(m, create_mem_params(), factors = c("a", "b"),
            summary_vars = "burden", decomp_years = mem_years,
            cf_type = CF_TOTAL_IMPACT, future_policies = future,
            step_scenarios = TRUE, verbose = FALSE)
}

test_that("sequential totals telescope to observed minus all-off at every year", {
  res <- run_mem("off")
  tot <- sequential_totals(res)
  m <- structure(list(), class = "mem_model")
  p <- create_mem_params()
  obs <- run_simulation(m, p)$burden
  p0 <- p; p0$a[] <- 0; p0$b[] <- 0
  off <- run_simulation(m, p0)$burden
  expect_equal(tot$a + tot$b, obs - off, tolerance = 1e-12)
})

test_that("same-year attribution matches between modes (causal model)", {
  on <- run_mem("on")$decomp; off <- run_mem("off")$decomp
  expect_equal(on$a, off$a, tolerance = 1e-12)
  expect_equal(on$b, off$b, tolerance = 1e-12)
})

test_that("later-year step effects differ: 'on' includes future policies", {
  on  <- run_mem("on")$extended_decomp
  off <- run_mem("off")$extended_decomp
  k <- on$decomp_year == 2000 & on$year == 2010
  expect_false(isTRUE(all.equal(on$a[k], off$a[off$decomp_year == 2000 & off$year == 2010])))
})

test_that("the year-y policy's effect decays after y when the future is off", {
  ext <- run_mem("off")$extended_decomp[decomp_year == 2003]
  # burden is reduced by policies, so attributions are negative; the 2003
  # policy's impact must shrink in magnitude as its stock contribution decays
  expect_true(all(diff(abs(ext$a + ext$b)) < 0))
})

test_that("step scenarios climb from all-off to observed when the future is off", {
  st <- run_mem("off")$step_scenarios
  m <- structure(list(), class = "mem_model")
  obs <- run_simulation(m, create_mem_params())
  last <- st[step_year == max(mem_years)]
  expect_equal(last$burden, obs[year == max(mem_years), burden], tolerance = 1e-12)
  s2005 <- st[step_year == 2005]
  expect_equal(s2005[year == 2005, burden], obs[year == 2005, burden], tolerance = 1e-12)
  expect_gt(s2005[year == 2010, burden], obs[year == 2010, burden])
})

test_that("sequential_totals refuses a future-on result", {
  expect_error(sequential_totals(run_mem("on")), "double-counts")
})
