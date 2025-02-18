
/* 
data步中的各种函数运算方式为横向，而proc的运行方式为纵向，是处理数据集中的一个或多个变量。
*/

proc means data=sashelp.cars clm /*lclm*/ alpha=.01 n nmiss p25 p75 std var
                                     cv kurtosis mode range stderr sum maxdec=2;
    var msrp;
    output out=work.cars_ci mean=mean std=std stderr=se lclm=lclm uclm=uclm;
run;
data work.cars_ci2;
    set work.cars_ci;
    lclm=mean-quantile("normal", .9995, 0, 1)*se;
    uclm=mean+quantile("normal", .9995, 0, 1)*se;
run;
proc print data=work.cars_ci2; run;
proc sort data=sashelp.cars out=work.cars;
    by type;
run;
proc means data=work.cars;
    by type;
    var msrp;
run;
proc means data=work.cars;
    where type in ('Hybrid', 'SUV');
    class type;
    var msrp;
    output out=work.cars_summary;
run;
proc means data=score;
    var score;
    weight weight; /*权重*/
run;
proc means data=score;
    var score;
    freq count; /*频率*/
run;
/* 同样的功能可以使用proc summary和proc univariate来实现 */

/*一维频率表*/
proc freq data=sashelp.cars;
    table type; 
run;
/*二维频率表*/
/* 
在语法上，为了表示两个变量联立而且分别计算频数，要在变量之间加上*，
该符号运行满足分配律，即a*(b c)等价于a*b a*c
 */
proc freq data=sashelp.cars;
    table type*origin / nopercent norow nocol out= work.cars_freq; 
run;
/* 三维频率表 */
/* 在更高维度下，proc freq会将高于二维的变量按照不同的值拆分到不同的表中 */
proc freq data=sashelp.cars;
    table type*origin*cylinders;
run;

/* 异常值处理 */
/* ************************************************************* */
/* 按照均值加减3个标准差来处理 */
proc means data=sashelp.cars mean std stderr;
    var cylinders;
run;
proc means data=sashelp.cars mean std stderr noprint;
    var cylinders;
    output out=work.cylinders_mean(drop=_type_ _freq_) mean=cy_mean;
    output out=work.cylinders_std(drop=_type_ _freq_) std=cy_std;
    output out=work.cylinders_se(drop=_type_ _freq_)  stderr=cy_se;
run;
data work.cy_outliers;
    merge work.cylinders_mean work.cylinders_std;
    call symput("hLimit", strip(put(cy_mean+3*cy_std, best.)));
    call symput("lLimit", strip(put(cy_mean-3*cy_std, best.)));
run;
data work.cylinders;
    set sashelp.cars(keep=type cylinders);
    if cylinders>&hLimit or cylinders<&lLimit then outlierfl= 'Y';
    else outlierfl= 'N';
run;
proc print data=work.cylinders; 
    where outlierfl= "Y";
run;
proc means data=sashelp.cars n nmiss;
    var cylinders;
run;
/* ******************************************************************* */
/* 使用proc sql一步到位 */
proc sql;
    create table work.cylinders_sql as
        select type, cylinders,
               case when cylinders>hLimit or cylinders<lLimit
                then "Y" else "N" end as outlierfl
        from sashelp.cars as a
        left join (
            select avg(cylinders)+3*std(cylinders) as hLimit,
                   avg(cylinders)-3*std(cylinders) as lLimit
            from sashelp.cars
        ) as b
        on 1=1;
quit;
/* 
在 proc sql 语句中，on 1=1 是一种特殊的用法，用于创建一个笛卡尔积（即每一行都与另一表的每一行匹配）。
*/
proc print data=work.cylinders_sql;
    where outlierfl="Y";
