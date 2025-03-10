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
libname saslib clear;
proc print data= saslib.service noobs;
run;
proc summary data=saslib.service;
	var servicelevel;
	output out=saslib.sumout n=n;
run;

data saslib.service_vw / view=saslib.service_vw;
	set saslib.service;
run;

data _null_;
	a= sqrt(4);
run;
data aa;
	a= sqrt(4);
run;

libname sashelp list;
libname _all_ list;

options obs=10;
title "数据集选项OBS=生效打印5条观测";
proc print data=sashelp.shoes (obs=5);
run;
title "系统选项OBS=生效打印10条观测";
proc print data=sashelp.shoes;
run;

libname saslib 'C:\Library\Applications\Typora\data\self-training\SAS\data' access=readonly;
proc print data= saslib.service noobs;
run;
data saslib.aa;
	set saslib.service;
	a= 1;
run;

proc options option=obs /*value*/;
run;
%put %sysfunc(getoption(obs));

*Do NOT edit below this line!;
/* Do NOT edit below this line! */
/***********************************************************
* PROGRAM SETUP
* Use this section to alter macro variables, options, or
* other aspects of the test. No Edits to this Program are
* allowed past the Program Setup section!!
***********************************************************/

libname saslib 'C:\Library\Applications\Typora\data\self-training\SAS\data';
data saslib.inventory;
	input Product_ID $ Instock Price;
	Cost=Price*0.15;
	N= _n_;
	put _n_;
	datalines;
P001R 12 125.00
P003T 34 40.00
P301M 23 500.00
PC02M 12 100.00
;
run;

filename invtfile 'C:\Library\Applications\Typora\data\self-training\SAS\data\inventory.dat';
data saslib.Inventory;
	infile invtfile;
	input Product_ID $ Instock Price;
run;
filename extfiles 'C:\Library\Applications\Typora\data\self-training\SAS\data';
data saslib.Inventory;
	infile extfiles(inventory);
	input Product_ID $ Instock Price;
run;

