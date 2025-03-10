
/* 
医学统计学
孙振球
第四版
*/

/* log-linear model for count data */
data ex17_2;
    input sex hypertension count;
    cards;
    1 1  579
    1 2  485
    2 1 1032
    2 2  483
    ;
run;

/* saturated model */
proc genmod data=ex17_2;
    class sex (ref= '2') hypertension (ref= '2') / param=ref; 
    model count = sex hypertension sex*hypertension / link=log dist = poi obstats residuals;
    estimate 'odds ratio of interaction' sex*hypertension 1 / exp;
run;
/* unsaturated model */
proc genmod data=ex17_2;
    class sex (ref= '2') hypertension (ref= '2') / param=ref; 
    model count = sex hypertension / link=log dist = poi obstats residuals; 
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    49.8430 1
    50.0463 1
    ;
run;
proc print;
run;

data ex17_3;
    input treat result count;
    cards;
    1 1 42
    1 2 18
    2 1 38
    2 2 27
    3 1 56
    3 2 19
    ;
run;
/* saturated model */
proc genmod data=ex17_3;
    class treat (ref= '3') result (ref= '2') / param=ref; 
    model  count = treat|result / link=log dist= poi obstats residuals; 
run;
/* unsaturated model */
proc genmod data=ex17_3;
    class treat (ref= '3') result (ref= '2') / param=ref; 
    model  count = treat result / link=log dist= poi obstats residuals; 
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    4.3103 2
    4.3599 2
    ;
run;
proc print;
run;
/* no interaction, therefore to check the main effect */
/* only x */
proc genmod data=ex17_3;
    class treat (ref= '3') / param=ref; 
    model  count = treat / link=log dist= poi obstats residuals; 
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    30.8214 3
    29.7149 3
    ;
run;
proc print;
run;
/* only y */
proc genmod data=ex17_3;
    class result (ref= '2') / param=ref; 
    model  count = result / link=log dist= poi obstats residuals; 
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    6.0432 4
    6.2224 4
    ;
run;
proc print;
run;

data ex17_4;
    input group drug gene count;
    cards;
    1 1 1 25
    1 1 0 84
    1 0 1 10
    1 0 0 36
    0 1 1 2
    0 1 0 63
    0 0 1 4
    0 0 0 100
    ;
run;
/* saturated model */
proc genmod data=ex17_4;
    class group (ref= '0') drug (ref= '0') gene (ref='0') / param=ref; 
    model  count = group|drug|gene / link=log dist= poi obstats residuals; 
run;
/* no second-order interaction model */
proc genmod data=ex17_4;
    class group (ref= '0') drug (ref= '0') gene (ref='0') / param=ref; 
    model  count = group|drug group|gene drug|gene / link=log dist= poi obstats residuals;
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    0.0961 1
    0.0946 1
    ;
run;
proc print;
run;
/* conditional independence model: xy, yz */
/* x= drug; y= gene; z= group; */
proc genmod data=ex17_4;
    class group (ref= '0') drug (ref= '0') gene (ref='0') / param=ref; 
    model  count = drug|gene gene|group / link=log dist= poi obstats residuals;
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    30.9197 2
    ;
run;
proc print;
run;
/* conditional independence model: xy, xz */
/* x= drug; y= gene; z= group; */
proc genmod data=ex17_4;
    class group (ref= '0') drug (ref= '0') gene (ref='0') / param=ref; 
    model  count = drug|gene drug|group / link=log dist= poi obstats residuals;
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    25.9093 2
    ;
run;
proc print;
run;
/* conditional independence model: xz, yz *
/* x= drug; y= gene; z= group; */
proc genmod data=ex17_4;
    class group (ref= '0') drug (ref= '0') gene (ref='0') / param=ref; 
    model  count = drug|group gene|group / link=log dist= poi obstats residuals;
    estimate 'xz' group*drug 1 / exp;
    estimate 'yz' group*gene 1 / exp;
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    0.0970 2
    ;
run;
proc print;
run;
/* jointly independence model: xz, y */
/* x= drug; y= gene; z= group; */
proc genmod data=ex17_4;
    class group (ref= '0') drug (ref= '0') gene (ref='0') / param=ref; 
    model  count = drug|group gene / link=log dist= poi obstats residuals;
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    28.7515 3
    ;
run;
proc print;
run;
/* jointly independence model: x, yz */
/* x= drug; y= gene; z= group; */
proc genmod data=ex17_4;
    class group (ref= '0') drug (ref= '0') gene (ref='0') / param=ref; 
    model  count = drug gene|group / link=log dist= poi obstats residuals;
run;
data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    33.7619 3
    ;
run;
proc print;
run;


data chi_test_for_goodness_of_fit;
    input chi2 df;
    p= 1-probchi(chi2,df);
    cards;
    0.0006 2
    ;
run;
proc print;
run;





