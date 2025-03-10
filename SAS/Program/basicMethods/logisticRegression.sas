
/* 
医学统计学
孙振球
第四版
*/

proc logistic data =eff_adbl;
    class SQFL ( ref="N") PTFL(ref="N") ECOGBL (ref="0") LCLINES (ref=">2") wt(ref=">=60") sex (ref="F") / param = ref;
    model avalc (event='Y') = SQFL PTFL ECOGBL LCLINES wt sex age;
run;

/* example 16.1 */
data ex16_1;
    input y x1 x2 freq @@;
    cards;
    1 0 0 63
    0 0 0 136
    1 0 1 63
    0 0 1 107
    1 1 0 44
    0 1 0 57
    1 1 1 265
    0 1 1 151
    ;
run;
proc logistic data=ex16_1;
    freq freq;
    model y(event='1') = x1 x2;
run;

data ex16_2;
    input x1-x8 y @@;
    cards;
    3 1 0 1 0 0 1 1 0
    2 0 1 1 0 0 1 0 0
    2 1 0 1 0 0 1 0 0
    2 0 0 1 0 0 1 0 0
    3 0 0 1 0 1 1 1 0
    3 0 1 1 0 0 2 1 0
    2 0 1 0 0 0 1 0 0
    3 0 1 1 1 0 1 0 0
    2 0 0 0 0 0 1 1 0
    1 0 0 1 0 0 1 0 0
    1 0 1 0 0 0 1 1 0
    1 0 0 0 0 0 2 1 0
    2 0 0 0 0 0 1 0 0
    4 1 0 1 0 0 1 0 0
    3 0 1 1 0 0 1 1 0
    1 0 0 1 0 0 3 1 0
    2 0 0 1 0 0 1 0 0
    1 0 0 1 0 0 1 1 0
    3 1 1 1 1 0 1 0 0
    2 1 1 1 1 0 2 0 0
    3 1 0 1 0 0 1 0 0
    2 1 1 0 1 0 3 1 0
    2 0 0 1 1 0 1 1 0
    2 0 0 0 0 0 1 0 0
    2 0 1 0 0 0 1 0 0
    2 0 0 1 1 0 1 1 0
    2 0 0 0 0 0 1 0 0
    2 0 0 0 0 0 2 1 0
    2 1 1 1 0 1 2 1 1
    3 0 0 1 1 1 2 1 1
    2 0 0 1 1 1 1 0 1
    3 1 1 1 1 1 3 1 1
    2 0 0 1 0 0 1 1 1
    2 0 1 0 1 1 1 1 1
    2 0 0 1 0 1 1 0 1
    2 1 1 1 1 0 1 1 1
    3 1 1 1 1 0 1 1 1
    3 1 1 1 0 1 1 1 1
    3 1 1 1 1 0 1 1 1
    3 0 1 0 0 0 1 0 1
    2 1 1 1 1 0 2 1 1
    3 1 0 1 0 1 2 1 1
    3 1 0 1 0 0 1 1 1
    3 1 1 1 1 1 2 0 1
    4 0 0 1 1 0 3 1 1
    3 1 1 1 1 0 3 1 1
    4 1 1 1 1 0 3 0 1
    3 0 1 1 1 0 1 1 1
    4 0 0 1 0 0 2 1 1
    1 0 1 1 1 0 2 1 1
    2 0 1 1 0 1 2 1 1
    2 1 1 1 0 0 2 1 1
    2 1 0 1 0 0 1 1 1
    3 1 1 0 1 0 3 1 1
    ;
run;
/* stepwise selection method */
proc logistic data=ex16_2;
    model y(event='1') = x1-x8 / selection= stepwise sle= 0.1 sls= 0.15 stb;
run;
/* backward selection method */
proc logistic data=ex16_2;
    model y(event='1') = x1-x8 / selection= backward slstay= 0.15 stb;
run;

