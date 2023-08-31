
libname ex base "C:\Library\Applications\Typora\data\self-training\SAS\data";
ods graphics on;

**ex10.1**;
proc means data=sashelp.fish maxdec=2 n mean std stderr clm;
	where species="Bream";
	var height;
	title "95% Confidence Interval for Bream";
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
proc npar1way data=ex.service wilcoxon median;
  class store;
  var servicelevel;
  title "Using NPAR1WAY to Compare Service Level";
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



