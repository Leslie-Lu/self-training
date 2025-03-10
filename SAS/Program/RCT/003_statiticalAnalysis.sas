/* 
Statistical design, monitoring, and analysis of clinical trials: Principles and methods
Chapter 2: Concepts and Methods of Statistical Designs
*/

/**************************************************************************************************/
/* 
HOMEWORK 2.2
1. Use the SAS® software to generate a completely randomized
allocation schedule for a trial with total sample size N = 50, two
treatment groups, and an even allocation design. Comment on
the actual sample size of each group.
Hint: Use PROC PLAN to generate a list of 50 random numbers from the uniform (0, 1) distribution. Assign Patient 1 the
frst random number, Patient 2 the second random number, etc.
If a patient’s random number is <0.5, then assign that patient to
Treatment A; otherwise, assign the patient to Treatment B.
2.  Run the computer program repeatedly 10,000 times to show that in this case
(N = 50) the probability is greater than 5% that the design will
end up as an uneven treatment allocation in the ratio of 18:32 or
more extreme.
*/

%let N = 50;
%let num_runs = 10000;

data work.allocation;
    call streaminit(123);
    do i = 1 to &N;
        rand_num = rand("Uniform");
        if rand_num < 0.5 then treatment = "A";
        else treatment = "B";
        output;
    end;
run;
proc freq data=work.allocation;
    table treatment / out=work.freq_out;
run;
proc print data=work.freq_out;
run;

/* Run the simulation 10,000 times */
data work.simulation_results;
    do run = 1 to &num_runs;
        call streaminit(123 + run);
        count_A = 0;
        count_B = 0;
        do i = 1 to &N;
            rand_num = rand("Uniform");
            if rand_num < 0.5 then count_A + 1;
            else count_B + 1;
        end;
        output;
    end;
run;
proc freq data=work.simulation_results;
    tables count_A*count_B / out=work.sim_freq_out;
run;
proc print data=work.sim_freq_out;
run;

/* Calculate the probability of uneven allocation */
data work.probability;
    set work.sim_freq_out end=eof;
    if count_A <= 18 or count_B <= 18 then extreme + count;
    else non_extreme+ count;
    if eof then do;
        extreme_prob= extreme/(extreme+non_extreme)*100;
        put "in this case (N = 50) the probability is greater than " @;
        put extreme_prob 4.2 "% that" @; 
        put "the design will end up as an uneven treatment allocation in the ratio of 18:32 or more extreme"; 
    end;
run;
proc print;
run;
/* 
for a trial with a small size or for an (early) interim analysis, 
the possibility exists that treatment groups will end
up with considerably unequal numbers of subjects.
*/

/**************************************************************************************************/
/* 
HOMEWORK 2.3
Use the SAS software to generate a blocked randomization schedule for a trial with total sample size N = 180, three treatment groups
(J = 3), and an even allocation design. Vary the block size (s ×J) by permuting s = 1, 2, 3. How many blocks will there be? Comment on the
actual sample size of each group.
*/

%let N = 180;
%let J = 3;
%let s_values = 1 2 3;

/* varying block size randomization */
data work.blocked_randomization;
    call streaminit(123);
    array s_array[3] _temporary_ (&s_values);
    do block= 1 to &N/&J while (total <= &N);
        s= s_array[rand("Integer", 1, dim(s_array))];
        block_size= s*&J;
        do i = 1 to block_size;
            rand_num = rand("Uniform");
            if rand_num < 1/&J then treatment = "A";
            else if rand_num < 2/&J then treatment = "B";
            else treatment = "C";
            output;
        end;
        total+block_size;
    end;
run;
proc print;
run;
proc freq data=work.blocked_randomization;
    table treatment / out=work.blocked_freq_out;
run;
proc print data=work.blocked_freq_out;
run;
data _null_;
    set work.blocked_freq_out;
    put "Treatment " treatment ": " count "patients";
run;
/* 
Blocked randomization is used to perform simple randomization within
blocks in order to avoid severely imbalanced allocation to treatment groups.
*/


