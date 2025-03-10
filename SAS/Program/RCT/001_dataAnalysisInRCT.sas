
/* ******************************************** */
/* 定义基准线 */
data work.vsdm;
    merge vs(in=a) dim;
    by studyid usubjid;
    if a;
run;
proc sort data=work.vsdm;
    by usubjid vsdtc;
run;
data work.baseline;
    set work.vsdm(where=(vsdtc<rfstdtc));
    by usubjid;
    if last.usubjid;
    vsblfl= "Y";
run;
data work.vs2;
    merge work.vsdm(in=a) work.baseline;
    by usubjid vsdtc;
    if a;
run;
/* ********************************************** */
/* 区分不同的vstest */
proc sort data=work.vsdm;
    by usubjid vstest vsdtc;
run;
data work.baseline;
    set work.vsdm(where=(vsdtc<rfstdtc));
    by usubjid vstest;
    if last.vstest;
    vsblfl= "Y";
run;
data work.vs2;
    merge work.vsdm(in=a) work.baseline;
    by usubjid vstest vsdtc;
    if a;
run;
/* ********************************************** */
/* vsstresn含缺失值 */
proc sort data=work.vsdm;
    by usubjid vstest vsdtc;
run;
data work.baseline;
    set work.vsdm(where=(vsdtc<rfstdtc and vsstresn ne .));
    by usubjid vstest;
    if last.vstest;
    vsblfl= "Y";
run;
data work.vs2;
    merge work.vsdm(in=a) work.baseline;
    by usubjid vstest vsdtc;
    if a;
run;
/* ********************************************** */
/* 日期时间存在缺失 */
/* 这里不针对填补日期时间的情况，仅考虑利用未缺失的日期时间 */
data work.vsdm;
    merge vs(in=a) dim;
    by studyid usubjid;
    if a;
    n= _n_;
run;
proc sort data=work.vsdm;
    by usubjid vstest vsdtc;
run;
data work.baseline;
    /* 使用lengthn函数判断长度是否为10，即日期时间是否在yymmdd10.格式下为缺失 */
    set work.vsdm(where=(vsdtc<rfstdtc and vsstresn ne . and lengthn(vsdtc)=10));
    by usubjid vstest;
    if last.vstest;
    vsblfl= "Y";
run;
data work.vs2;
    merge work.vsdm(in=a) work.baseline;
    by usubjid vstest vsdtc;
    if a;
run;
/* 由于前面日期时间有缺失，导致上面proc sort会将有缺失的记录排到更靠上的位置 */
/* 为了保证数据的完整性，需要再次按_n_排序 */
proc sort data=work.vs2;
    by n;
run;
/* ********************************************** */
/* change from baseline */
data work.base;
    set work.vs2(where=(vsblfl="Y"));
    keep usubjid vstest vsstresn vsdtc;
    rename vsstresn=base vsdtc=basedtc;
run;
data work.vs3;
    merge work.vs2(in=a) work.base;
    by usubjid vstest;
    if a;
run;
data work.vs4;
    set work.vs3;
    if vsdtc<basedtc then base= .;
    if nmiss(vsstresn, base) eq 0 then do;
        chg= vsstresn-base;
        pchg= chg/base*100;
    end;
run;
/* 对于chg和pchg，可以使用折线图来描述变化 */
symbol interpol=join; /* 描述折线图的连接方式，表示数据点将通过线条连接起来，形成一条连续的折线 */
proc gplot data=work.vs4(where=(base ne . and usubjid= "001-001"));
    plot chg*vsdtc= vstest; /* chg变量作为Y轴，vsdtc变量作为X轴，vstest变量作为分组变量 */
run;
/* ********************************************** */
/* 缺失值的处理 */
/* 1. 均值填补 */
/* summary 是 PROC MEANS 生成的输出对象名称 */
ods trace on;
ods output summary= work.mean;
proc means data=sashelp.baseball mean;
    var salary;
run;
ods output close;
ods trace off;
proc sql noprint;
    select salary_mean into: salary_mean from work.mean;
