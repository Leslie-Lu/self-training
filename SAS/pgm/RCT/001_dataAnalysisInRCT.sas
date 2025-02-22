
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

