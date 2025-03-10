/* 
Statistical design, monitoring, and analysis of clinical trials: Principles and methods
Chapter 3: Effciency with Trade-Offs and Crossover Designs
*/

/**************************************************************************************************/
/* 
Example 3.3
In this example, we examine the data in Table 3.2. For this dataset, T_lambda = −1.623
with n1 + n2 − 2 = 15 df (p-value>0.10). Thus, we proceed to test for equal
direct treatment effects by T_tau = −2.162 with 15 df (p < 0.05). Furthermore, we
test the equality of the period effect π1 = π2, assuming no residual effects
lambda_1 = lamda_2 = 0, by Tπ = 1.172 with 15 df (p>0.20).
*/

/* solution 1, cell-means model */
data work.asthma;
    input Subject Sequence $ Period1 Period2;
    datalines;
1 AB 1.28 1.33
2 AB 1.6 2.21
3 AB 2.46 2.43
4 AB 1.41 1.81
5 AB 1.4 0.85
6 AB 1.12 1.2
7 AB 0.9 0.9
8 AB 2.41 2.79
9 BA 3.06 1.38
10 BA 2.68 2.1
11 BA 2.6 2.32
12 BA 1.48 1.3
13 BA 2.08 2.34
14 BA 2.72 2.48
15 BA 1.94 1.11
16 BA 3.35 3.23
17 BA 1.16 1.25
;
run;
/* a series of ttest */
data work.asthma_diff;
    set work.asthma;
    Diff12= Period1-Period2;
    if Sequence= "AB" then Diff21= Period1-Period2;
    else Diff21= Period2-Period1;
    Sum = Period1 + Period2;  
run;

/* lambda, corresponding to residual effect */
proc ttest data=work.asthma_diff;
    class Sequence;
    var Sum;
    title 't-test: Residual Effect';
run;
/* tau: treatment effect */
proc ttest data=work.asthma_diff;
    class Sequence;
    var Diff12;
    title "t-test: Treatment Effect";
run;
/* pi: period effect */
proc ttest data=work.asthma_diff;
    class Sequence;
    var Diff21;
    title 't-test: Period Effect';
run;


/* solution 2 */
data work.asthma_long;
    set work.asthma;
    Period = 1; Treatment = ifc(Sequence='AB', 'A', 'B'); FEV = Period1; output;
    Period = 2; Treatment = ifc(Sequence='AB', 'B', 'A'); FEV = Period2; output;
run;
proc print;
run;
/* PROC MIXED */
proc mixed data=work.asthma_long;
    class Subject Sequence Period Treatment;
    model FEV = Sequence Period Treatment / solution ddfm=kr;
    random Subject(Sequence);
    lsmeans Treatment / diff;
    estimate 'Treatment effect (A - B)' Treatment 1 -1;
    estimate 'Period effect (2 - 1)' Period -1 1;
    estimate 'Residual effect (AB - BA)' Sequence 1 -1;
run;

/* solution 3, not recommended */
/* 
Note that, if there is no residual effect and no
period effect, then the above model reduces to a one-way ANOVA
with a paired-data design
*/
proc anova data=work.asthma_long;
    class Subject Treatment;
    model FEV = Subject Treatment;
    means Treatment / tukey;
    title 'One-Way ANOVA with Paired-Data Design';
run;


/**************************************************************************************************/
/* 
HOMEWORK 3.2
Table 3.3 (Weight Loss Data) displays outcome data from a clinical trial on weight loss (kg) with the
test drug mCPP versus placebo using a 2 × 2 crossover design. The test
drug mCPP is denoted by D (drug) and the placebo by P.
1. First, we simply assume that there are no carryover and no
period effects. Because this is a small dataset, we prefer to carry
out the basic nonparametric sign test for equal treatment effects.
2. Second, use the cell-means model to test the hypothesis regarding the assumption of equal carryover effect, whether there is
a treatment effect, and whether there is a period effect (with
necessary assumptions) by (a) independent t-tests (available in
SAS PROC ttest) and by (b) Wilcoxon rank-sum test (available
in SAS PROC npar1way) due to the small sample size.
*/


data work.weightLoss;
    input Subject Sequence $ Period1 Period2;
    datalines;
1 AB 1.1 0
2 AB 1.3 -0.3
3 AB 1.0 0.6
4 AB 1.7 0.3
5 AB 1.4 -0.7
6 BA -0.2 0.1
7 BA 0.6 0.5
8 BA 0.9 1.6
9 BA -2.0 -0.5
;
run;
data work.weightLoss_long;
    set work.weightLoss;
    Period = 1; Treatment = ifc(Sequence='AB', 'A', 'B'); weightLoss = Period1; output;
    Period = 2; Treatment = ifc(Sequence='AB', 'B', 'A'); weightLoss = Period2; output;
run;
proc print;
run;
/* PROC MIXED */
proc mixed data=work.weightLoss_long;
    class Subject Sequence Period Treatment;
    model weightLoss = Sequence Period Treatment / solution ddfm=kr;
    random Subject(Sequence);
    lsmeans Treatment / diff;
    estimate 'Treatment effect (A - B)' Treatment 1 -1;
    estimate 'Period effect (2 - 1)' Period -1 1;
    estimate 'Residual effect (AB - BA)' Sequence 1 -1;
run;