quit;
data work.baseball;
    set sashelp.baseball;
    if salary=. then do; 
        salary= &salary_mean;
        salary_imp_fl= "Y";
    end;
run;
proc print; run;
/* 分组计算均值 */
proc sql noprint;
    select mean(salary) into: mean1-:mean4 
        from sashelp.baseball 
            group by div;
quit;
%put &mean1 &mean2 &mean3 &mean4;
data work.baseball;
    set sashelp.baseball;
    if salary=. then do;
        select(div);
            when ("AE") salary= &mean1;
            when ("AW") salary= &mean2;
            when ("NE") salary= &mean3;
            when ("NW") salary= &mean4;
            otherwise;
        end;
        salary_imp_fl= "Y";
    end;
run;
proc print; run;
/* 线性回归模型填补 */
ods trace on;
ods output parameterestimates= work.param;
proc reg data=sashelp.baseball;
    model salary= nouts nassts nerror;
run;
ods output close;
ods trace off;
data work.param1;
    set work.param end=eof;
    if eof then call symput("max", strip(put(_n_, best.)));
run;
%macro regImp;
%global factor;
%let factor=;
%do i=1 %to &max;
    data work.param&i;
        set work.param;
        if _n_=&i;
        if variable ne "Intercept" then call symput("reg&i", strip(put(estimate, best.))||"*"||strip(variable));
        else call symput("reg&i", strip(put(estimate, best.)));
    run;
    %put &&reg&i;
    %let factor= &factor+(&&reg&i);
%end;
%put &factor;
%mend regImp;
%regImp;
data work.baseball;
    set sashelp.baseball;
    if salary=. then do;
        salary= &factor;
        salary_imp_fl= "Y";
    end;
run;
proc print; run;
/* 
在使用回归填补之前，可以使用主成分分析等方法找出对目标变量影响较大的变量，然后再进行回归填补
*/
/* 2. 末次观测值结转法（LOCF） */
proc sort data=work.lb out=work.lb2;
    by usubjid lbtestcd lbdtc;
run;
data work.lb3;
    set work.lb2;
    by usubjid lbtestcd;
    retain intermediate_value;
    if first.lbtestcd then intermediate_value= lbstresn;
    if lbstresn=. then do;
        lbstresn= intermediate_value;
        locf_fl= "Y";
    end;
    else intermediate_value= lbstresn;
run;
/* 3. 日期时间 */
/* 
日期时间一般采用直接填补的方法，即自定义一个日期时间，然后填补
*/
data work.ae2;
    set work.ae;
    if aestdtc ne "" or aeendtc ne "" then do;
        if lengthn(aestdtc)=7 then aestedtc=strip(aestdtc)||"-01";
        else if lengthn(aestdtc)=4 then aestdtc=strip(aestdtc)||"-01-01";
        else if aestdtc="" then aestdtc=substr(aeendtc,1,4)||"-01-01";

        /*将日期字符串转换为日期值并减去一天，得到上个月的最后一天*/
        if lengthn(aeendtc)=7 then aeendtc=strip(put(input(substr(aeendtc,1,4)||"-"||strip(put(input(substr(aeendtc,6,7),best.)+1,z2.)||"-01"),yymmdd10.)-1,yymmdd10.));
        if lengthn(aeendtc)=4 then aeendtc=strip(aeendtc)||"-12-31";
        else if aeendtc="" then aeendtc=substr(aestdtc,1,4)||"-12-31";
    end;
run;
/* ***************************************************************** */
/* 时间窗口/持续时间 */
data work.lb2;
    set work.lb;
    if lbdtc<rfstdtc then lbdy=input(lbdtc,yymmdd10.)-input(rfstdtc,yymmdd10.);
    else lbdy=input(lbdtc,yymmdd10.)-input(rfstdtc,yymmdd10.)+1; /*避免持续时间为0的情况*/
run;
/* 以上代码可以简化为 */
data work.lb2;
    set work.lb;
    lbdy=input(lbdtc,yymmdd10.)-input(rfstdtc,yymmdd10.)+(lbdtc>=tfstdtc); /*避免持续时间为0的情况*/
