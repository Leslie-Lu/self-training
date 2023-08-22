libname ex "\\scnwex\Book\Data";

******4.1******;
data work.New_Employee;
	input Emp_ID $ Emp_Name $ @@;
	datalines;
ET001 Jimmy ED003 Emy EC002 Alfred EQ004 Kim
;
run;
data work.Old_Employee;
	input Emp_ID $ Emp_Name $ @@;
	datalines;
EQ122 Molly ET121 Dillon ET124 Helen ED123 John
;
run;
data work.Employee;
	set work.Old_Employee work.New_employee;
run;
proc print data=work.Old_Employee;
	title 'Old Employee';
run;
proc print data=work.New_Employee;
	title 'New Employee';
run;
proc print data=work.Employee;
	title 'All Employee';
run;

*******4.2******;
data work.New_Employee_Dept;
	set work.New_Employee;
	if substr(Emp_ID,2,1)="T" then
		Dept="TSG";
	else if substr(Emp_ID,2,1)="Q" then
		Dept="QSG";
	else if substr(Emp_ID,2,1)="D" then
		Dept="DSG";
	else if substr(Emp_ID,2,1)="C" then
		Dept="CSG";
run;
data work.Old_Employee_Gen;
	set work.Old_Employee;
	if mod(substr(Emp_ID,length((trim(Emp_ID))),1),2)=0 then
		Gender="F";
	else Gender="M";
run;
data work.Employee_Update;
	set work.Old_Employee_Gen work.New_employee_Dept;
run;
proc print data=work.Employee_Update;
	title 'All Employee Update';
run;
******4.3*****;
proc sort data=work.New_Employee_Dept;
	by Emp_ID;
run;
proc sort data=work.Old_Employee_Gen;
	by Emp_ID;
run;
data work.Employee_Int;
	set work.Old_Employee_Gen  work.New_Employee_Dept;
	by Emp_ID;
run;
proc print data=work.Employee_Int;
	title 'All Employee Interleaving by ID';
run;

*****4.4*****;
data work.Employee;
	length Emp_ID $15;
	set work.New_Employee work.Old_employee;
	by  Emp_ID;
run;

*****4.5******;
proc contents data=ex.jmp_staff varnum;
run;
proc contents data=ex.rnd_staff varnum;
run;

data work.All_Staff;
	set ex.JMP_Staff (rename=(Employee_ID=Emp_ID))
	     ex.RnD_Staff;
run;

****4.6*****;
proc append base=Old_Employee_Gen data=New_Employee_Dept FORCE;
run;
****4.7*****;
data work.staff;
	infile datalines dsd;
	length emp_name $20 title $15;
	input emp_name $ title $;
	datalines;
Jacob Adams,Analyst
Emily Anderson,Analyst
Michael Arnold,Senior Analyst
Hannah Baker,Manager
Joshua Carter,Senior Analyst
;
data work.time;
	input time date9. room $11-24;
	format time date9.;
	datalines;
01Dec2013 Meeting Room 1
02Dec2013 Meeting Room 2
03Dec2013 Meeting Room 1
03Dec2013 Meeting Room 2
04Dec2013 Meeting Room 3
04Dec2013 Meeting Room 1
;
run;
options mergenoby=error;
data work.schedule;
	merge staff time;
run;
proc print data= work.schedule;
	title "Schedule for Performance Management";
run;

****4.8*****;
proc sort data=ex.staff_personel out=work.staff_personel;
	by Emp_ID;
run;
proc sort data=ex.sales_current_month out=work.sales_current_month;
	by Emp_ID;
run;
data work.Staff_sales;
	merge work.staff_personel work.sales_current_month;
	by    Emp_ID;
run;
proc print data=work.Staff_sales noobs;
	title'Staff Sales';
run;

******4.9*****;
proc sort data=ex.staff_personel out=work.staff_personel;
	by Emp_id;
run;
proc sort data=ex.sales_three_month out=work.sales_three_month;
	by Emp_id;
run;
data work.staff_report;
	merge work.staff_personel work.sales_three_month;
	by    Emp_id;
run;
proc print data=work.staff_personel noobs;
	title "Staff Information";
run;
proc print data=work.sales_three_month Fexnoobs;
	title "Sales For Three Months";
run;
proc print data=work.staff_report noobs;
	title "Staff Report";
run;

****;
data work.Data1;
	input x y ;
	datalines;
