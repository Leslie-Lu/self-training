
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
/* ************************************************************* */
/* 二项分布 */
/* 只有两种结果的情况下，成功次数的分布 */
data work.binomial;
    do i=1 to 10;
        a= rand("bino", .5, 100); /* 0.5是成功的概率，100是试验次数 */
        output;
    end;
    drop i;
run;
proc print data=work.binomial; run;
/* ************************************************************* */
/* 几何分布 */
/* 在伯努利试验中，成功一次所需的试验次数的分布 */
data work.geometric;
    do i=1 to 10;
        a= rand("geometric", .5); /* 0.5是成功的概率 */
        output;
    end;
    drop i;
run;
proc print data=work.geometric; run;
/* ************************************************************* */
/* 泊松分布 */
/* 单位时间内随机事件发生次数的分布，注意，事件必须为独立事件 */
/* 5是单位时间内事件的平均发生次数，即期望，泊松分布的期望与方差相等 */ 
data work.poisson;
    do i=1 to 10;
        a= rand("poisson", 5);
        output;
    end;
    drop i;
run;
proc print data=work.poisson; run;
/* ************************************************************* */
/* 正态分布 */
/* 0是均值，1是标准差，注意这里rand的第三个参数指定是标准差而非方差 */
data work.normal;
    do i=1 to 10;
        a= rand("normal", 0, 1); 
        output;
    end;
    drop i;
run;
proc print data=work.normal; run;



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