run;
/* 
时间窗口的定义应当保证不重不落，即每一个确定的时间点只能属于一个时间窗
可以使用proc format来帮助定义时间窗
*/
proc format;
    value visit;
        low--90= "Month -4"
        -90--60= "Month -3"
        -60--30= "Month -2"
        -30-0  = "Month -1"
        1-30   = "Month  1"
        31-60  = "Month  2"
    ;
run;
data work.lb3;
    set work.lb2;
    length visit $20;
    visit= strip(put(lbdy, visit.));
run;
/* 使用宏来定义时间窗 */
%macro read;
data _null_;
    set visit end=eof; /*文档化编程，即将部分编程的工作放在如excel文档里，通过修改文档内容的方式实现程序运行不同结果*/
    if eof then call symput("max", strip(put(_n_, best.)));
run;
%do i=1 %to &max;
    %global if&i;
    data _null_;
        set visit;
        if _n_ = &i;
        /*"%str(;)" 用于在宏变量中包含分号 (;) 而不让 SAS 解释器将其视为语句的结束符*/
        call symput("if&i", "if "||strip(put(dy_start, best.))||"<=lbdy<="||strip(put(dy_end, best.))||" then visit='"||strip(visit)||"'%str(;)");
        call symput("ifs&i", "if "||strip(put(dy_start, best.))||"<=lbdy<="||strip(put(dy_end, best.))||" then visitnum="||strip(put(visitnum, best.))||"%str(;)");
    run;
%end;
%global if ifs;
%let if=;
%let ifs=;
%do j=1 %to &max;
    %let if= &if &&if&j;
    %let ifs= &ifs &&ifs&j;
%end;
%put &ifs;
%mend read;
data work.lb2;
    set work.lb;
    &if;
    &ifs;
run;
/* 使用proc sql来定义时间窗 */
proc sql;
    create table work.lb2 as
        select a.*, b.visit, b.visitnum from work.lb as a
        left join visit as b
            on dy_start<=lbdy<=dy_end
                order by subjid, lbtest, lbdtc;
quit;
/* ***************************************************** */
/* 设置图表表头和脚注 */
proc print data=sashelp.cars;
    var make model;
    title j=c "Vehicle Market Information Table";
    footnote j=l "Data is from sashelp.cars";
run;
/* 全局设置 */
title j=c "Vehicle Market Information Table";
footnote j=l "Data is from sashelp.cars";
proc means data=sashelp.cars;
    var msrp;
run;
proc freq data=sashelp.cars;
    table type*cylinders;
run;    
/* 自动设置表头和脚注 */
title; footnote;
%macro tf_read;
%global title footnote;
%if not %symexist(pgm) %then %do;
    %put Error: Macro variable pgm is not defined in the program;
    %put Error: Please check;
    %goto Exit;
%end;
/* read excel file and generate title and footnote */
proc import datafile="title_footnote.xlsx" dbms=xlsx replace out=work.tf;
run;
data _null_;
    set work.tf;
    ***filter based on &pgm*******;
    where strip(upcase(program_name))= "%upcase(&pgm)";
    ***title***;
    call symput("title1", "Table "||strip(table_number));
    call symput("title2", strip(table_name));
    ***footnote****;
    call symput("footnote", strip(footnote));
run;
%Exit;
%mend tf_read;
%tf_read;
dm log "clear"; dm output "clear";
%let pgm=t_baseball;
%include "tf_read.sas";
title1 j=c "&title1";
title2 j=c "&title2";
title3 j=c "";
/* 
%bquote 是一个宏函数，用于在宏变量中包含特殊字符（如引号、括号等）时进行转义处理。它会将宏变量中的特殊字符转义，使其在解析时不会引起语法错误
*/
footnote1 j=l "%bquote(&footnote)";
footnote2 j=l "";
footnote3 j=l "Program: &pgm..sas."
          j=r "Date time: %sysfunc(date(), date9.) %sysfunc(time(), time5.)";
option nobyline center nonumber nodate;
ods rtf file="&pgm..rtf" style=htmlblue;
    proc contents data=sashelp.baseball;
    run;
ods rtf close;
