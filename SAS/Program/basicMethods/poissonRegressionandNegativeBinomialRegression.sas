
/* 
医学统计学
孙振球
第四版
*/

/* poisson regression */
data ex18_1;
    input x1-x4 y pys @@; /* pys is person-years */
    ln= log(pys); /*the log of person-years is used as an offset variable, that is, a regression variable with a coefficient fixed at 1 for each observation*/
    cards;
    0 0 0 0 14 38336.7
    0 0 0 1 7 11026.1
    1 0 0 0 38 31019.1
    1 0 0 1 42 10792.1
    0 1 0 0 58 17495.5
    0 1 0 1 59 6897.9
    0 0 1 0 41 6842.4
    0 0 1 1 17 2580.9
    ;
run;
ods output parameterestimates=pe;
/* https://support.sas.com/kb/24/188.html */
proc genmod data=ex18_1;
    class x1 (ref= '0') x2 (ref= '0') x3 (ref= '0') x4 (ref= '0') / param= glm;
    model y = x1 x2 x3 x4 / dist=poisson link=log offset=ln scale=deviance;
    estimate 'incidence rate ratio' x4 1 / exp;
    /* equals to */
    lsmeans x4 / ilink diff exp cl;
    estimate 'x3' x3 1 / exp;
    estimate 'x2' x2 1 / exp;
    estimate 'x1' x1 1 / exp;
    lsmeans x4 / ilink cl;
    estimate "Incidence Rate: baseline" intercept 1 x1 0 1 x2 0 1 x3 0 1 x4 0 1 /exp;
    estimate "Incidence Rate: x4=1" intercept 1 x1 0 1 x2 0 1 x3 0 1 x4 1 0 /exp;
run;
ods output close;



/* negative binomial regression */
data ex18_2;
    input y place freq @@;
    place2= (place= 2);
    place3= (place= 3);
    cards;
    0 1 136 0 2 38 0 3 67
    1 1 23 1 2 8 1 3 5
    2 1 10 2 2 2 2 3 0
    3 1 5 3 2 0 3 3 0
    4 1 2 4 2 0 4 3 0
    5 1 1 5 2 0 5 3 0
    6 1 1 6 2 0 6 3 0
    11 1 1 11 2 0 11 3 0
    ;
run;
/* using poisson regression */
proc genmod data=ex18_2;
    freq freq;
    model y = place2 place3 / dist=poisson link=log /*scale=deviance*/;
run;
/* using Lagrange multiplier statistics to test over-dispersion */
proc genmod data=ex18_2;
    freq freq;
    model y = place2 place3 / dist=negbin link=log lrci noscale;
run;
/* using negative binomial regression to model over-dispersion */
proc genmod data=ex18_2;
    freq freq;
    class place2 (ref='0') place3 (ref= '0') / param=glm;
    model y = place2 place3 / dist=negbin link=log lrci;
    estimate 'incidence rate ratio of place1 vs place3' place3 1 / exp;
    lsmeans place3 / ilink diff= control('1') exp cl;
run;



/* SAS\materials\Document\PharmaSUG-2024-ST-199.pdf */
/* INCIDENCE RATE (%) */
PROC SORT DATA=ADAM.ADAE (WHERE=(SAFFL='Y' AND TRTEMFL='Y')) OUT=UNIQUE_AE NODUPKEY;
    BY TRT01AN AEBODSYS AEDECOD USUBJID;
RUN;
PROC FREQ DATA=UNIQUE_AE NOPRINT;
    TABLE TRT01AN*AEBODSYS*AEDECOD / OUT=COUNT (DROP=PERCENT);
RUN;
/* To determine the denominator for calculating the incidence rate */
PROC FREQ DATA=ADAM.ADSL (WHERE=(SAFFL='Y')) NOPRINT;
    TABLE TRT01AN / OUT=BIGN (DROP=PERCENT);
RUN;
/* After obtaining counts for both the numerator and denominator, the datasets are merged */
DATA INC_RATE;
    MERGE COUNT(IN=A RENAME=(COUNT=NUM)) BIGN(IN=B);
    BY TRT01AN;
    IF A;
    INC=ROUND(NUM/COUNT*100,.01);
run;
PROC SORT;
    BY AEBODSYS AEDECOD;
RUN;
PROC TRANSPOSE DATA=INC_RATE OUT=INC_RATE_TR (DROP=_NAME_) PREFIX=INC;
    BY AEBODSYS AEDECOD;
    ID TRT01AN;
    VAR INC;
RUN;

/* EVENT INCIDENCE RATE ADJUSTDED BY PATIENT-YEARS */
DATA ADSL;
    SET ADAM.ADSL;
    IF NMISS(TRTEDT,TRTSDT)=0 THEN TRTDURY=(TRTEDT-TRTSDT+1)/365.25;
    ELSE IF TRTSDT>. THEN TRTDURY=(INPUT("&SNAPDT.", DATE9.)- TRTSDT+1)/365.25;
