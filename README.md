# xtrobreg
Stata module providing pairwise-differences and first-differences robust regression estimators

`xtrobreg` provides robust pairwise-differences estimators and robust
first-differences estimators for panel data. In case of least-squares
regression, the pairwise-differences estimator is equivalent to the
fixed-effects estimator.

`xtrobreg` works by applying `robreg` to appropriately transformed
data (restoring the original data after estimation). Alternatively,
use `xtrobreg convert` to transform the data permanently and then apply
`robreg` manually.

Requires: Stata 11 or newer, packages `robreg` and `moremata`

---

Installation from GitHub:

    . net install xtrobreg, replace from(https://raw.githubusercontent.com/benjann/xtrobreg/main/)
    . net install robreg, replace from(https://raw.githubusercontent.com/benjann/robreg/main/)
    . net install moremata, replace from(https://raw.githubusercontent.com/benjann/moremata/master/)

---

Main changes:

    17apr2021 (version 1.0.0):
    - xtrobreg released on GitHub
