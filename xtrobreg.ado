*! version 1.0.0  17apr2021  Ben Jann

capt findfile robreg.ado
if _rc {
    di as error "the {bf:robreg} package is required; type {stata ssc install robreg, replace}"
    error 499
}

capt findfile lmoremata.mlib
if _rc {
    di as error "the {bf:moremata} package is required; type {stata ssc install moremata, replace}"
    error 499
}

program xtrobreg, eclass
    version 11
    if replay() { // replay output
        robreg`0'
        exit
    }
    gettoken subcmd : 0, parse(", ")
    if `"`subcmd'"'=="predict" {
        gettoken subcmd 0 : 0, parse(", ")
        Predict `0'
        exit
    }
    else if `"`subcmd'"'==substr("convert", 1, max(4,strlen(`"`subcmd'"'))) {
        gettoken subcmd 0 : 0, parse(", ")
        Convert `0'
        exit
    }
    local cmdlist "ls q m s mm lms lts lqs"
    if !`:list subcmd in cmdlist' {
        di as err `"invalid subcommand: `subcmd'"'
        exit 198
    }
    local version : di "version " string(_caller()) ":"
    Check_vce `0' // returns hasvce, 00
    if "`hasvce'"!="" { // bootstrap/jackknife
        `version' _vce_parserun xtrobreg, noeqlist: `00'
        ereturn local cmdline `"xtrobreg `0'"'
        exit
    }
    Estimate `0' // returns diopts
    ereturn local cmdline `"xtrobreg `0'"'
    robreg, `diopts'
end

program Check_vce
    _parse comma lhs 0 : 0
    syntax [, vce(str) CLuster(passthru) NOSE * ]
    if `"`vce'"'=="" exit
    gettoken vcetype : vce, parse(" ,")
    if `"`vcetype'"'!= substr("bootstrap",1,max(4,strlen(`"`vcetype'"'))) ///
     & `"`vcetype'"'!= substr("jackknife",1,max(4,strlen(`"`vcetype'"'))) {
         di as err `"{bf:vce(`vce')} not allowed"'
         exit 198
    }
    if `"`cluster'"'!="" {
        di as err "option {bf:cluster()} not allowed with {bf:vce(`vcetype')}"
        di as err "specify {bf:cluster()} as suboption within {bf:vce()}"
        exit 198
    }
    c_local hasvce 1
    c_local 00 `lhs', nose vce(`vce') `options'
end