run;
/* *********************************************************************** */
/* 使用macro来处理异常值 */
%macro outlier_check(data,var);
%local rc dsid num_vars;
%let dsid= %sysfunc(open(&data));
%let num_vars= %eval(%sysfunc(countc(&var,","))+1);
%do j=1 %to &num_vars;
    %let input_var&j = %upcase(%scan(&var,&j,",")) ;
    %if %sysfunc(varnum(&dsid,&&input_var&j)) > 0 %then %do;
        %put &&input_var&j EXIST;
        proc sql;
            create table _&j as
                select &&input_var&j,
                       case when &&input_var&j>upper or &&input_var&j<lower 
                        then "Y" else "N" end as &&input_var&j.._FLAG 
                from &data as a 
                left join (
                    select avg(&&input_var&j)+3*std(&&input_var&j) as upper,
                           avg(&&input_var&j)-3*std(&&input_var&j) as lower 
                    from &data
                ) as b 
                on 1=1;
        quit;
    %end;
    %else %put &&input_var&j NOT EXIST;
    data &data.2;
    merge _1-
        %do i=1 %to &num_vars;
            %if %sysfunc(exist(_&i.)) %then _&i;
        %end;;
    run;
    proc print data=&data.2;
        where 
            %do j=1 %to &num_vars;
                %let input_var&j = %upcase(%scan(&var,&j,",")) ;
                %if %sysfunc(varnum(&dsid,&&input_var&j)) > 0 %then %do;
                    &&input_var&j.._FLAG= "Y"
                    %if &j < &num_vars %then or; 
                %end;
                %else %do;
                    " "
                    %if &j < &num_vars %then or;
                %end;
            %end;;
    run;
%end;
%let rc = %sysfunc(close(&dsid));
%mend;
data work.cars;
    set sashelp.cars;
run;
%outlier_check(work.cars,%str(cylinders));
%outlier_check(work.cars, %str(cylinders, invoice));
%outlier_check(work.cars, %str(cylinders, invoice, test));
/* ***************************************************************** */
/* 按照百分位数删除p5和p95 */
proc univariate data=work.cylinders outtable=work.cylinders_p;
    var cylinders;
run;
proc sql;
    select _p5_ into: lLimit from work.cylinders_p;
    select _p95_ into: hLimit from work.cylinders_p;
quit;
data work.cylinder2;
    set work.cylinders;
    if cylinders>&hLimit or cylinders<&lLimit then outlierfl= 'Y';
    else outlierfl= 'N';
    if outlierfl= "Y";
run;
proc print; run;


/* 常见的分布 */
/***********************************************************************
 Programs for 
 Wicklin, Rick, 2013, Simulating Data with SAS, SAS Institute Inc., Cary NC.

 Chapter 2: Simulating Data from Common Univariate Distributions
 ***********************************************************************/
/********************************************************************
 Getting Started: Simulate Data from the Standard Normal Distribution
 *******************************************************************/
/* 
Use the DATA step to simulate data from univariate and uncorrelated multivariate distributions.
Use the SAS/IML language to simulate data from many distributions, including correlated multivariate distributions.
Although the DATA step is a useful tool for simulating univariate data, SAS/IML software is more powerful for simulating multivariate data.
To “simulate data” means to generate a random sample from a distribution with known properties.
*/
/* ************************************************************* */
%let N = 100;
data work.Bernoulli(keep=x);
    call streaminit(4321);
    p = 1/2;
    do i = 1 to &N;
        x = rand("Bernoulli", p);           /* coin toss */
        output;
    end;
run;
/* we can use proc freq to compute the empirical distribution of the data */
proc freq data=work.Bernoulli;
    table x;
run;
/* the extact probabilities are obtained from the probability mass function (PMF) of the distribution */
data work.PMF(keep=t Y);
    p = 1/2;
    do t = 0 to 1;
        Y = pdf("Bernoulli", t, p);
        output;
    end;
run;
/* GTL syntax changed at 9.4 */
%macro ScaleOpt;
%if %sysevalf(&SysVer < 9.4) %then pct;
%else proportion;
%mend;
proc template;
    define statgraph DiscretePDF;
    dynamic _X _T _Y _Title _HAlign; /*动态变量将在后续的宏调用中动态赋值*/
    begingraph;
        entrytitle halign=center _Title;
            layout overlay / yaxisopts=(griddisplay=on)
                xaxisopts=(type=discrete display=(TICKS TICKVALUES LINE ));
            barchart x=_X / name='bar' stat=%ScaleOpt legendlabel='Sample';
            scatterplot x=_T y=_Y / name='pmf' legendlabel='PMF/PDF'
                markerattrs=GraphDataDefault(symbol=CIRCLEFILLED size=10);
            discretelegend 'bar' 'pmf' / opaque=true border=true halign=_HAlign 
                valign=top across=1 location=inside;
        endlayout;
    endgraph;
    end;