1 2
1 3
2 4
3 5
;
run;
data work.Data2;
	input x z ;
	datalines;
1 3
1 4
1 4
2 1
2 3
4 4
;
run;
data work.Combined;
	merge work.Data1 work.Data2;
	by x;
run;
proc print data=work.Combined noobs;
	title 'After Merging';
run;
*************;
data work.Staff_sales;
	merge work.staff_personel           (IN=a)
		work.sales_current_month      (IN=b);
	by    Emp_ID;
	ina=a;
	inb=b;
run;
proc print data=work.Staff_sales noobs;
	title'Staff Sales';
run;

*****4.10*****;
data work.Customer;
	input Customer_ID $1-4  Name $ 6-19 Address $ 21-37 City $ 39-51 State $ 53-54;
	datalines;
C001 Jacob Adams    111 Clancey Court Chapel Hill   NC 
C002 Emily Anderson 1009 Cherry St.   York          PA 
C003 Michael Arnold 4 Shepherd St.    Vancouver     BC 
C004 Hannah Baker   Box 108           Milagro       NM 
;
run;
proc print data=work.Customer noobs;
	title "Customer - Master Data";
run;
data work.UpdateInfo;
	infile datalines missover;
	input Customer_ID $1-4  Name $ 6-19 Address $ 21-37 City $ 39-51 State $ 53-54;
	datalines;
C001                14 Bridge St.     San Francisco CA
C002 Emily Cooker   42 Rue Marston
C002                52 Rue Marston    Paris
C005 Jimmy Cruze    Box 100           Cary          NC 
;
run;
proc print data=work.UpdateInfo noobs;
	title "Update Information - Yearly Transaction Data";
run;
data work.Customer;
	update work.Customer work.UpdateInfo;
	by Customer_ID;
run;
proc print data=work.Customer noobs;
	title "Customer - Master Data Update";
run;

****4.11****;
data work.inventory;
	input Product_ID $ Instock Price;
	datalines;
P001R 12 125.00
P003T 34 40.00
P301M 23 500.00
PC02M 12 100.00
;
proc print data=work.inventory noobs;
	title "Warehouse Inventory";
run;
data work.inventory;
	modify work.inventory;
	price=price*1.15;
run;
proc print data=work.inventory noobs;
	title 'Price reflects 15% increase';
run;

****4.12*****;
data work.inventory2;
	input Product_ID $ Outstock;
	datalines;
P001R 12 
P001R 30
P001R 25 
P003T 34 
P301M 23 
;
proc print data=work.inventory noobs;
	title "Warehouse Inventory Inhouse";
run;
proc print data=work.inventory2 noobs;
	title 'Warehouse Inventory Overseas';
run;
data work.inventory;
	modify work.inventory work.inventory2;
	by      product_id;
	instock=instock+Outstock;
run;
proc print data=work.inventory noobs;
	title 'Total Inventory';
run;

****4.13**;
data work.sales;
	input Emp_ID $ Dept $ Sales Gender$;
	datalines;
ET001 TSG 100 M
ED001 DSG 200 F
ED001 DSG 135 M
EQ001 QSG 234 F
ET001 TSG 125 F
ET002 TSG 98 M
EQ002 QSG 100 M
EQ003 QSG 98 M
ED002 DSG 124 M
ET003 TSG 123 F
;
run;
proc print data=work.sales;
	title 'Sales';
run;
data work.total_sales;
	set work.sales END=last;
	total_sales+sales;
	if last then
		output;
	keep total_sales;
run;
proc print data=work.total_sales noobs;
	title 'Total Sales in Million';
run;
data work.total_sales;
	set work.sales END=last;
	retain total_sales 0;
	total_sales=total_sales+sales;
	if last then output;
	keep total_sales;
run;

*********;
data work.test;
	input x y $ @@;
	datalines;
1 A 1 A 1 B 2 B 2 C
;
run;
data work.try;
	set work.test;
	by x y;
	firstx=first.x;	lastx=last.x;
	firsty=first.y;	lasty=last.y;
run;
*********;


***4.14***;
proc sort data=work.sales;
	by Dept Gender;
run;
data work.sales_dept;
	set work.sales;
	by  Dept Gender;
	retain sales_by_dept;
	if  first.Gender then
		sales_by_dept=0;
	sales_by_dept=sales_by_dept+sales;

	if last.Gender;
	keep Dept Gender sales_by_dept;