/**************************************************************************************************/
/* 
HOMEWORK 2.4
Suppose that 32 patients will be recruited for a clinical trial comparing Treatments A and B. After completing the consent process for
these patients, they will be allocated to one of the treatments. Suppose
that age (categories 18–25, 26–39, and 40–60) and gender (M and F) are
expected to be important prognostic factors for the outcome being studied. Using the minimization approach, create a randomization schedule
using an initialization probability of 1/2 and the probability of π = 1
afterward. When G = 0, use the following uniform random numbers in
the allocation procedure (rather than generating your own):
0.26,0.69,0.11,0.51,0.22,0.56,0.23,0.98,0.11,0.43,0.53,0.98,0.29, and 0.23
Note: Setting π = 1 here is for convenience so that you need not to do any
computer programming for this problem.
The following are the ages and genders of the 32 subjects in the order
in which they were enrolled in the study:
ID Age Gender
1 26 F
2 32 F
3 18 M
4 29 F
5 35 F
6 35 M
7 38 F
8 55 M
9 56 M
10 34 F
11 22 M
12 22 F
13 23 F
14 35 F
15 34 F
16 22 F
17 34 M
18 56 F
19 59 F
20 29 M
21 45 F
22 43 F
23 33 F
24 23 M
25 49 F
26 51 F
27 23 F
28 38 F
29 34 M
30 19 F
31 39 F
32 40 M
According to the randomization schedule you created:
1. How many subjects are allocated to Treatments A and B within
each age–gender subcategory?
2. How many subjects are allocated to Treatments A and B within
each age group?
3. How many within each gender group?
4. How many overall?
*/

data work.patients;
    input ID Age Gender $;
    datalines;
1 26 F
2 32 F
3 18 M
4 29 F
5 35 F
6 35 M
7 38 F
8 55 M
9 56 M
10 34 F
11 22 M
12 22 F
13 23 F
14 35 F
15 34 F
16 22 F
17 34 M
18 56 F
19 59 F
20 29 M
21 45 F
22 43 F
23 33 F
24 23 M
25 49 F
26 51 F
27 23 F
28 38 F
29 34 M
30 19 F
31 39 F
32 40 M
;
run;
data work.count;
    set work.patients;
    if 18<=age<=25 then agegr= "18-25";
    else if 26<=age<=39 then agegr= "26-39";
    else agegr= "40-60";
run;
proc freq data=work.count noprint;
    table agegr*gender /out= work.count_freq;
