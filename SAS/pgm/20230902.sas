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