run;
title; title2; title3; /*清除之前设置的标题*/
%macro MergeAndPlot(DistName);
data work.Discrete;
   merge &DistName work.PMF;
run;
proc sgrender data=work.Discrete template=DiscretePDF;
    dynamic _X="X" _T="T" _Y="Y" _HAlign="right"
    _Title="Sample from &DistName Distribution (N=&N)";
run;
%mend;
/* the expected percentages for each result are shown by the round markers */
%MergeAndPlot(work.Bernoulli);
/* 
if X is a random variable that has a Bernoulli distribution with parameter p, 
then the expected value of X is p and the variance of X is p*(1-p).
*/
/* *********************************************************** */
/* 二项分布 */
/* 只有两种结果的情况下，成功次数的分布 */
/* 0.5是成功的概率，100是试验次数 */
data work.binomial;
    do i=1 to 100;
        x= rand("Binomial", .5, 100); 
        output;
    end;
    drop i;
run;
proc print data=work.binomial; run;
data work.PMF(keep=t Y);
    p = 1/2;
    do t = 0 to 100;
        Y = pdf("Binomial", t, p, 100);
        output;
    end;
run;
%MergeAndPlot(work.binomial);
/* 
if X is a random variable from the binomial(p, n) distribution, 
then the expected value of X is n*p and the variance of X is n*p*(1-p).
when you simulate data from a population model, the data will most always look slightly different from the theoretical distribution.
this deviation is not an indication that something is wrong. Rather, it demonstates sampling variation.
it is this sampling variance that makes simulation so valuable.
*/
/* ************************************************************* */
/* 几何分布 */
/* 在伯努利试验中，成功一次所需的试验次数的分布 */
/* 
an atlternative definition, which is used by the MCMC procedure in SAS, 
is to define the geometric distribution to be the number of failures before the first success.
*/
data work.geometric;
    do i=1 to 10;
        a= rand("geometric", .5); /* 0.5是成功的概率 */
        output;
    end;
    drop i;
run;
proc print data=work.geometric; run;
/* 
if X is a random variable from the geometric(p) distribution, 
then the expected value of X is 1/p and the variance of X is (1-p)/(p^2).
*/
/* ************************************************************* */
/* the discrete uniform distribution */
/* we can use the discrete uniform distribution to produce k intergers in the range [1,k] */
/* 
sas does not have a built-in function for the discrete uniform distribution.
instead, we can use the continuous uniform distribution to produce a random number u in the interval [0,1],
and then use the ceil function to produce the smallest interger that is greater than or equal to k*u.
*/
data work.Uniform(keep=x);
    call streaminit(4321);
    k = 6;                                   /* a six-sided die         */
    do i = 1 to &N;
        x = ceil(k * rand("Uniform"));        /* roll 1 die with k sides */
        output;
    end;
run;
proc freq data=work.Uniform;
   table x / nocum;
run;
/* 
the uniform random number generator never generates the number 0 nor the number 1.
therefore, all values are in the open interval (0, 1).
we can also use the uniform distribution to sample random values from (a, b).
to do this, we can use the formula a + (b-a)*rand("Uniform").
if x is a random variable from the uniform(a, b) distribution, then the expected value of x is (a+b)/2 and the variance of x is ((b-a)^2)/12.
*/
/* ************************************************************** */
/* tabulated Distributions */
/* 
in some situations there are multiple outcomes, but the probabilities of the outcomes are not equal.
the rand function supports a table distribution that enables you to specify a table of probabilities for each of k outcomes.
we can use the table distributions to sample with replacement from a finite set of outcomes where we specify the probability for each outcome.
the following data step generates a random sample of size N=100 from the table distribution with probabilities p={0.5, 0.2, 0.3}
*/
data Table(keep=x);
    call streaminit(4321);
    p1 = 0.5; p2 = 0.2; p3 = 0.3;
    do i = 1 to &N;
        x = rand("Table", p1, p2, p3);        /* sample with replacement */
        output;
    end;
