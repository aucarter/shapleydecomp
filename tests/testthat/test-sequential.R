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


# ---------------------------------------------------------------------------
#  Null factors: runs grouped when a factor's counterfactual changes nothing
# ---------------------------------------------------------------------------

late_years <- 1995:2015
create_late_params <- function() {
  # c only starts in 2008, so it is a null player before then
  list(a = setNames(seq(0.1, 0.6, length.out = length(late_years)), late_years),
       b = setNames(seq(0.3, 0.1, length.out = length(late_years)), late_years),
       c = setNames(ifelse(late_years >= 2008, 0.2, 0), late_years),
       years = late_years)
}
run_simulation.late_model <- function(model, params, ...) {
  s <- 0; out <- numeric(length(params$years))
  for (t in seq_along(params$years)) {
    a <- params$a[t]; b <- params$b[t]; c <- params$c[t]
    s <- 0.7 * s + a + b + c + a * c
    out[t] <- 100 * exp(-s)
  }
  data.table(year = params$years, burden = out)
}
build_counterfactual.late_model <- function(model, params, factor_name,
                                            decomp_year, cf_type,
                                            baseline_values, ...) {
  params[[factor_name]][params$years >= decomp_year] <- 0
  if (isTRUE(model$no_dedupe)) params$calls <- c(params$calls, factor_name)
  params
}
.S3method("run_simulation", "late_model", run_simulation.late_model)
.S3method("summarize_results", "late_model", function(model, sim_output, ...) sim_output)
.S3method("get_baseline_value", "late_model", function(model, params, factor_name,
          cf_type, baseline_year, ...) list(type = "zero"))
.S3method("build_counterfactual", "late_model", build_counterfactual.late_model)

run_late <- function(no_dedupe, future = "off") {
  shapley_decompose(structure(list(no_dedupe = no_dedupe), class = "late_model"),
                    create_late_params(), factors = c("a", "b", "c"),
                    summary_vars = "burden", decomp_years = 2000:2015,
                    cf_type = CF_TOTAL_IMPACT, future_policies = future,
                    verbose = FALSE)
}

test_that("null factors are detected, simulated once, and get zero effect", {
  res <- run_late(no_dedupe = FALSE)
  rs <- res$run_summary
  expect_equal(rs[decomp_year < 2008, unique(null_factors)], "c")
  expect_true(all(rs[decomp_year >= 2008, null_factors] == ""))
  expect_true(all(rs[decomp_year < 2008, simulated] < rs[decomp_year < 2008, runs]))
  expect_equal(res$decomp[decomp_year < 2008, c], rep(0, 8))
})

test_that("grouping null factors gives the same answer as simulating every run", {
  for (future in c("off", "on")) {
    grouped <- run_late(no_dedupe = FALSE, future = future)
    full    <- run_late(no_dedupe = TRUE,  future = future)
    # Under "on" a factor that starts later is not null: switching it off
    # also removes its future values. Only "off" groups runs here.
    if (future == "off") {
      expect_true(sum(full$run_summary$simulated) > sum(grouped$run_summary$simulated))
    }
    expect_equal(grouped$decomp, full$decomp)
    expect_equal(grouped$extended_decomp, full$extended_decomp)
    expect_equal(grouped$step_scenarios, full$step_scenarios)
  }
})

test_that("a factor that is null on the base but not in a coalition is simulated", {
  # c's counterfactual depends on a: with a on, c is left alone (null on the
  # base); with a off, c is zeroed. Grouping must notice and simulate.
  .S3method("build_counterfactual", "coupled_model", function(model, params, factor_name,
            decomp_year, cf_type, baseline_values, ...) {
    idx <- params$years >= decomp_year
    if (factor_name != "c" || all(params$a[idx] == 0)) params[[factor_name]][idx] <- 0
    if (isTRUE(model$no_dedupe)) params$calls <- c(params$calls, factor_name)
    params
  })
  p <- create_late_params(); p$c[] <- 0.2
  run <- function(nd) shapley_decompose(
    structure(list(no_dedupe = nd), class = c("coupled_model", "late_model")),
    p, factors = c("a", "b", "c"), summary_vars = "burden",
    decomp_years = 2000:2006, cf_type = CF_TOTAL_IMPACT, verbose = FALSE)
  grouped <- run(FALSE); full <- run(TRUE)
  expect_true(all(grouped$run_summary$null_factors == "c"))
  expect_equal(grouped$decomp, full$decomp)
  expect_equal(grouped$extended_decomp, full$extended_decomp)
})
