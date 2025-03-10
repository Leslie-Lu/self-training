libname ex "\\scnwex\Book\Data";

**ex 16.1 ***;

proc logistic data=ex.loan 
	plots(only)=(effect (clband showobs));
	model bad(event="1")= DELINQ DEBTINC;
	title 'Bad Loan Model';
run;

proc means data=ex.loan n nmiss mean;
	var delinq debtinc;
run;

proc contents data=ex.loan;
run;

***16.2****;

proc logistic data=ex.loan
	plots(only)=(effect (clband x=(DELINQ DEBTINC REASON))
				 oddsratio (type=horizontalstat range=clip));
	class EDUCATION(ref="college") REASON(ref="car") PLOAN(ref="0")/param=reference;
	model BAD(event="1") = DELINQ DEBTINC YROPEN EDUCATION REASON PlOAN
		/clodds=pl stb parmlabel;
	units DEBTINC=5 -5;
	oddsratio EDUCATION/diff=all cl=pl;
	oddsratio REASON/diff=all cl=pl;
	title "Bad Loan Model";
run;

proc logistic data=ex.loan;
	class EDUCATION(ref="college") REASON(ref="car") PLOAN(ref="0")/param=reference;
	model BAD(event="1") = DELINQ DEBTINC YROPEN EDUCATION REASON PlOAN
						   DELINQ*DEBTINC DEBTINC*EDUCATION
		/stb parmlabel selection=foreward hierarchy=single details;
	title "Foreward Selection";
run;

****16.3****;

proc sort data=ex.loan out=work.loan;
	by DEBTINC;
run;

proc rank data=work.loan out=work.ranks groups=50;
	var DEBTINC;
	ranks rk;run;

proc means data=work.ranks noprint nway;
	class rk;
	var DEBTINC BAD;
	output out=work.bins sum(BAD)=BAD mean(DEBTINC)=DEBTINC n(BAD)=counts;
run;

data work.bins;
	set work.bins;
	logit=log((BAD+0.5)/(counts-BAD+0.5));
run;

proc sgplot data=work.bins;
	reg x=DEBTINC y=logit;
	scatter x=DEBTINC y=logit;
	yaxis label="Estimated Logit";
	title "Estimated Logit Plot of DEBTINC";
run;

****16.4*****;

proc logistic data=ex.loan;
	class EDUCATION(ref="college") REASON(ref="car") PLOAN(ref="0")/param=reference;
	model BAD(event="1") = DELINQ DEBTINC YROPEN EDUCATION REASON PlOAN
						   DELINQ*DEBTINC DEBTINC*EDUCATION
		/clodds=pl stb parmlabel selection=forward hierarchy=single details;
	title "Bad Loan Model";
run;

proc logistic data=ex.loan;
	class EDUCATION(ref="college") REASON(ref="car") PLOAN(ref="0")/param=reference;
	model BAD(event="1") = DELINQ DEBTINC YROPEN EDUCATION REASON PlOAN
						   DELINQ*DEBTINC DEBTINC*EDUCATION
		/clodds=pl stb parmlabel selection=forward hierarchy=single details;
	title "Bad Loan Model";
run;