run;
proc freq data=Table;
   table x / nocum;
run;
/* 
if we have many potential outcomes, it would be tedious to specify the probabilities of each outcome by using a comma-separated list.
istead, it is more convenient to specify an array in the data step to hold the probabilities,
and ro use the of operator to list the values of the array as shown in the following example.
*/
data Table(keep=x);
    call streaminit(4321);
    array p[3] _temporary_ (0.5 0.2 0.3);
    do i = 1 to &N;
        x = rand("Table", of p[*]);           /* sample with replacement */
        output;
    end;
run;
/* 
the _temporary_ modifier is used to create a temporary array that is not added to the data set.
the elements of a temporary array do not have names and are not written to the output data set,
which means that we do not need to use a drop or keep option to omit them from the data set.
the table distribution is related to the multinomial distribution.
if we generate N observations from the table distribution and tabulate the frequencies for each category,
then the frequency vector is a single observation from the multinomial distribution.
consequently, the table and multinomial distributions are related in the same way that the bernoulli and binomial distributions are related.
*/
/* ************************************************************* */
/* 泊松分布 */
/* 单位时间内随机事件发生次数的分布，注意，事件必须为独立事件，且假设事件的平均发生次数是恒定的 */
/* 5是单位时间内事件的平均发生次数，即期望，泊松分布的期望与方差相等 */ 
data work.poisson;
    do i=1 to 100;
        x= rand("poisson", 5);
        output;
    end;
    drop i;
run;
proc print data=work.poisson; run;
data work.PMF(keep=t Y);
    lambda = 5;
    do t = 0 to 10;
        Y = pdf("Poisson", t, lambda);
        output;
    end;
run;
%MergeAndPlot(Poisson);
/* ***************************************************************** */
/* negative binomial distribution */
/* 
a negative binomial variable is defined as the number of failures before k successes in a series of independent Bernoulli trials with probability of success p.
define a trial as rolling a six-sided die until a specified face appears k=3 times.
*/
data work.NegBinomial(keep=x);
    call streaminit(4321);
    k = 3; p = 1/6;
    do i = 1 to &N;
        x = rand("NegBinomial", p, k);       /* roll die until k=3 sixes */
        output;
    end;
run;
proc univariate data=work.NegBinomial;
    histogram x;
    ods select histogram;
run;
/* ************************************************************* */
/* 正态分布 */
/* 
the normal distribution with mean \mu and standaed deviation \sigma is denoted by N(\mu, \sigma).
*/
proc template;
    define statgraph ContPDF;
    dynamic _X _T _Y _Title _HAlign
            _binstart _binstop _binwidth;
    begingraph;
        entrytitle halign=center _Title;
        layout overlay /xaxisopts=(linearopts=(viewmax=_binstop));
            histogram _X / name='hist' SCALE=DENSITY binaxis=true 
                endlabels=true xvalues=leftpoints binstart=_binstart binwidth=_binwidth;
            seriesplot x=_T y=_Y / name='PDF' legendlabel="PDF" lineattrs=(thickness=2);
            discretelegend 'PDF' / opaque=true border=true halign=_HAlign valign=top 
                    across=1 location=inside;
        endlayout;
    endgraph;
end;
run;
%macro ContPlot(DistName, binstart, binstop, binwidth);
data Cont;
   merge &DistName work.PDF;
run;
proc sgrender data=Cont template=ContPDF;
   dynamic _X="X" _T="T" _Y="Y" _HAlign="right"
	   _binstart=&binstart _binstop=&binstop _binwidth=&binwidth
	   _Title="Sample from &DistName Distribution (N=&N)";
run;
%mend;
/* 0是均值，1是标准差，注意这里rand的第三个参数指定是标准差而非方差 */
data work.normal;
    do i=1 to &N;
        a= rand("normal", 0, 1); 
        output;
    end;
    drop i;
