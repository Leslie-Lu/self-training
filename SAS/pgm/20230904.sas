
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
	means Medicine / hovtest; /*hovtest, Requests a homogeneity of variance test*/
run;






/*example 11.4*/
ods graphics on;
proc glm data = ex.ReliefTime ; 
	class Medicine; 
	model Hours = Medicine; 
	lsmeans Medicine/pdiff = All ;
run;

/*example 11.5*/
proc means data = sashelp.class N mean ; 
	class age sex; 
	var height;
run;


proc glm data = sashelp.class; 
	class Age Sex; 
	model Weight = Age Sex Age*Sex; 
run;


/*example 11.6*/

data ex.fruit; 
	input humidity $ temperature $ output_lbs @@; 
	datalines; 
	A1 B1 58.2 	A1 B1 52.6
	A1 B2 56.2 	A1 B2 41.2
 	A1 B3 65.3 	A1 B3 60
	A2 B1 49.1 	A2 B1 42.8
	A2 B2 54.1 	A2 B2 50.5
 	A2 B3 51.6 	A2 B3 48.4
	A3 B1 60.1	A3 B1 58.3
	A3 B2 70.9	A3 B2 73.2
 	A3 B3 39.2	A3 B3 40.7
; 
run;


proc glm data = ex.fruit; 
	class humidity temperature; 
	model output_lbs = humidity temperature 
             humidity*temperature;
run;

