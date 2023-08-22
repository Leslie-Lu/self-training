
/*libname ex "\\scnwex\Book\Data";*/

***Ex 15.1****;
ods graphics /reset=all imagemap;

title "Correlations and Scatter plots with Revenue";
proc corr data=ex.retail rank plots(only)=scatter(ellipse=none nvar=all) ;
	var Member Square Inventory Loyalty Population Tenure;
	with Revenue;
	ID StoreID;
run;

***Ex 15.2****;
ods graphics /reset=all ;
title "Correlations and Scatter Plot Matrix of Revenue Predictors";
proc corr data=ex.retail nosimple plots=matrix(histogram nvar=all) ;
	var Member Square Inventory Loyalty Population Tenure;
run;

proc corr data=ex.retail nosimple plots=scatter(nvar=all) ;
	var Member Square Inventory Loyalty Population Tenure;
run;

***Ex 15.3***;

title "Predicting Revenue from Square";
proc reg data=ex.retail;
	model Revenue=Square//*clm cli*/ influence;
run;
quit;

title "Predicting Revenue from Square";
proc reg data=ex.retail plots(only)=(QQ REsidualbypredicted);
	model Revenue=Square;
	id StoreID;
run;
quit;

***Ex 15.4***;

data work.Need_Predictions;
	input Square @@;
	datalines;
30 40 50 60 70
;
run;

proc reg data=ex.retail noprint outest=work.Betas;
	PreRev: model Revenue=Square;
run;
quit;

title "OUTEST= Data Set from PROC REG";
proc print data=work.Betas;
run;

proc score data=work.Need_Predictions score=work.Betas
			out=Scored type=parms;
	var Square;
run;

title "Score New Observations";
proc print data=Scored;
run;

***Ex 15.5***;

ods graphics / reset=all imagemap=on;
title "Best Models Using All-Regression Option";
proc reg data=ex.retail plots(only)=(rsquare adjrsq cp);
	ALL_REG: model Revenue=Member Square Inventory Loyalty Population Tenure
			 / selection=rsquare adjrsq cp;
run;
quit;

ods graphics / reset=all imagemap=on;
title "Best Models Using All-Regression Option";
proc reg data=ex.retail plots(only)=(cp);
	ALL_REG: model Revenue=Member Square Inventory Loyalty Population Tenure
			 / selection=cp rsquare adjrsq best=15;
run;
quit;

ods graphics / reset=all imagemap=on;
title "Best Models Using All-Regression Option";
proc reg data=ex.retail plots(only)=(cp);
	ALL_REG: model Revenue=Member Square Inventory Loyalty Population Tenure
			 / selection=rsquare adjrsq best=15;
run;
quit;

title 'Check "Best" Two Candidate Models';
proc reg data=ex.retail ;
	Predict: model Revenue= Square ;
	Explain: model Revenue= Square Inventory;
run;
quit;

***Ex 15.6***;
title "Best Models Using Stepwise Selection";
proc reg data=ex.retail plots(only)=adjrsq;
	forward: model Revenue=Member Square Inventory Loyalty Population Tenure/ selection=forward;
	backward: model Revenue=Member Square Inventory Loyalty Population Tenure/ selection=backward;
	stepwise: model Revenue=Member Square Inventory Loyalty Population Tenure/ selection=stepwise;
run;
quit;

***Exx15.7****;

title "Collinearity - Full Model";
proc reg data=ex.retail;
	fullmodel: model Revenue=Member Square Inventory Loyalty Population Tenure/ vif;
run;
quit;

proc reg data=ex.retail;
	fullmodel: model Revenue=/*Member*/ Square Inventory Loyalty Population Tenure/ vif;
run;
quit;

proc reg data=ex.retail;
	fullmodel: model Revenue=/*Member*/ Square Inventory Loyalty Population /*Tenure*// vif;
run;
quit;









		






