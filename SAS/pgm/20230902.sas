/*libname saslib 'c:\sas\data';*/
data work.Inventory;
	input Product_ID $ Instock Price;
	datalines;
	P001R 12 125.00
	P003T 34 40.00
	P301M 23 500.00
	PC02M 12 100.00
;
run;
proc contents data= work.inventory;
run;
proc print data= work.inventory /*noobs*/;
run;

data sales;
	infile datalines dsd missover;
	input Emp_ID $ Dept $ Sales Date;
	format Sales COMMA10. Date yymmdd10.;
	informat Date date9. sales dollar8.;
	label Emp_ID="员工ID" Dept="部门" Sales="销售数据";
	label Date="销售时间";
	datalines;
ET001,TSG,$10000,01JAN2012
ED002,,$12000,01FEB2012
ET004,TSG,$5000,02MAR2012
EC002,CSG,$23000,01APR2012
ED004,QSG,,01AUG2012
;
run;
proc contents data=sales;
run;
proc print data=sales noobs /*label*/;
run;

libname saslib 'C:\Library\Applications\Typora\data\self-training\SAS\data';
proc print data= saslib.service noobs;
run;
proc summary data=saslib.service;
	var servicelevel;
	output out=saslib.sumout n=n;
run;