/* conditional logistic regression */
data ex16_3;
    input index y x1-x6 @@;
    cards;
    1 1 3 5 1 1 1 0
    1 0 1 1 1 3 3 0
    1 0 1 1 1 3 3 0
    2 1 1 3 1 1 3 0
    2 0 1 1 1 3 2 0
    2 0 1 2 1 3 2 0
    3 1 1 4 1 3 2 0
    3 0 1 5 1 3 2 0
    3 0 1 4 1 3 2 0
    4 1 1 4 1 2 1 1
    4 0 1 1 1 3 3 0
    4 0 2 1 1 3 2 0
    5 1 2 4 2 3 2 0
    5 0 1 2 1 3 3 0
    5 0 2 3 1 3 2 0
    6 1 1 3 1 3 2 1
    6 0 1 2 1 3 2 0
    6 0 1 3 2 3 3 0
    7 1 2 1 1 3 2 1
    7 0 1 1 1 3 3 0
    7 0 1 1 1 3 3 0
    8 1 1 2 3 2 2 0
    8 0 1 5 1 3 2 0
    8 0 1 2 1 3 1 0
    9 1 3 4 3 3 2 0
    9 0 1 1 1 3 3 0
    9 0 1 4 1 3 1 0
    10 1 1 4 1 3 3 1
    10 0 1 4 1 3 3 0
    10 0 1 2 1 3 1 0
    11 1 3 4 1 3 2 0
    11 0 3 4 1 3 1 0
    11 0 1 5 1 3 1 0
    12 1 1 4 3 3 3 0
    12 0 1 5 1 3 2 0
    12 0 1 5 1 3 3 0
    13 1 1 4 1 3 2 0
    13 0 1 1 1 3 1 0
    13 0 1 1 1 3 2 0
    14 1 1 3 1 3 2 1
    14 0 1 1 1 3 1 0
    14 0 1 2 1 3 3 0
    15 1 1 4 1 3 2 0
    15 0 1 5 1 3 3 0
    15 0 1 5 1 3 3 0
    16 1 1 4 2 3 1 0
    16 0 2 1 1 3 3 0
    16 0 1 1 3 3 2 0
    17 1 2 3 1 3 2 0
    17 0 1 1 2 3 2 0
    17 0 1 2 1 3 2 0
    18 1 1 4 1 3 2 0
    18 0 1 1 1 2 1 0
    18 0 1 2 1 3 2 0
    19 1 1 3 2 2 2 0
    19 0 1 1 1 2 1 0
    19 0 2 2 2 3 1 0
    20 1 1 4 2 3 2 1
    20 0 1 5 1 3 3 0
    20 0 1 4 1 3 2 0
    21 1 1 5 1 2 1 0
    21 0 1 4 1 3 2 0
    21 0 1 2 1 3 2 1
    22 1 1 2 2 3 1 0
    22 0 1 2 1 3 2 0
    22 0 1 1 1 3 3 0
    23 1 1 3 1 2 2 0
    23 0 1 1 1 3 1 1
    23 0 1 1 2 3 2 1
    24 1 1 2 2 3 2 1
    24 0 1 1 1 3 2 0
    24 0 1 1 2 3 2 0
    25 1 1 4 1 1 1 1
    25 0 1 1 1 3 2 0
    25 0 1 1 1 3 3 0
    ;
run;
proc logistic data=ex16_3;
    model y(event='1') = x1-x6 / selection= stepwise sle= 0.1 sls= 0.15;
    strata index;
run;

/* ordinal logistic regression */
data ex16_4;
    input x1 x2 y freq;
    cards;
    0 1 0 5
    0 1 1 2
    0 1 2 7
    0 0 0 1
    0 0 1 0
    0 0 2 10
    1 1 0 16
    1 1 1 5
    1 1 2 6
    1 0 0 6
    1 0 1 7
    1 0 2 19
    ;
run;
proc logistic data=ex16_4;
    freq freq;
    model y (desc) = x1 x2 / link= cumlogit /*cloglog*/; /*used cloglog to test parallel lines assumption*/
run;
/* note the direction of ORs */
proc logistic data=ex16_4;
    freq freq;
    model y = x1 x2 / link= cumlogit /*cloglog*/; /*used cloglog to test parallel lines assumption*/
run;

/* multinomial logistic regression */
data ex16_5;
    input x1 x2 y freq;
    cards;
    0 0 1 20
    0 0 2 35
    0 0 3 26
    0 1 1 10
    0 1 2 27
    0 1 3 57
    1 0 1 42
    1 0 2 17
    1 0 3 26
    1 1 1 16
    1 1 2 12
    1 1 3 26
    ;
run;
proc logistic data=ex16_5;
    freq freq;
    model y (order= data) = x1 x2 / link= glogit;
run;



/* SAS\materials\Document\PharmaSUG-2024-ST-113.pdf */
/* Calculating statistics for each dependent variable in our logistic model */
%macro uni (variable=, pe=, or=, rp=, total=, ref=);
ODS OUTPUT ParameterEstimates =&pe OddsRatios =&or Responseprofile=&rp nobs=&total;
proc logistic data = eff_adbl;
class &variable (ref=&REF) / param = ref;
model avalc(event='Y') = &variable ;
run;
ODS OUTPUT CLOSE;

/*'regression coefficient', 'standard error' and 'p-value' */
data &pe;
    set &pe;
    where variable ne "INTERCEPT";
    regcoef= put(round(estimate, 0.001),6.3);
    pvalue = put(probchisq, 6.3);
    stderrn = put(stderr, 6.3);
    keep variable /*classval0*/ regcoef stderrn pvalue ;
run;
/*Odds Ratio and 95% CI */
data &or;
    set &or;
    drop effect;
    lowerci = put(lowercl, 6.3);
    upperci = put(uppercl, 6.3);
    oddsratio= put(oddsratioest, 6.3);
    drop lowercl uppercl;
run;

/*total no of events*/
data &rp;
    set &rp;
    where outcome="Y";
    keep count;
run;
data &total;
    set &total;
    where label ='Number of Observations Used';
    keep n;
run;
%mend;

%uni (variable=SQFL, pe=pe_SQFL, or=or_SQFL , rp=rp_SQFL, total=t_SQFL, ref="N");
%uni (variable=ECOGBL, pe=pe_ECOGBL, or=or_ECOGBL , rp=rp_ECOGBL, total=t_ECOGBL, ref="0");
%uni (variable=wt, pe=pe_wt, or=or_wt , rp=rp_wt, total=t_wt, ref=">=60");