run;
proc print data=work.normal; run;
data work.Normal(keep=x);
    call streaminit(4321);     
    do i = 1 to 100;
        x = rand("Normal");                 /* X ~ N(0, 1), Standard normal distribution */
        output;
    end;
run;
proc print data=work.Normal(obs=5); run; /* show the first 5 observations */
data work.PDF;
    do t = -3.5 to 3.5 by 0.05;
        Y = pdf("Normal", t);
        output;
    end;
run;
%ContPlot(work.Normal,-3.5,3.5,0.5);


/********************************************************************
 Simulating Univariate Data in SAS/IML Software
we can also generate random samples by using the randgen subroutine in the SAS/IML language.
the randgen subroutine uses the same algorithms as the rand function, but it fills and entire matrix at once,
which means that we do not need a do loop.
 *******************************************************************/
/***********************************************************************/
proc datasets lib=work kill nolist;
run;
proc iml;
    /* define parameters */
    p = 1/2;  lambda = 4;  k = 6;  prob = {0.5 0.2 0.3};

    /* allocate vectors */
    /* 
    the j function allocates a matrix of a certain size and fills it with a specified value.
    the syntax j(r, c) creates a matrix with r rows and c columns, and the syntax j(r, c, v) fills the matrix with the value v.
    for example, the statement j(1, 5, .) creates a row vector with 5 SAS missing values.
    notice that the SAS/IML implementation is more compact than the data step implementation.
    it does not create a sas data set, but instaed holds the simulated data in memory in the form of a matrix.
    by not writing a data set to disk, the IML implementation is faster and uses less disk space.
    */
    N = 100;
    Bern = j(1, N);   Bino = j(1, N);   Geom = j(1, N);
    Pois = j(1, N);   Unif = j(1, N);   Tabl = j(1, N);

    /* fill vectors with random values */
    call randseed(4321);
    call randgen(Bern, "Bernoulli", p);     /* coin toss                */
    call randgen(Bino, "Binomial", p, 10);  /* num heads in 10 tosses   */
    call randgen(Geom, "Geometric", p);     /* num trials until success */
    call randgen(Pois, "Poisson", lambda);  /* num events per unit time */
    call randgen(Unif, "Uniform");          /* uniform in (0,1)         */
    Unif = ceil(k * Unif);                  /* roll die with k sides    */
    call randgen(Tabl, "Table", prob);      /* sample with replacement  */

    /* create a sas data set from the iml matrices */
    create work.randomData from Bern Bino Geom Pois Unif Tabl;
    append from Bern Bino Geom Pois Unif Tabl;
quit;
/* 
notice that in the sas/iml language, which supports vectors in a natural way,
the syntax for the table distribution is simpler than in the data step.
we simply define a vector of parameters and pass the vector to the randgen subroutine.
*/
proc iml;
    call randseed(4321);
    prob = j(6, 1, 1)/6;                /* equal prob. for six outcomes */
    d = j(10, 1);                       /* allocate 10 x 1 vector        */
    call randgen(d, "Table", prob);     /* fill with integers in 1-6    */
    print prob, d;
quit;
/* 
the sample function generates a random sample from a finite set.
use this function to sample with replacement or without replacement.
this function can sample with equal probability or with unequal probability.
this function is similar to the table distribution in that we can specify the probability of sampling each element in a finite set.
however, the table fistribution only supports sampling with replacement, whereas the sample function supports sampling with or without replacement.
the following exmaple simulates three possible draws, without replacement, of five socks.
*/
proc iml;
    call randseed(4321);
    socks = {"Black" "Black" "Black" "Black" "Black" 
             "Brown" "Brown" "White" "White" "White"};
    params = {5,                         /* sample size                */
              3};                       /* number of samples          */  
    s = sample(socks, params, "WOR");     /* sample without replacement */
    /* 
    the sample function returns a matrix with 3 rows and 5 columns.
    each row contains a random sample of 5 socks without replacement.
    the experiment is repeated 3 times.
    because each draw is without replacement, no row can have more than two Brown socks or more than three White socks.
    */
    print s;
