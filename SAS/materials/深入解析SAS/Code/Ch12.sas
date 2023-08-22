Proc princomp data = sashelp.cars out = car_component; 
	Var MPG_City MPG_Highway Weight Wheelbase Length; 
run;

/*ex12-2*/
Proc factor data = sashelp.cars simple corr;
	var MPG_City MPG_Highway Weight Wheelbase Length; 
run;

/*ex12-2 part2*/
Proc factor data = sashelp.cars simple corr n=2;
	Var MPG_City MPG_Highway Weight Wheelbase Length; 
run;

/*ex12-2 part3*/
proc factor data=sashelp.cars n=5 score;
	ods output StdScoreCoef=Coef;
	var MPG_City MPG_Highway Weight Wheelbase Length; 
run;

proc stdize method=ustd mult=0.44721 data=Coef
out=work.eigenvectors;
	Var Factor1-Factor5;
run;

proc printdata=work.eigenvectors; 
run;

/*ex12-3*/
Proc factor data=sashelp.cars corr priors=smc rotate=varimax;
	Var MPG_City MPG_Highway Weight Wheelbase Length; 
run;


/*ex12-4*/
proc factor data=sashelp.cars
	priors=smc
	rotate=varimax
	outstat=work.fact_cars score;
	var MPG_City MPG_Highway Weight Wheelbase Length; 
run;
proc score data = sashelp.cars
	score=work.fact_cars  out=work.Fscore; 			
	var MPG_City MPG_Highway Weight Wheelbase Length; 
run;
