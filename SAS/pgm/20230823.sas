
libname ex base "C:\Library\Applications\Typora\data\self-training\SAS\data";
ods graphics on;
ods pdf body= 'C:\Library\Applications\Typora\data\self-training\SAS\output\test.pdf';

**ex10.1**;
proc means data=sashelp.fish maxdec=2 n mean std stderr clm;
	where species="Bream";
	var height;
	title "95% Confidence Interval for Bream";
run;

/*p.153 例7-4 p.154 例7-5*/
data a7_4;
	input d @@;
	cards;
3.48
7.41
7.48
9.42
8.25
3.35
6.95
7.41
6.35
7.41
8.58
;
run;
/*调用univariate过程进行正态性检验*/
**************************************************
若样本量n不超过2000，使用Shapiro-Wilk统计量W作检验；
若n大于2000，用Kolmogorov-Smirnov D统计量.
**************************************************;
proc univariate data= a7_4 normal;
	var d;
run;
/*调用Means过程对差值d进行t检验，输出均数、标准差、t值、P值、置信区间*/
proc means data= a7_4 mean std t prt clm;
	var d;
run;


/*p.151例7-1 p.152 例7-3*/
data a7_1;
	n=36;
	mean=6.76;
	sd=1.36;
/*	t=2.030;*/
	t= quantile('t',.975,n-1);
	cl=mean-t*sd/sqrt(n);
	cu=mean+t*sd/sqrt(n);

	**one sample t test**; 
	mean_p=4;
	df=n-1;
	t=(mean-mean_p)/(sd/sqrt(n));
	p=(1-probt(abs(t),df))*2; /*probt(t,df)，自由度为df的t分布中，-∞ ~ t的累积概率*/
run;
proc print data= a7_1 noobs;
	Var cl cu t p;
run;

**ex10.2**;
**one sample t test**; 
proc univariate data=sashelp.fish mu0=14;
	where species="Bream";
	var height;
	title "Testing whether the mean of Bream height = 14 ";
run;
**equal to ex10.3***;
proc ttest data=sashelp.fish h0=14 plots(shownull)=interval;
	where species="Bream";
	var height;
	title "Testing whether the mean of Bream height = 14 "
	      "Using PROC TTEST";
run;

***ex10.4***;
***two sample t test***;
proc contents data= ex.score;
run;
proc ttest data=ex.score plots(shownull)=interval;
	class gender;
	var score;
	title "Two Sample t test for Boys and Girls";
run;

/*p.159 例7-8*/
data a7_8_1;;
	n1=12;
	mean1=120;
	std1=21.39;
	n2=7;
	mean2=101;
	std2=20.62;

/*	CI for two sample t test*/
	mean_d=mean1-mean2;
	td=quantile('t',.975,n1+n2-2);
	se_d=sqrt(((n1-1)*std1**2+(n2-1)*std2**2)/(n1+n2-2)*(1/n1+1/n2)); /*in the case of equivalence of variance*/
	cld=mean_d-td*se_d;
	cud=mean_d+td*se_d;
run;
proc print data= a7_8_1 noobs;
	var mean_d cld cud;
run;

***ex10.5***;
***use summary statistics to perform two sample t test***;
proc sort data=ex.score;
   by gender;
run;
proc means data=ex.score noprint;
	by gender;
   var score;
   output out=work.summary;
run;
proc print data=work.summary;
	title "Work.Summary";
run;
proc ttest data=work.summary;
	class gender;
	var score;
	title "Two Sample t test for Boys and Girls Using Summary Statistics";
run;

****ex10.6*******;
**one sided t test**;
proc ttest data=ex.score plots(shownull)=interval sides=U;
	class gender;
	var score;
	title "One-Sided t test for Boys and Girls";
run;

***ex 10.7***;
***paired t test***;
data work.pressure;
	input SBPbefore SBPafter @@;
	datalines;
   120 128   124 131   130 131   118 127
   140 132   128 125   140 141   135 137
   126 118   130 132   126 129   127 135
   ;
run;
proc ttest data=work.pressure;
  	paired SBPbefore*SBPafter;
	title "Testing the difference before and after stimulus";
run;

**ex10.8****;
**non-parametric test***;
/*单样本或配对设计的样本资料常用Wilcoxon符号秩检验，它的sas实现方法常用的是过程proc univariate*/
data a10_1;/****p.211 例10-1，单样本符号秩和检验****************/
	input x;
	median=18.9;
	d=x-median;
	cards;