run;
proc print data=work.sales_dept noobs;
	title 'Sales by Department by Gender';
run;

****4.15***;
data work.sample;
	do i=1 to total by 3;
		set work.whole point=i nobs=total;
		output;
	end;
	stop;
run;

***4.16*;
data work.DATA1;
	input x y @@;
	datalines;
1 2 2 3 3 4
;
run;
data work.DATA2;
	input x z @@;
	datalines;
1 3 3 5 4 2 5 4
;
run;
data work.Combined;
	set work.DATA1;
	set work.DATA2;
run;
proc print data=work.Combined;
	title 'Using Two Set in Data Step';
run;

***4.17**;
data work.class_expand;
	set sashelp.class(keep=name age);
	do i=1 to nobs;
		set sashelp.class(keep=name age rename=(name=nameolder age=ageolder)) nobs=nobs point=i;
		if age lt ageolder then
			output;
	end;
run;
proc sort data=work.class_expand;
	by name age ageolder nameolder;
run;
proc print data=work.class_expand;
	title "Students";
	by name age;
	id name age;
run;

****4.18***;
data work.sales;
	input Emp_ID $ Dept $ Sales Product_ID $;
	datalines;
ET001 TSG 100 P001
ED001 DSG 120 P001
ET001 TSG 50 P002
EC001 CSG 230 P004
EQ001 QSG 150 P003
ET001 TSG 210 P004
ET002 TSG 40 P002
ET003 TSG 150 P003
;
run;
data work.product;
	infile datalines dsd;
	length Product_ID $8 Product_Name Description $35;
	input Product_ID $ Product_Name $ Description $;
	datalines;
P001,ManufacturingIndustry Solutions,ManufacturingIndustry Solutions V2
P002,Logistics Solutions,Logistics Solutions V1
P003,Financial Service Solutions,Financial Service Solutions V3
P004,Insurance Solutions,Insurance Solutions V2
;
run;
data work.sales_description(drop=ErrorDesc)
	work.exception;
	length Product_ID $8 Product_Name Description $35;
	if _N_=1 then
		do;
			/*Define hash objective*/
			declare hash product_desc(dataset:"work.product");
			product_desc.definekey('Product_ID');
			product_desc.definedata('Product_Name','Description');
			product_desc.definedone();
			call missing(Product_ID,Product_Name,Description);
		end;
	set work.sales;
	/*Retrieve matching data*/
	rc=product_desc.find();
	if rc = 0 then
		output sales_description;
	else
		do;
			ErrorDesc="No Product Description";
			output  exception;
		end;
	drop rc;
run;

****4.19******;
data work.expected_profit;
	warehouse_id="VSC001";
	do i=1 to 1000;
		profit_margin=abs(rannor(1234567)*10);
		output;
	end;
	warehouse_id="VSC002";
	do i=1 to 1000;
		profit_margin=abs(rannor(173245)*10);
		output;
	end;
	warehouse_id="VSC003";
	do i=1 to 1000;
		profit_margin=abs(rannor(9999999)*10);
		output;
	end;
	drop i;
run;
proc sort data=work.expected_profit;
	by warehouse_id descending profit_margin;
run;
data work.warehouse_constraint;
	warehouse_id="VSC001";
	capacity=350;
	output;
	warehouse_id="VSC002";
	capacity=200;
	output;
	warehouse_id="VSC003";
	capacity=600;
	output;
run;
proc sort data=work.expected_profit;
	by descending profit_margin;
run;
data work.allocation;
	retain total_cars_before 1000;
	length warehouse_id $6;
	if _N_=1 then
		do;
			declare hash constraint(dataset: "work.warehouse_constraint");
			constraint.definekey('warehouse_id');
			constraint.definedata('capacity');
			constraint.definedone();
			call missing(warehouse_id,capacity);
		end;
	set work.expected_profit;
	rc = constraint.find();
	if rc = 0 and capacity>=1 and total_cars_before>=1 then
		do;
			capacity=capacity-1;
			total_cars_after=total_cars_before-1;
			rc=constraint.replace(key:warehouse_id, data: capacity);
			if rc=0 then
				do;
					output work.allocation;
					total_cars_before=total_cars_before-1;
				end;
			else put "Error: Replace capacity failed!";
		end;
	else if rc ne 0 then
		put "Error: Failed to find warehouse capacity!";
	keep warehouse_id capacity profit_margin total_cars_before total_cars_after;
run;

***end****;

