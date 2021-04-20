{smcl}
{* 20apr2021}{...}
{hi:help xtrobreg}{...}
{right:{browse "http://github.com/benjann/xtrobreg/"}}
{hline}
{p 0 0 2}

{title:Title}

{pstd}{hi:xtrobreg} {hline 2} Pairwise-differences and first-differences robust regression


{marker syntax}{...}
{title:Syntax}

{pstd}
    Estimation

{p 8 15 2}
    {cmd:xtrobreg} {it:subcmd} {depvar} {indepvars} {ifin} {weight}
    [{cmd:,} {help xtrobreg##opts:{it:options}} ]

{pmore}
    where {it:subcmd} is any of the subcommands supported by {helpb robreg##syntax:robreg}.

{pstd}
    Replaying results

{p 8 15 2}
    {cmd:xtrobreg} [{cmd:,} {help robreg##repopts:{it:reporting_options}} ]

{pstd}
    Prediction

{p 8 15 2}
    {cmd:predict} [{help datatypes:{it:type}}]
        {newvar} {ifin}
        [{cmd:,} {it:{help xtrobreg##propts:predict_options}} ]

{pstd}
    Convert data

{p 8 15 2}
    {cmd:xtrobreg} {opt conv:ert} {depvar} [{indepvars}] {ifin} {weight}
    [{cmd:,} {it:{help xtrobreg##tropts:convert_options}} ]


{synoptset 21}{...}
{marker opts}{col 5}{it:{help xtrobreg##options:options}}{col 28}description
{synoptline}
{synopt :{opt fd}}use first differences rather than pairwise differences
    {p_end}
{synopt :{opt gmin(#)}}required minimum number of observations per group
    {p_end}
{synopt :{opt gmax(#)}}allowed maximum number of observations per group
    {p_end}
{synopt :{opt cl:uster(clustvar)}}specify custom cluster variable
    {p_end}
{synopt:{cmd:vce(}{it:vcetype}{cmd:)}}use bootstrap or jackknife for
    variance estimation
    {p_end}
{synopt :{help robreg##opts:{it:robreg_options}}}any other options allowed by
    {helpb robreg}
    {p_end}
{synoptline}
{pstd}
    A panel variable (and, depending on options, a time variable) must be set; use {helpb xtset}.
    {p_end}
{pstd}
    {cmd:pweight}s are allowed; see {help weight}. Weights must be constant within
    groups.


{marker propts}{col 5}{help xtrobreg##predict_options:{it:predict_options}}{col 28}description
{synoptline}
{synopt:{opt xb}}a + xb, fitted values; the default
    {p_end}
{synopt:{opt ue}}u_i + e_it, the combined residual
    {p_end}
{synopt:{opt xbu}}a + xb + u_i, prediction including fixed effect
    {p_end}
{synopt:{opt u}}u_i, the fixed effect
    {p_end}
{synopt:{opt e}}e_it, the idiosyncratic error
    {p_end}
{synoptline}

{marker tropts}{col 5}{help xtrobreg##conv_options:{it:convert_options}}{col 28}description
{synoptline}
{synopt :{opt fd}}generate first differences rather than pairwise differences
    {p_end}
{synopt :{opt gmin(#)}}required minimum number of observations per group
    {p_end}
{synopt :{opt gmax(#)}}allowed maximum number of observations per group
    {p_end}
{synopt :{opth w:var(newvarname)}}custom name for weights variable
    {p_end}
{synopt :{opth keep(varlist)}}additional variables to be kept in the data
    {p_end}
{synopt :{opt clear}}overwrite current data in memory
    {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
    {cmd:xtrobreg} provides robust pairwise-differences estimators and robust
    first-differences estimators for panel data. In case of least-squares
    regression, the pairwise-differences estimator is equivalent to the
    fixed-effects estimator. See Aquaro and Cizek (2010) for a discussion of
    robust estimation based on pairwise differences.

{pstd}
    {cmd:xtrobreg} works by applying {helpb robreg} to appropriately transformed
    data. {cmd:xtrobreg} restores the original data after estimation. Alternatively,
    use {cmd:xtrobreg convert} to transform the data permanently and then apply
    {cmd:robreg} manually.

{pstd}
    {cmd:xtrobreg} requires {cmd:robreg} and {cmd:moremata}. See
    {net "describe robreg, from(http://fmwww.bc.edu/repec/bocode/r/)":ssc describe robreg}
    and
    {net "describe moremata, from(http://fmwww.bc.edu/repec/bocode/m/)":ssc describe moremata}.


{marker options}{...}
{title:Options}

{dlgtab:xtrobreg}

{phang}
    {opt fd} requests that the first-differences estimator be
    computed. The default is to compute the pairwise-differences estimator. For
    least-squares regression, the pairwise-differences estimator is equal to the
    fixed-effects estimator. Option {cmd:fd} requires a time variable to be set
    if there are groups with more than two observations.

{pmore}
    In any case, the data from which the differences are computed will be
    restricted to (non-missing) observations satisfying the {cmd:if} and {cmd:in} qualifiers, and
    differences will be taken irrespective of whether there are gaps in the
    time line. This means that option {cmd:fd} is different from how 
    time-series operators work in Stata. If you are interested in a
    first-differences estimate that treats the data in a way that is consistent
    with time-series operators, you can used {helpb robreg} with time-series
    operator {cmd:D.} (see {help tsvarlist}).

{phang}
    {opt gmin(#)}, with #>=2, specifies the required minimum number of
    observations per group. The default is {cmd:gmin(2)}. Groups with less than
    # observations will be excluded from the estimation sample.

{phang}
    {opt gmax(#)}, with #>=2, specifies the allowed maximum number of
    observations per group. The default is to impose no limit. Groups with more
    than # observations will be excluded from the estimation sample.

{phang}
    {opt cluster(clustvar)} specifies a custom cluster variable for influence-function based
    standard errors. The default is to cluster on panel groups.

{phang}
    {cmd:vce(}{it:vcetype}{cmd:)} may be used to request replication-based variance
    estimation; see {cmd:bootstrap} and {cmd:jackknife} in
    {it:{help vce_option}}. You may want to specify the
    {cmd:cluster()}, {cmd:idcluster()}, and {cmd:group()} suboptions. The default is to report
    cluster-robust standard errors based on influence functions.

{phang}
    {it:robreg_options} are any other options allowed by
    {helpb robreg}.

{marker predict_options}{...}
{dlgtab:predict}

{phang}
    {opt xb} generates fitted values (a + xb). This is the default. The overall
    constant, a, is computed as the mean ({cmd:xtrobreg ls}), quantile ({cmd:xtrobreg q}),
    or median (all other estimators) of y - xb.

{phang}
    {opt ue} generates combined residuals (u_i + e_it).

{phang}
    {opt xbu} generates predictions including fixed effects (a + xb + u_i).

{phang}
    {opt u} generates the fixed effects (u_i). The fixed effects are computed as
    group-specific means ({cmd:xtrobreg ls}), quantiles
    ({cmd:xtrobreg q}), or medians (all other estimators) of y - (a + xb).

{phang}
    {opt e} generates the idiosyncratic errors (e_it).

{marker conv_options}{...}
{dlgtab:convert}

{phang}
    {opt fd} generates first differences. The default is to generate pairwise
    differences.

{phang}
    {opt gmin(#)}, with #>=2, specifies the required minimum number of
    observations per group. The default is {cmd:gmin(2)}. Groups with less than
    # observations will be excluded from the converted data.

{phang}
    {opt gmax(#)}, with #>=2, specifies the allowed maximum number of
    observations per group. The default is to impose no limit. Groups with more
    than # observations will be excluded from the converted data.

{phang}
    {opth wvar(newvarname)} specifies a custom name for the weights variable. The default
    is to use {cmd:_weight}.

{phang}
    {opth keep(varlist)} specifies additional variables to be kept in the converted
    data. These variables must be constant within groups.

{phang}
    {opt clear} specifies that the data may be converted even though the dataset
    has changed since it was last saved on disk.


{marker examples}{...}
{title:Examples}

        . {stata webuse xtdatasmpl, clear}
        . {stata xtreg ln_w age* ttl_exp* tenure* not_smsa south, fe cluster(idcode)}
        . {stata xtrobreg ls ln_w age* ttl_exp* tenure* not_smsa south}
        . {stata xtrobreg mm ln_w age* ttl_exp* tenure* not_smsa south}

{pstd}
    Using manually transformed data:

        . {stata webuse xtdatasmpl, clear}
        . {stata xtrobreg convert ln_w age* ttl_exp* tenure* not_smsa south, wvar(wt)}
        . {stata robreg ls ln_w age* ttl_exp* tenure* not_smsa south [pw=wt], noconstant cluster(idcode)}
        . {stata robreg s ln_w age* ttl_exp* tenure* not_smsa south [pw=wt], noconstant cluster(idcode)}
        . {stata robreg mm, efficiency(75)}
        . {stata robreg mm, efficiency(85)}


{marker results}{...}
{title:Stored results}

{pstd}
    In addition to the results from {helpb robreg}, {cmd:xtrobreg} saves the following
    results in {cmd:e()}.

{synoptset 16 tabbed}{...}
{pstd}Scalars{p_end}
{synopt:{cmd:e(N_g)}}number of groups{p_end}
{synopt:{cmd:e(g_min)}}minimum number of observations per group{p_end}
{synopt:{cmd:e(g_avg)}}average number of observations per group{p_end}
{synopt:{cmd:e(g_max)}}maximum number of observations per group{p_end}
{synopt:{cmd:e(_cons)}}value of overall constant{p_end}

{pstd}Macros{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtrobreg}{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtrobreg predict}{p_end}
{synopt:{cmd:e(ivar)}}name of panel variable{p_end}
{synopt:{cmd:e(tvar)}}name of time variable (if set){p_end}
{synopt:{cmd:e(model)}}{cmd:pd} or {cmd:fd}{p_end}

{pstd}
    {cmd:xtrobreg convert} saves the following results in {cmd:r()}.

{synoptset 16 tabbed}{...}
{pstd}Scalars{p_end}
{synopt:{cmd:r(N_g)}}number of groups{p_end}
{synopt:{cmd:r(g_min)}}minimum number of observations per group{p_end}
{synopt:{cmd:r(g_avg)}}average number of observations per group{p_end}
{synopt:{cmd:r(g_max)}}maximum number of observations per group{p_end}

{pstd}Macros{p_end}
{synopt:{cmd:r(ivar)}}name of panel variable{p_end}
{synopt:{cmd:e(tvar)}}name of (differenced) time variable (if set){p_end}
{synopt:{cmd:r(wvar)}}name of weights variable{p_end}
{synopt:{cmd:e(model)}}{cmd:pd} or {cmd:fd}{p_end}


{marker refrerences}{...}
{title:References}

{phang}
    Aquaro, M., P. Cizek (2010). One-Step Robust Estimation of Fixed-Effects
    Panel Data Models. CentER Discussion Paper No. 2010-110. Tilburg
    University. {browse "https://research.tilburguniversity.edu/en/publications/one-step-robust-estimation-of-fixed-effects-panel-data-models":[link]}
    {p_end}


{marker author}{...}
{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@soz.unibe.ch
    {p_end}
{pstd}
    Vincenzo Verardi, University of Namur and Universite libre de Bruxelles

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B., V. Verardi (2021). xtrobreg: Stata module providing pairwise-differences and
    first-differences robust regression estimators. Available from
    {browse "http://github.com/benjann/xtrobreg/"}.


{marker alsosee}{...}
{title:Also see}

{psee}
    {helpb xtreg},
    {helpb xtset},
    {helpb robreg}
    {p_end}