run;
proc print;
run;
data work.allocation;
    call streaminit(123);
    set work.count;
    retain count_A_18_25_M 0 count_A_26_39_M 0 count_A_40_60_M 0
        count_A_18_25_F 0 count_A_26_39_F 0 count_A_40_60_F 0
        count_B_18_25_M 0 count_B_26_39_M 0 count_B_40_60_M 0
        count_B_18_25_F 0 count_B_26_39_F 0 count_B_40_60_F 0
        G_18_25_M 0 G_26_39_M 0 G_40_60_M 0
        G_18_25_F 0 G_26_39_F 0 G_40_60_F 0
        use_random_number 1;
    drop count_A_18_25_M count_A_26_39_M count_A_40_60_M
        count_A_18_25_F count_A_26_39_F count_A_40_60_F
        count_B_18_25_M count_B_26_39_M count_B_40_60_M
        count_B_18_25_F count_B_26_39_F count_B_40_60_F;
    array random_numbers(14) _TEMPORARY_ (0.26 0.69 0.11 0.51 0.22 0.56 0.23 0.98 0.11 0.43 0.53 0.98 0.29 0.23);
    array treatment_array(2) $1 _temporary_ ("A" "B");
    select (agegr);
        when ("18-25") do;
            select (gender);
                when ("M") do; 
                    if _N_=1 then treatment= treatment_array[rand("Integer", 1, dim(treatment_array))];
                    else if G_18_25_M=0 then do;
                        if random_numbers(use_random_number)< .5 then treatment= "A";
                        else treatment= "B";
                        use_random_number= mod(use_random_number, 14)+1;
                    end;
                    else if G_18_25_M>0 then treatment= "B";
                    else if G_18_25_M<0 then treatment= "A";

                    if treatment= "A" then count_A_18_25_M+1;
                    else count_B_18_25_M+1;
                    G_18_25_M= count_A_18_25_M-count_B_18_25_M;
                end;
                when ("F") do; 
                    if _N_=1 then treatment= treatment_array[rand("Integer", 1, dim(treatment_array))];
                    else if G_18_25_F=0 then do;
                        if random_numbers(use_random_number)< .5 then treatment= "A";
                        else treatment= "B";
                        use_random_number= mod(use_random_number, 14)+1;
                    end;
                    else if G_18_25_F>0 then treatment= "B";
                    else if G_18_25_F<0 then treatment= "A";

                    if treatment= "A" then count_A_18_25_F+1;
                    else count_B_18_25_F+1;
                    G_18_25_F= count_A_18_25_F-count_B_18_25_F;
                end;
                otherwise;
            end;
        end;
        when ("26-39") do;
            select (gender);
                when ("M") do; 
                    if _N_=1 then treatment= treatment_array[rand("Integer", 1, dim(treatment_array))];
                    else if G_26_39_M=0 then do;
                        if random_numbers(use_random_number)< .5 then treatment= "A";
                        else treatment= "B";
                        use_random_number= mod(use_random_number, 14)+1;
                    end;
                    else if G_26_39_M>0 then treatment= "B";
                    else if G_26_39_M<0 then treatment= "A";

                    if treatment= "A" then count_A_26_39_M+1;
                    else count_B_26_39_M+1;
                    G_26_39_M= count_A_26_39_M-count_B_26_39_M;
                end;
                when ("F") do; 
                    if _N_=1 then treatment= treatment_array[rand("Integer", 1, dim(treatment_array))];
                    else if G_26_39_F=0 then do;
                        if random_numbers(use_random_number)< .5 then treatment= "A";
                        else treatment= "B";
                        use_random_number= mod(use_random_number, 14)+1;
                    end;
                    else if G_26_39_F>0 then treatment= "B";
                    else if G_26_39_F<0 then treatment= "A";

                    if treatment= "A" then count_A_26_39_F+1;
                    else count_B_26_39_F+1;
                    G_26_39_F= count_A_26_39_F-count_B_26_39_F;
                end;
                otherwise;
            end;
        end;
        when ("40-60") do;
            select (gender);
                when ("M") do; 
                    if _N_=1 then treatment= treatment_array[rand("Integer", 1, dim(treatment_array))];
                    else if G_40_60_M=0 then do;
                        if random_numbers(use_random_number)< .5 then treatment= "A";
                        else treatment= "B";
                        use_random_number= mod(use_random_number, 14)+1;
                    end;
                    else if G_40_60_M>0 then treatment= "B";
                    else if G_40_60_M<0 then treatment= "A";

                    if treatment= "A" then count_A_40_60_M+1;
                    else count_B_40_60_M+1;
                    G_40_60_M= count_A_40_60_M-count_B_40_60_M;
                end;
                when ("F") do; 
                    if _N_=1 then treatment= treatment_array[rand("Integer", 1, dim(treatment_array))];
                    else if G_40_60_F=0 then do;
                        if random_numbers(use_random_number)< .5 then treatment= "A";
                        else treatment= "B";
                        use_random_number= mod(use_random_number, 14)+1;
                    end;
                    else if G_40_60_F>0 then treatment= "B";
                    else if G_40_60_F<0 then treatment= "A";

                    if treatment= "A" then count_A_40_60_F+1;
                    else count_B_40_60_F+1;
                    G_40_60_F= count_A_40_60_F-count_B_40_60_F;
                end;
                otherwise;
            end;
        end;
        otherwise;
    end;
run;
proc print;
run;

proc freq data=work.allocation noprint;
    table agegr*Gender*treatment / out=work.age_gender_treatment;
    table Gender*treatment / out=work.gender_treatment;
    table agegr*treatment / out=work.age_treatment;
    table treatment / out=work.overall_treatment;
run;
proc print data=work.age_gender_treatment;
run;
proc print data=work.age_treatment;
run;
proc print data=work.gender_treatment;
run;
proc print data=work.overall_treatment;
run;
/* 
When there are many prognostic factors to consider, often the need is to
balance the marginal distributions rather than the joint distribution. That is,
we desire to balance each of the factors individually and simultaneously,
when the number of combinations of factors is too large to be feasible. The
method of minimization works toward this goal.
*/


/**************************************************************************************************/
/* call streaminit */
data work.test1;
    call streaminit(123);
    do run = 1 to 5;
        rand_num = rand("Uniform");
        output;
    end;
run;
proc print;
run;
data work.test2;
    do run = 1 to 5;
        call streaminit(123 + run);
        rand_num = rand("Uniform");
        output;
    end;
run;
proc print;
run;
data work.test3;
    call streaminit(123);
    do block= 1 to 3;
        s= rand("Integer", 1, 3);
        output;
    end;
run;
proc print;
run;