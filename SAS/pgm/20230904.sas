
libname ex base "C:\Library\Applications\Typora\data\self-training\SAS\data";
ods graphics on;

/*example 11.3*/
/*one way anova*/
data ex.ReliefTime; 
	input Medicine $ Hours @@; 
	datalines; 
A 7 A 5 A 3 A 1
B 6 B 5 B 3 B 3
C 7 C 9 C 9 C 9
D 4 D 3 D 4 D 3
	;
run; 
/*proc freq data= ex.relieftime;*/
/*	tables Medicine*Hours;*/
/*run;*/
proc anova data = ex.ReliefTime; 
	class Medicine; 
	model Hours = Medicine; 
run;
/*equal*/
/*example 11.3*/
proc glm data = ex.ReliefTime plots(only) = diagnostics; 
	class Medicine; 
	model Hours = Medicine; 
	means Medicine / hovtest=levene(type=square); /*hovtest, Requests a homogeneity of variance test*/
	output out=aa p=pred r=resi stdr=dtdr student=sturesi;/*将分析结果导出，后续做残差分析*/
run;
/*残差分析图*/
proc gplot data=aa;
	plot sturesi*Medicine/haxis=0 to 4;
	plot sturesi*pred;
run;

/*pairwise comparison*/
/*example 11.4*/
proc glm data = ex.ReliefTime ; 
	class Medicine; 
	model Hours = Medicine; 
/*	ls-means, suitable for unbalanced data*/
	lsmeans Medicine / pdiff = All adjust=tukey; /*pdiff, request that p-values for all pairwise differences*/
run;


/*two-way ANOVA*/
/*example 11.5*/
proc means data = sashelp.class N mean ; 
	class age sex; 
	var height;
run;
/*proc glm, for unbalanced data*/
proc glm data = sashelp.class; 
	class Age Sex; 
	model Weight = Age Sex Age*Sex; /*no statistical significance for interaction*/
	lsmeans age / pdiff=all adjust=tukey;
run;

/*example 11.6*/
data ex.fruit; 
	input humidity $ temperature $ output_lbs @@; 
	datalines; 
A1 B1 58.2 A1 B1 52.6
A1 B2 56.2 A1 B2 41.2
A1 B3 65.3 A1 B3 60
A2 B1 49.1 A2 B1 42.8
A2 B2 54.1 A2 B2 50.5
A2 B3 51.6 A2 B3 48.4
A3 B1 60.1 A3 B1 58.3
A3 B2 70.9 A3 B2 73.2
A3 B3 39.2 A3 B3 40.7
; 
run;
proc means data=ex.fruit n mean;
	class humidity temperature;
/*	by humidity temperature;*/
	var output_lbs;
run;
proc glm data = ex.fruit; 
	class humidity temperature; 
	model output_lbs = humidity temperature humidity*temperature; /*statistical significance for interaction*/
	lsmeans humidity*temperature / slice=humidity; /*test for the effect of temperature within each leavl of humidity*/
	lsmeans humidity*temperature / pdiff=all adjust=tukey; 
run;

/****p.182  例8-4，随机区组方差分析****************/
data D07_02;
	input group block cure @@;
	cards;
1 1 58.02 2 1 71.9 3 1 66.27
1 2 52.7 2 2 56.35 3 2 60.59
1 3 60.22 2 3 70.08 3 3 66.12
1 4 44.49 2 4 56.6 3 4 55.36
1 5 59.31 2 5 68.25 3 5 53.39
1 6 56.23 2 6 63.36 3 6 52.34
1 7 55.16 2 7 66.12 3 7 55.16
1 8 42.48 2 8 50.02 3 8 58.64
1 9 50.84 2 9 66.97 3 9 44.01
1 10 49.38 2 10 67.05 3 10 52.49
1 11 55.16 2 11 69.89 3 11 59.99
1 12 53.47 2 12 61.08 3 12 61.08
;
run;
proc univariate data= D07_02 normal;
	class group;
	var cure;
run;
proc univariate data= D07_02 normal;
	class block;
	var cure;
run;
proc glm data= D07_02 plots(only)= diagnostics;
	class group block;
	model cure = group block;
	lsmeans group / pdiff=all adjust=tukey;
	means group / tukey;
	contrast '1 vs 2' group 1 -1 0;
	contrast '1 vs 3' group 1 0 -1;
	contrast '2 vs 3' group 0 1 -1;
run;


/**** p.220例10-6，多组计量资料秩和检验****************/
data a10_6;
	input group tnf @@;
	cards;
1 0.218
1 0.051
1 0.186
1 0.198
1 0.036
2 0.253
2 0.558
2 0.352
2 0.284
2 0.487
3 0.695
3 0.53
3 0.645
3 0.621
3 0.384
;
run;
proc univariate normal;
	class group;
	var TNF;
run;
proc npar1way wilcoxon;
	exact wilcoxon;/*计算确切概率。当样本含量小，不能用卡方近似时，需加该语句*/
	class group;
	var tnf;
run;

/****p.222 例10-7，多组等级资料秩和检验****************/
/****直接输数据****/
data a10_7;
	input group grade @@;
	cards;
1 1 2 2 3 1 3 1 4 1
1 1 2 2 3 1 3 1 4 1
1 1 2 2 3 1 3 2 4 1
1 1 2 2 3 1 3 2 4 1
1 3 2 2 3 1 3 2 4 1
2 1 2 3 3 1 3 2 4 1
2 1 2 3 3 1 3 2 4 1
2 1 2 3 3 1 3 2 4 1
2 1 2 3 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 2 4 1
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 3 3 4 2
2 1 3 1 3 1 4 1 4 2
2 1 3 1 3 1 4 1 4 2
2 1 3 1 3 1 4 1 4 2
2 1 3 1 3 1 4 1 4 2
2 1 3 1 3 1 4 1 4 2
2 1 3 1 3 1 4 1 4 2
2 1 3 1 3 1 4 1 4 3
2 1 3 1 3 1 4 1 4 3
2 2 3 1 3 1 4 1 4 3
2 2 3 1 3 1
;
run;
proc freq;
	tables group*grade;
run;
proc npar1way wilcoxon;
	class group;
	var grade;
run;

/****频数表法输数据***/
data a10_7a;
	do group=1 to 4;
	  do grade=1 to 3;
		  input f @@;
		  output;
	  end;
	end;
	cards;
4 0 1 35 7 4 77 21 9 32 15 3
;
run;
proc freq;
	tables group*grade;
	weight f;
run;
proc npar1way wilcoxon;
	class group;
	var grade;
	freq f;
run;