RUN;
*SORT AND FILTER THE ADAE;
PROC SORT DATA=ADAE (WHERE=(SAFFL='Y' AND TRTEMFL='Y')) OUT=AE;
    BY AEBODSYS AEDECOD;
RUN;
*COUNT EVENTS PER PREFERRED TERM;
PROC FREQ DATA=AE NOPRINT;
    BY AEBODSYS AEDECOD;
    TABLE TRT01AN / OUT=EVENT (DROP=PERCENT);
RUN;
PROC SORT DATA=EVENT;
    BY TRT01AN AEBODSYS AEDECOD;
RUN;
/* To get the denominator */
PROC SQL NOPRINT;
    CREATE TABLE PY AS
        SELECT TRT01AN, SUM(TRTDURY) AS DENOM
            FROM ADSL
                GROUP BY TRT01AN;
QUIT;
DATA EIR;
    MERGE EVENT(IN=A) PY(IN=B);
    BY TRT01AN;
    EIR= COUNT/DENOM*100;
run;
PROC SORT;
    BY AEBODSYS AEDECOD;
RUN;
PROC TRANSPOSE DATA=EIR OUT=EIR_TR (DROP=_NAME_) PREFIX=EIR;
    BY AEBODSYS AEDECOD;
    ID TRT01AN;
    VAR EIR;
RUN;

/* EXPOSURE-ADJUSTED INCIDENCE RATE */
/* To address variability across preferred terms, one strategy involves generating a placeholder dataset DUMMY */
/* This unique combination is then assigned to every subject in the safety population, akin to a Cartesian join, irrespective of whether they experienced a specific adverse event or not */
PROC SQL NOPRINT;
    CREATE TABLE DUMMY AS
        SELECT DISTINCT A.USUBJID, B.AEBODSYS, B.AEDECOD FROM
            ADSL A, ADAE B WHERE A.SAFFL='Y' AND B.TRTEMFL='Y';
QUIT;
/* For subjects who experience an adverse event, only the first event that occurred will be considered in the calculation of patient-years */
PROC SORT DATA=ADAE (WHERE=(SAFFL='Y' AND TRTEMFL='Y')) OUT=SORTED_AE;
    BY USUBJID AEBODSYS AEDECOD ASTDT;
RUN;
DATA FIRST_AE;
    SET SORTED_AE;
    BY USUBJID AEBODSYS AEDECOD;
    IF FIRST.AEDECOD THEN OUTPUT;
RUN;
/* To ensure non-null values for the event start date in ADAE (ASTDT) */
PROC SQL NOPRINT;
    CREATE TABLE ADAE AS
        SELECT A.*, B.TRT01AN, B.TRTSDT, IFN(^MISSING(B.EOSDT), B.EOSDT, INPUT("&SNAPDT",DATE9.)) AS EOSDT FORMAT=DATE9. "END OF STUDY DATE", C.ASTDT, 
            CASE WHEN MISSING(C.ASTDT) 
                THEN (CALCULATED EOSDT - B.TRTSDT+1)/365.25
                ELSE (C.ASTDT-B.TRTSDT+1)/365.25
            END AS SUBJECT_YEAR
            FROM DUMMY A LEFT JOIN ADSL B ON A.USUBJID=B.USUBJID
                LEFT JOIN FIRST_AE C ON A.USUBJID=C.USUBJID AND
                    A.AEBODSYS=C.AEBODSYS AND
                        A.AEDECOD=C.AEDECOD;
QUIT;
/* To obtain the numerator for the Exposure-adjusted Incidence Rate (EAIR) */
PROC FREQ DATA=ADAE (WHERE=(^MISSING(ASTDT))) NOPRINT;
    TABLE TRT01AN*AEBODSYS*AEDECOD / OUT=NUM (DROP=PERCENT);
RUN;
/* To determine the denominator for EAIR, the patient-years calculated in the ADAE dataset need to be aggregated by treatment group, System Organ Class (SOC), and Preferred Term (PT) */
PROC SQL NOPRINT;
    CREATE TABLE DENOM AS
        SELECT TRT01AN, AEBODSYS, AEDECOD, SUM(SUBJECT_YEAR) AS DENOM
            FROM ADAE
                GROUP BY TRT01AN,AEBODSYS,AEDECOD;
QUIT;
DATA EAIR;
    MERGE NUM(IN=A) DENOM(IN=B);
    BY TRT01AN AEBODSYS AEDECOD;
    EAIR=COUNT/DENOM*100;
PROC SORT;
    BY AEBODSYS AEDECOD;
RUN;
PROC TRANSPOSE DATA=EAIR OUT=EAIR_TR (DROP=_NAME_) PREFIX=EAIR;
    BY AEBODSYS AEDECOD;
    ID TRT01AN;
    VAR EAIR;
RUN;