program Predict
    if `"`e(cmd)'"'!="xtrobreg" {
        di as err "last robreg results not found"
        exit 301
    }
    local subcmd `"`e(subcmd)'"'
    if !inlist(`"`subcmd'"',"ls","q","m","s","mm","lms","lts","lqs") {
        di as err "last xtrobreg results not found"
        exit 301
    }
    syntax newvarname [if] [in], [ xb ue xbu u e ]
    local opt `xb' `ue' `xbu' `u' `e'
    if "`opt'"=="" local opt xb
    if `: list sizeof opt'>1 {
        di as err "`opt': only one allowed"
        exit 198
    }
    // linear prediction
    if "`opt'"=="xb" {
        _predict `typlist' `varlist' `if' `in', xb nolabel
        qui replace `varlist' = e(_cons) + `varlist'  `if' `in'
        lab var `varlist' "Fitted values"
        exit
    }
    // ue
    if "`opt'"=="ue" {
        tempname z
        qui _predict double `z' `if' `in', xb nolabel
        gen `typlist' `varlist' = `e(depvar)' - (e(_cons) + `z') `if' `in'
        lab var `varlist' "Combined residuals"
        exit
    }
    // xbu, u, e
    tempvar xb r u esamp
    qui gen byte `esamp' = e(sample)==1
    if `"`e(wtype)'"'!="" {
        tempvar wvar
        qui gen double `wvar' `e(wexp)' if `esamp'
    }
    qui _predict double `xb' if `esamp', xb nolabel
    qui replace `xb' = e(_cons) + `xb' if `esamp'
    qui gen double `r' = `e(depvar)' - `xb' if `esamp'
    qui gen double `u' = .
    mata: xtrobreg_u()
    if "`opt'"=="xbu" {
        gen `typlist' `varlist' = `xb' + `u' `if' `in'
        lab var `varlist' "Combined predictions"
        exit
    }
    if "`opt'"=="u" {
        gen `typlist' `varlist' = `u' `if' `in'
        lab var `varlist' "Fixed effects"
        exit
    }
    if "`opt'"=="e" {
        gen `typlist' `varlist' = `r' - `u' `if' `in'
        lab var `varlist' "Residuals"
        exit
    }
end

program Convert, rclass
    syntax varlist(numeric) [if] [in] [pw] [, pd fd Wvar(name) keep(varlist) ///
        clear gmin(numlist int max=1 >=2) gmax(numlist int max=1 >=2 miss) ]
    local model `pd' `fd'
    if "`model'"=="" local model pd
    if `:list sizeof model'>1 {
        di as err "{bf:fd} and {bf:pd} not both allowed"
        exit 198
    }
    if "`wvar'"!="" {
        confirm new variable `wvar'
        local user_wvar `wvar'
        local wvar
    }
    
    // backup data
    if "`clear'"=="" {
        quietly describe
        if r(changed) error 4
    }
    preserve
    
    // panel setup
    tempname touse nvar last g_avg wvar
    Panelsetup `varlist' `if' `in' [`weight'`exp'], ///
        touse(`touse') nvar(`nvar') last(`last') g_avg(`g_avg') ///
        model(`model') wvar(`wvar') keep(`keep') gmin(`gmin') gmax(`gmax')
    
    // transform data
    local varlist: list varlist | tvar
    Transform `varlist', touse(`touse') ivar(`ivar') nvar(`nvar') ///
        last(`last') model(`model') wvar(`wvar') keep(`keep') ///
        g_min(`g_min') g_avg(`g_avg') g_max(`g_max') 
    
    // weights
    capt confirm variable `wvar', exact
    if _rc==1 exit _rc
    else if _rc==0 {
        if "`user_wvar'"=="" {
            local user_wvar _weight
            capt confirm new variable `user_wvar'
            if _rc==1 exit _rc
            else if _rc {
                di as err "variable {bf:`user_wvar'} already defined"
                di as err "cannot store weights"
                exit 110
            }
            di as txt "(weights stored as {bf:`user_wvar'})"
        }
        if "`user_wvar'"!="`wvar'" {
            rename `wvar' `user_wvar'
        }
    }
    else local user_wvar
    
    // clear xtset
    xtset, clear

    // returns
    ret local  model `model'
    ret local  ivar  `ivar'
    ret local  tvar  `tvar'
    ret local  wvar  `user_wvar'
    ret scalar N_g    = `N_g'
    ret scalar g_min  = `g_min'
    ret scalar g_avg  = `g_avg'
    ret scalar g_max  = `g_max'
    
    // everything went well; cancel restoring
    restore, not
end