0
0
0
0
0
12.4
34.1
69
98.4
129.5
156.1
163.5
170.9
177.6
172.4
180.3
189.2
192.2
196.8
205.3
;
run;
proc univariate data=a10_1 normal; /*检验样本的正态性,并看结果中的符号秩检验项*/
	var d;
run;
************************************************************************
注：结果中的Test for Location:Mu=0栏，t检验就是我们常见的t检验，
Signed Rank检验中S统计量：（正秩和-负秩和）/2
************************************************************************;
/*equal*/
proc univariate data=a10_1 normal mu0=18.9;
	var x;
run;

DATA D09_01;
	INPUT A B @@;
	D=B-A;/*配对样本的符号秩检验求差值*/
	/*例10-2： 15 16 14 12 8 5 17 19 20 16 10 13 22 9 15 15 3 7 13 46*/
	/*轻1 中2 重3*/
	CARDS;
1 3 1 1 1 3 1 2 3 2 2 3 1 2 1 3
2 2 3 3 1 1 3 3 1 2 2 3 1 2 2 3
; 
PROC UNIVARIATE data= D09_01 NORMAL; 
	VAR D;
RUN;

/*NPAR1WAY:单向资料非参数检验,WILCOXON:两独立样本的WILCOXON秩和检验*/
proc npar1way data=ex.service wilcoxon median;
  exact wilcoxon;/*计算确切概率。当样本含量小，不能用正态近似时，需加该语句*/
  class store;
  var servicelevel;
  title "Using NPAR1WAY to Compare Service Level";
run;

DATA D09_02;
	DO X=1 TO 5;
	   DO G=1 TO 2;
		   INPUT F @@;
		   OUTPUT;
	   END;
	END;
	CARDS;
1 1 5 14 13 10 9 5 2 0 
;
run;
PROC FREQ data= D09_02;
	TABLE X*G/CHISQ EXPECTED EXACT;
	WEIGHT F;
RUN;
PROC NPAR1WAY data= D09_02 WILCOXON ;
	CLASS G;
	VAR X;
	FREQ F;
RUN;
proc ttest data= D09_02 plots(shownull)=interval;
	class G;
	var x;
	freq F;
run;


**ex10.9***;
/*distribution fitness test */
proc univariate data=sashelp.heart normal plot;
	var Systolic;
	histogram;
run;
**ex 10.10**;
data Plates;
      label Gap = 'Plate Gap in cm';
      input Gap @@;
      datalines;
   0.746  0.357  0.376  0.327  0.485 1.741  0.241  0.777  0.768  0.409
   0.252  0.512  0.534  1.656  0.742 0.378  0.714  1.121  0.597  0.231
   0.541  0.805  0.682  0.418  0.506 0.501  0.247  0.922  0.880  0.344
   0.519  1.302  0.275  0.601  0.388 0.450  0.845  0.319  0.486  0.529
   1.547  0.690  0.676  0.314  0.736 0.643  0.483  0.352  0.636  1.080
   ;
run;
proc univariate data=Plates normal plot;
      var Gap;
      histogram /
		lognormal (l=1  color=red)
        weibull   (l=15  color=blue)
        gamma     (l=40  color=yellow);
run;


/*one sample rate test*/
/*p.165 例7-15*/
data a7_15;
	n=500;
	x=16;
	p=x/n;
	sp=sqrt(p*(1-p)/n);
	z=quantile('normal', .975);
	/*	CI for one sample rate test*/
	cl=p-z*sp;
	cu=p+z*sp;

/*	one sample rate test*/
	p_p=0.0043;
	p_1=probbnml(p_p,n, x-1);
	p_2=1-p_1;

/*	normal approximation*/
	p_n= 1- cdf('normal', (p-p_p)/(sqrt(p_p*(1-p_p)/n)));
	a= 1- probnorm(abs((p-p_p)/(sqrt(p_p*(1-p_p)/n))));
run;
proc print data= a7_15 noobs;
	var p cl cu p_2 p_n a;
run;

/*two sample rate test*/
data diss3;
	n1=200;
	n2=150;
	X1=40;
	X2=20;
	p1=X1/n1;
	p2=X2/n2;

	/*	normal approximation*/
	pc=(X1+X2)/(n1+n2);
	sp_d=sqrt(pc*(1-pc)*(1/n1+1/n2));
	p_d=p1-p2;
	z=p_d/sp_d;
	p_value=2*(1-probnorm(abs(z)));
run;
proc print data= diss3 noobs;
run;




ods pdf close;