quit;
/***********************************************************************/
proc iml;
    /* define parameters */
    mu = 3;  sigma = 2;

    /* allocate vectors */
    N = 100;
    StdNor = j(1, N);  Normal = j(1, N);
    Unif = j(1, N);    Expo   = j(1, N);

    /* fill vectors with random values */
    call randseed(4321);
    call randgen(StdNor, "Normal");               /* N(0,1)      */
    call randgen(Normal, "Normal", mu, sigma);    /* N(mu,sigma) */
    call randgen(Unif,   "Uniform");              /* U(0,1)      */
    call randgen(Expo,   "Exponential");          /* Exp(1)      */
quit;
/* 
except for the t, Fm abd normalmix distributions,
we can identify a distribution by its first four letters.
*/



/* proc ttest */
/* ************************************************************* */
/* 单样本t检验 */
proc ttest data=sashelp.cars h0=6;
    var cylinders;
run;
/* ************************************************************* */
/* 双样本t检验 */
data work.cars;
    set sashelp.cars;
    length orig $10.;
    if origin="Asia" then orig="Asia";
    else orig="Other";
run;
proc ttest data=work.cars;
    class orig;
    var cylinders;
run;



/* proc freq */
/* ************************************************************* */
/* 卡方检验 */
data work.d;
    do smoke= 0 to 1;
        do disease= 0 to 1;
            input count @@;
            output;
        end;
    end;
    cards;
    15 4 10 26
    ;
run;
proc print data=work.d; run;
proc freq data=work.d;
    table smoke*disease / chisq relrisk;
    weight count;
    exact pchi or;
    title "relationship between smoking and disease";
run;
/* OR= (26/10)/(4/15)=9.75 */
/* (4/15)/(26/10)=0.10 */
/* RR= (26/36)/(4/19)=3.43 */
/* 
Relative Risk (Column 1)	= Column 1: 表示 smoke=0 的组
(15/19)/(10/36)= 2.8421
Relative Risk (Column 2)	= Column 2: 表示 smoke=1 的组
(4/19)/(26/36)= 0.2915
*/



/* example */
/* ************************************************************* */
proc datasets lib=work kill nolist;
run;
%macro adeff(adeff);
%do i= 1 %to 4;
    proc freq data=&adeff(where=(avisitn=&i));
        table trta*avalc / expected norow nocol outexpect out=_&i;
    run;
    proc sql noprint;
        select int(min(expected)) into: expected from _&i;
        select int(min(count)) into: obscnt from _&i;
    quit;
    %put expected number is &expected;
    %put observed number is &obscnt;
    %if &expected lt 5 and &obscnt lt 5 %then %do;
        proc freq data=&adeff(where=(avisitn=&i));
            table trta*avalc / exact fisher;
            output out= p_val&i exact;
        run;
    %end;
    %else %do;
        proc freq data=&adeff(where=(avisitn=&i));
            table trta*avalc / chisq;
            output out= p_val&i chisq;
        run;
    %end;
    data p&i;
        set p_val&i;
        %if &expected lt 5 and &obscnt lt 5 %then %do;
            p_value= strip(put(xp2_fish, 6.3));
        %end;
        %else %do; 
            p_value= strip(put(p_pchi, 6.3));
        %end;
        keep p_value;
    run;
    proc sort data=_&i out=_&i;
        by avalc;
    run;
    proc transpose data=_&i out=_&i.t(drop=_:);
        by avalc;
        id trta;
        var count;
    run;
    data all&i.;
        merge _&i.t p&i;
        /* not use by statement, to match rows by row number */
        visit= "Week "||strip(put(&i*2, best.));
    run;
%end;
data all;
    set all1-
        %do i=1 %to 4;
            all&i
        %end;;
run;
proc print data=all; run;
%mend;
libname exlib "/materials";
data work.adeff;
    set exlib.adeff;
run;
proc print data=work.adeff; run;
%adeff(adeff=work.adeff);



/* proc princomp */
/* ************************************************************* */
/* 主成分分析 */
proc princomp data=sashelp.cars out=work.cars_pca;
    var _numeric_;
run;
/* 使用proc corr查看前5个主成分的相关性 */
proc corr data=work.cars_pca plots(maxpoints=10000)=matrix(histogram);
    var prin1-prin5;
run;