program Estimate, eclass sortpreserve
    // syntax
    gettoken subcmd 0 : 0, parse(", ")
    syntax varlist(min=2 numeric) [if] [in] [pw] [, ///
        fd pd gmin(numlist int max=1 >=2) gmax(numlist int max=1 >=2 miss) ///
        CLuster(varname) NOSE Level(passthru) all noHEADer NOTABle ///
        noCONStant nor2 /// will be ignored
        nolog * ]
    _get_diopts diopts options, `options'
    _get_eformopts, eformopts(`options') soptions allowed(__all__)
    local options `"`s(options)'"'
    c_local diopts `s(eform)' `level' `all' `header' `notable' `diopts'
    local model `pd' `fd'
    if "`model'"=="" local model pd
    if `:list sizeof model'>1 {
        di as err "{bf:fd} and {bf:pd} not both allowed"
        exit 198
    }
    if inlist(`"`subcmd'"',"lts","lqs","lms") local nose nose
    
    // panel setup
    tempname touse nvar last g_avg wvar
    Panelsetup `varlist' `if' `in' [`weight'`exp'], ///
        touse(`touse') nvar(`nvar') last(`last') g_avg(`g_avg') ///
        model(`model') wvar(`wvar') gmin(`gmin') gmax(`gmax') keep(`cluster')
    _nobs `touse' [`weight'`exp']
    local N = r(N)
    
    // transform data and estimate model
    if "`log'"=="" di as txt "converting data ..." _c
    preserve
    Transform `varlist', touse(`touse') ivar(`ivar') ///
        nvar(`nvar') last(`last') model(`model') wvar(`wvar') ///
        g_min(`g_min') g_avg(`g_avg') g_max(`g_max') keep(`cluster')
    if "`log'"=="" di as txt " done"
    capt confirm variable `wvar', exact
    if _rc==1 exit _rc
    else if _rc==0 local wgt [pw=`wvar']
    if "`nose'"=="" {
        if "`cluster'"!="" local vce vce(cluster `cluster')
        else               local vce vce(cluster `ivar')
    }
    robreg `subcmd' `varlist' `wgt', noconstant nor2 noheader notable /*
         */ `log' `vce' `nose' `level' `options'
    restore
    
    // compute global intercept
    tempvar z alpha
    qui _predict double `z' if `touse', xb nolabel
    qui replace `z' = `e(depvar)' - `z' if `touse'
    mata: xtrobreg_alpha()
    
    // update returns
    ereturn repost, esample(`touse')
    if "`model'"=="fd" eret local title `"First-difference `e(title)'"'
    else               eret local title `"Pairwise-difference `e(title)'"'
    eret local cmd       "xtrobreg"
    eret local subcmd    "`subcmd'"
    eret local ivar      "`ivar'"
    eret local tvar      "`tvar'"
    eret local model     "`model'"
    eret local predict   "xtrobreg predict"
    eret local wtype     "`weight'"
    eret local wexp      `"`exp'"'
    eret scalar N        = `N'
    eret scalar N_g      = `N_g'
    eret scalar g_min    = `g_min'
    eret scalar g_avg    = `g_avg'
    eret scalar g_max    = `g_max'
    eret scalar _cons    = `alpha'
end

program Panelsetup
    syntax varlist [if] [in] [pw], touse(str) Nvar(str) Last(str) ///
        g_avg(str) model(str) [ wvar(str) keep(str) gmin(str) gmax(str) ]
    if "`gmin'"=="" local gmin 2
    if "`gmax'"=="" local gmax .
    
    // xtset
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    
    // sample, weights
    mark `touse' `if' `in' [`weight'`exp']
    markout `touse' `varlist' `ivar' `tvar' `keep'
    if "`weight'"!="" {
        qui gen double `wvar' `exp' if `touse'
    }
    
    // sort data
    sort `touse' `ivar' `tvar'
    
    // compute panel sizes
    gen byte `nvar' = 0
    qui by `touse' `ivar': replace `nvar' = _N if `touse'
    
    // update sample (need at least 2 obs per group)
    capt assert (`nvar'>=`gmin' & `nvar'<=`gmax') if `touse'
    if _rc==1 exit _rc
    else if _rc {
        qui replace `touse' = 0 if `nvar'<`gmin' | `nvar'>`gmax'
        sort `touse' `ivar' `tvar'
    }
    
    // tag last obs per panel
    by `touse' `ivar': gen byte `last' = (_n==_N) & `touse'
    
    // return panel size stats
    su `nvar' if `last' & `touse', meanonly
    scalar `g_avg' = r(mean)
    local N_g = r(N)
    local g_min = r(min)
    local g_max = r(max)
    
    // checks
    if "`model'"=="fd" & "`tvar'"=="" & `g_max'>2 {
        di as err "{bf:fd} requires time variable to be set if" ///
            " there are more then two observations per group;" ///
            " use {bf:xtset} {it:panelvar} {it:timevar}"
        exit 459
    }
    if "`weight'"!="" {
        capt by `touse' `ivar': assert (`wvar'==`wvar'[1]) if `touse'
        if _rc==1 exit _rc
        else if _rc {
            di as err `"weight must be constant within `ivar'"'
            exit 199
        }
    }
    
    // returns
    c_local ivar `ivar'
    c_local tvar `tvar'
    c_local N_g   `N_g'
    c_local g_min `g_min'
    c_local g_max `g_max'
end

program Transform
    syntax varlist, touse(str) nvar(str) last(str) ///
        ivar(str) model(str) g_min(str) g_avg(str) g_max(str) ///
        [ wvar(str) keep(str) ]
    capt confirm variable `wvar', exact
    if _rc==1      exit _rc
    else if _rc==0 local WVAR `wvar'
    
    // check keep()
    if "`keep'"!="" {
        local keep: list keep - ivar
        local keep: list keep - varlist
        local keep: list keep - WVAR
        foreach v of local keep {
            capt by `touse' `ivar': assert (`v'==`v'[1]) if `touse'
            if _rc==1 exit _rc
            else if _rc {
                di as err `"keep(): `v' not constant within `ivar'"'
                exit 199
            }
        }
    }
    
    // drop irrelevant observations and variables
    qui keep if `touse'
    keep `nvar' `last' `ivar' `WVAR' `varlist' `keep'
    
    // transform data
    recast double `varlist' // [diff might require other type]
    tempvar N
    if "`model'"=="fd" {
        gen `: type `nvar'' `N' = `nvar' - 1
        mata: xtrobreg_transform(1)
    }
    else {
        gen `: type `nvar'' `N' = `nvar'
        qui replace `N' = comb(`N',2)
        mata: xtrobreg_transform(0)
    }
    
    // pairwise: update weights by inverse of group size if panel is unbalanced
    if `g_min'!=`g_max' & "`model'"=="pd" {
        if "`WVAR'"!="" {
            qui replace `wvar' = `wvar' * (`g_avg' / `nvar')
        }
        else {
            qui gen double `wvar' = `g_avg' / `nvar'
        }
    }
end

version 11
mata:
mata set matastrict on

void xtrobreg_transform(real scalar fd)
{
    real rowvector xvars
    real colvector n
    real matrix    X
    
    // get data
    n = st_data(., st_local("nvar"), st_local("last"))
    xvars = st_varindex(tokens(st_local("varlist")))
    X = st_data(., xvars)
    
    // expand dataset
    stata("qui keep if \`last'")
    stata("drop \`last'")
    stata("qui expand \`N'")
    stata("sort \`ivar'")
    
    // generate pairwise differences
    if (fd) _transform_fd(n, X, xvars)
    else    _transform_pd(n, X, xvars)
}

void _transform_fd(real colvector n, real matrix X, real rowvector xvars)
{
    real scalar    N, I, i, j, k
    real matrix    Y
    pragma unset   Y
    
    N = rows(n)
    st_view(Y, ., xvars)
    I = k = 0
    i = 1
    for (j=1; j<=N; j++) {
        I = I + n[j]
        i++
        for (; i<=I; i++) Y[++k,] = X[i,] - X[i-1,]
    }
}

void _transform_pd(real colvector n, real matrix X, real rowvector xvars)
{
    real scalar    N, I, i, ii, j, k
    real rowvector xi
    real matrix    Y
    pragma unset   Y
    
    N = rows(n)
    st_view(Y, ., xvars)
    I = k = 0
    i = 1
    for (j=1; j<=N; j++) {
        I = I + n[j]
        for (; i<=I; i++) {
            xi = X[i,]
            for (ii=i+1; ii<=I; ii++) Y[++k,] = X[ii,] - xi
        }
    }
}

void xtrobreg_alpha()
{
    string scalar  cmd
    real scalar    alpha
    real colvector r, w
    
    r = st_data(., st_local("z"), st_local("touse"))
    if (_st_varindex(st_local("wvar"))>=.) w = 1
    else w = st_data(., st_local("wvar"), st_local("touse"))
    cmd = st_local("subcmd")
    if      (cmd=="ls") alpha = mean(r, w)
    else if (cmd=="q")  alpha = mm_quantile(r, w, st_numscalar("e(q)"))
    else                alpha = mm_median(r, w)
    st_numscalar(st_local("alpha"), alpha)
}

void xtrobreg_u()
{
    string scalar esamp, cmd
    real colvector id, r, u, w, p
    
    esamp = st_local("esamp")
    cmd   = st_local("subcmd")
    id = st_data(., st_global("e(ivar)"), esamp)
    p = order(id, 1)
    _collate(id, p)
    r = st_data(., st_local("r"), esamp)[p]
    if (st_local("wvar")!="") w = st_data(., st_local("wvar"), esamp)[p]
    else                      w = 1
    u = J(rows(id), 1, .)
    if      (cmd=="ls") u[p] = _xtrobreg_u(r, w, id, &mean())
    else if (cmd=="q")  u[p] = _xtrobreg_u(r, w, id, &mm_quantile(), st_numscalar("e(q)"))
    else                u[p] = _xtrobreg_u(r, w, id, &mm_median())
    st_store(., st_local("u"), esamp, u)
}

real colvector _xtrobreg_u(real colvector y, real colvector w, real colvector id,
    pointer(function) scalar f, | real scalar o)
{
    real scalar  i, k, n, a, b, ww, O
    real matrix  info, res

    O = (args()>4)
    if (rows(y)<1) return(J(0, 1, .))
    ww = (rows(w)!=1)
    info = _mm_panels(id)
    n = rows(info)
    res = J(rows(id), 1, .)
    b = 0
    for (i=1; i<=n; i++) {
        k = info[i]
        a = b + 1
        b = b + k
        if (O) res[|a \ b|] = J(k, 1, (*f)(y[|a \ b|], ww ? w[|a \ b|] : w, o))
        else   res[|a \ b|] = J(k, 1, (*f)(y[|a \ b|], ww ? w[|a \ b|] : w))
    }
    return(res)
}

end
