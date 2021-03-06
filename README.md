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

To install `xtrobreg` from the SSC Archive, type

    . ssc install xtrobreg, replace
    . ssc install robreg, replace
    . ssc install moremata, replace

in Stata.

---

Installation from GitHub:

    . net install xtrobreg, replace from(https://raw.githubusercontent.com/benjann/xtrobreg/main/)
    . net install robreg, replace from(https://raw.githubusercontent.com/benjann/robreg/main/)
    . net install moremata, replace from(https://raw.githubusercontent.com/benjann/moremata/master/)

---

Main changes:

    29aug2021 (version 1.0.5):
    - options t0() and t1() added to -xtrobreg convert-
    - now using stable sort order when transforming data
    
    22apr2021 (version 1.0.4):
    - -xtrobreg convert- now additionally supports iweights
    - -xtrobreg convert- now always stores a weights variable, even if all weights
      are equal to 1
    
    21apr2021 (version 1.0.3)
    - factor variables are now allowed (although not with -xtrobreg convert-)
    - handling of cluster() option improved; cluster() now also allowed with
      -xtrobreg convert- (undocumented)
    - weights and variables from keep() no longer required to be constant if option
      -fd- is specified
    - option -fd- now always requires a time variable to be set
    
    20apr2021 (version 1.0.2)
    - option -fd(strict)- removed
    
    19apr2021 (version 1.0.1):
    - option -fd(strict)- added
    
    17apr2021 (version 1.0.0):
    - xtrobreg released on GitHub
