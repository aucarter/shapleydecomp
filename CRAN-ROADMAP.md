# CRAN submission roadmap

Status as of 2026-10-13, from `R CMD check --as-cran` on R 4.4.2.

|  | Before (`decomposer` 0.2.0) | Now (`shapleydecomp` 0.3.0) |
|----|----|----|
| ERROR | 1: package name conflicts with `DecomposeR` | 0 |
| WARNING | 1: all 17 exports undocumented, no `man/` | 0 from the package (`qpdf` missing on the cluster host only) |
| NOTE | 3: non-standard top-level dirs, undeclared globals, `getS3method` not imported | 1: “new submission”, plus site URLs until the site is deployed |
| Examples / tests / vignettes | none / OK / none | OK / OK / OK |

## 1. Blockers

### 1.1 Package name: resolved

CRAN compares package names case-insensitively, and `DecomposeR` is
already on CRAN, so `decomposer` / `decomposeR` would have been refused.
The package is now **`shapleydecomp`**, in the GitHub repo
`aucarter/shapleydecomp`, and the main entry point is
**[`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)**,
which no longer masks
[`stats::decompose()`](https://rdrr.io/r/stats/decompose.html). The
incoming-feasibility name check now passes.

Callers outside this repo still use the old name. They keep working
because they load the installed `decomposer 0.2.0` build, and each needs
moving when it next takes an update: - `leapfrog_adulthiv`:
`r_libs.lock` pins `decomposer 0.2.0`, and `R/decomp_structural.R` calls
`decomposer::`. Install a `shapleydecomp` build with `install_pinned()`,
bump the lockfile, and replace `decomposer::` and `decompose(` in the
same commit. - `hiv_decomp/R/adapters/*.R`:
`decomposer::CF_TOTAL_IMPACT` and the related constants. -
`manuscript/main.tex`: `\pkg{decomposer}` throughout.

### 1.2 Deploy the site so its URLs resolve: in progress

`DESCRIPTION`, the README and the package help page link to
`https://aucarter.github.io/decomposeR/`. CRAN checks every URL, and
these return 404 until the `pkgdown` workflow has run once. After the
first run, enable Pages in the repo settings with source branch
`gh-pages`, folder `/`.

## 2. Done on the `pkgdown-site` branch

- Roxygen generates `man/` and `NAMESPACE`. All 17 exports are
  documented, the four `.default` methods are registered with
  `S3method()`, and `data.table` /
  [`utils::getS3method`](https://rdrr.io/r/utils/getS3method.html) are
  imported explicitly.
- Every exported function has runnable examples. The SIR model moved to
  `inst/examples/sir_model.R` so that examples, the vignette and users
  can all source it.
- Two vignettes: *Get started* (an end-to-end SIR walkthrough) and
  *Methods* (Shapley weights, the Das Gupta equivalence, counterfactual
  types, sequential Shapley).
- Tests register their toy methods with
  [`.S3method()`](https://rdrr.io/r/base/S3method.html) instead of
  writing to `.GlobalEnv` with `<<-`. CRAN policy forbids modifying the
  user’s workspace.
- [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md)
  reports progress with
  [`message()`](https://rdrr.io/r/base/message.html) instead of
  [`cat()`](https://rdrr.io/r/base/cat.html), so `verbose = FALSE` and
  [`suppressMessages()`](https://rdrr.io/r/base/message.html) both
  silence it.
- [`make_run_table()`](https://aucarter.github.io/shapleydecomp/reference/make_run_table.md)
  now prints when called at top level. It used to return directly after
  a `:=`, so its first auto-print was suppressed.
- `DESCRIPTION` gains `URL`, `BugReports`, `Depends: R (>= 4.0.0)` (for
  `.S3method`), the `parallel` / `utils` imports and `VignetteBuilder`.
- `.Rbuildignore` keeps `manuscript/`, `.github/`, `_pkgdown.yml` and
  `scratch/` out of the tarball.
- CI: `R-CMD-check.yaml` (macOS, Windows, and Ubuntu on devel / release
  / oldrel) and `pkgdown.yaml`.

## 3. Should fix before submitting

CRAN reviewers read these, and they cost an extra round of review if
they come back.

| Item | Where | Why | Size |
|----|----|----|----|
| Hard-coded `ihme_loc_id` grouping | [`run_decomp()`](https://aucarter.github.io/shapleydecomp/reference/run_decomp.md), [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md), [`sequential_totals()`](https://aucarter.github.io/shapleydecomp/reference/sequential_totals.md) | A generic package should not recognise one institution’s column name. Replace it with a `by` argument whose default reproduces today’s behaviour. | S |
| Internal reference in the docs | [`shapley_decompose()`](https://aucarter.github.io/shapleydecomp/reference/shapley_decompose.md) `@param future_policies` | Mentions `hiv_decomp run_simmod_mean.R`, which no outside reader can see. Cite the manuscript instead. | S |
| Maintainer email | `DESCRIPTION` | CRAN mails the maintainer about every check failure for the life of the package, and an address that bounces leads to archival. Choose an address you will keep. | S |
| References in `Description` | `DESCRIPTION` | CRAN asks for method references in the form `Authors (year) <doi:...>`: Shapley (1953) <doi:10.1515/9781400881970-018>, Das Gupta (1993), and the manuscript once it has a DOI. Also add `inst/CITATION`. | S |
| Stale comment | `R/run_table.R` header | Says “3^n rows if decomp_scalar = 0”; the code produces 2^n binary rows. | S |
| Title and description wording | `DESCRIPTION` | Quote software names in single quotes (`'data.table'`) and avoid starting with “A …”. These are routine first-review comments. | S |
| Spelling and URL pass |  | Run `spelling::spell_check_package()` and `urlchecker::url_check()`. | S |

## 4. Submission steps

1.  Confirm the site deploys and the CI matrix is green.
2.  Move the callers listed in 1.1 when convenient. CRAN does not need
    this.
3.  Work through section 3.
4.  Bump the version (suggest `1.0.0`, given the API commitment) and
    update `NEWS.md`.
5.  Run the external checks: `devtools::check_win_devel()`,
    `devtools::check_mac_release()`, and `rhub::rhub_check()` for the
    additional platforms. Results come back by email.
6.  Update `cran-comments.md` with the check results and the “new
    submission” note.
7.  Run `devtools::submit_cran()`, then confirm the submission from the
    link CRAN emails to the maintainer.
8.  Expect one round of reviewer comments for a first submission
    (usually 1–3 weeks). Address them, bump the patch version, and
    resubmit.

Rough effort: about half a day (M) for section 3 and the submission,
plus calendar time for CRAN’s review.

## 5. After acceptance

- CRAN re-checks the package against every R-devel release. A failure
  comes with a deadline (typically 2–4 weeks) to fix it before the
  package is archived.
- Every update goes through the same incoming checks, so batch changes
  into releases rather than pushing small ones.
- Keep `main` installable from GitHub for the internal pipeline, and cut
  CRAN releases from tags.
