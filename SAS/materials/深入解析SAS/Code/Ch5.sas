/*libname ex "\\scnwex\Book\Data";*/


***5.1****;
proc print data=ex.sales_quarter1;
	title 'Ex.sales_quanter1';
	run;
proc print data=ex.sales_quarter1 obs='Observation Number';
	title 'Ex.sales_quanter1';
	run;
proc print data=ex.sales_quarter1 noobs;
	title 'Ex.sales_quanter1';
	run;

****5.2*****;
proc print data=ex.sales_quarter1;
	title 'Ex.sales_quanter1 with ID';
	id emp_id emp_name;
run;

****5.3****;
proc print data=ex.sales_quarter1 noobs;
	title 'Monthly Sales';
	var emp_id emp_name month sales amount;
	where month=2;
run;
proc print data=ex.sales_quarter1(where=( month=2)) noobs;
	title 'Monthly Sales';
	var emp_id emp_name month sales amount;
run;

proc print data=ex.sales_quarter1(firstobs=3);run;
proc print data=ex.sales_quarter1(obs=3);run;
proc print data=ex.sales_quarter1(firstobs=3 obs=2);run;

***5.4****;
proc print data=ex.sales_quarter1(firstobs=3 obs=5);
	title 'Observation: 3 to 5';
	var emp_id emp_name month sales amount;
run;
***5.5****;
proc print data=ex.sales_quarter1 noobs;
 	title 'Monthly Sales for Total';
	var emp_id emp_name month sales amount;
	where month=2;
	sum sales amount;
run;
***5.6****;
proc sort data=ex.sales_quarter1 out=work.sales_quarter1;
	by Emp_ID Month;
	run;
proc print data=work.sales_quarter1 noobs n='Sales Transactions' 'Total Sales Transactions';
	title 'Emp Monthly Sales for Total';
	var sales amount;
	where substr(emp_id,2,1)="T";
	sum sales amount;
	by  emp_id month;
run;

proc print data=work.sales_quarter1 noobs;
	title 'Emp Sales for Total';
	var sales amount;
	where substr(emp_id,2,1)="T";
	sum sales amount;
	by  emp_id month;
	id  emp_id month;
	sumby emp_id;
run;

****5.7*****;
proc print data=ex.sales_quarter1 noobs;
	title1 'Asia Pacific Acrea';
 	title3 'Monthly Sales Report';
	footnote1 'February Sales Total';
 	footnote2 'COMPANY CONFIDENTIAL';
	var emp_id emp_name month sales amount;
	where month=2;
	sum sales amount;
	run;

***5.8****;
proc print data=ex.sales_quarter1 noobs;
	title 'Using Formating';
	var emp_id emp_name month sales amount;
	where month=2;
	format amount dollar14.2;
run;

***5.9****;
proc print data=ex.sales_quarter1 label;
	title 'Using Formating and Label';
	var emp_id emp_name month sales amount;
	where month=2;
	format amount dollar14.2;
	label emp_id='员工工号' emp_name='员工姓名' Sales='销售数' Amount='销售金额';
	run;


***5.10***;
proc print data=ex.sales_quarter1 split='/' blankline=1;
	title 'Using Split and Adding blank line';
	var emp_id emp_name month sales amount;
	where month=2;
	format amount dollar14.2;
	label emp_id='员工/工号' emp_name='员工/姓名' Sales='销售数' Amount='销售/金额';
	run;


****TABULATE****;

***5.11*****;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales in North America';
	title2 'Trancations in Each State';
	class state;
	table state;
run;

****;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales in North America';
	title2 'Trancations in Each State';
	class state/missing;
	table state;
run;

****5.12****;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales in North America';
	title2 'Total Amount Sold in Each State';
	class state;
	var amount;
	table state,amount;
run;
****5.13***;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales in North America';
	title2 'Total Amount Sold in Each State for Each Type';
	class state type;
	var amount;
	table type,state,amount;
run;

proc tabulate data=ex.sales_halfyear;
	title1 'Sales in North America';
	title2 'Total Amount Sold in Each State';
	class state;
	var amount;
	table amount,state;
run;

****5.14****;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales in North America';
	title2 'Total Transactions';
	class state month;
	table state month;
	run;

****5.15****;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales in North America';
	title2 'Total Amount Sold For Each Type In Each State';
	class state type;
	var   amount;
	table type*state,amount;
	run;

*****5.16*****;
proc tabulate data=ex.sales_halfyear;
	title 'Type*State All';
	class state type;
	var    amount;
	table type*state all,amount;
	run;
proc tabulate data=ex.sales_halfyear;
	class state type;
	var    amount;
	title 'Type*(State All)';
	table type*(state all),amount;
	run;

proc tabulate data=ex.sales_halfyear;
	class state type;
	var    amount;
	title 'Type*(State All)';
	table (type all)*(state all),amount;
	run;

****5.17****;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales Report in North America';
	class state type;
	var    Amount;
	table type*state all,amount*n amount*mean amount;
	run;

****5.18****;
proc tabulate data=ex.sales_halfyear;
	title1 'Sales Report in North America';
	class state type;
	var   amount;
	table type='产品类型'*state all='汇总',amount=''*(n mean sum);
	label state='州';
	run;

***5.19****;
proc tabulate data=ex.sales_halfyear;
	title1 '北美销售概况';
	title2 '产品类型和季度角度分析';
	class state type;
	var   amount;
	table type='产品类型'*state all='汇总',amount=''*(n='销售次数' mean='平均销售金额' sum='销售金额之和');
	label state='州';
run;

***5.20****;
proc format;
	Value quarter
		1-3='季度1'
		4-6='季度2'
		7-9='季度3'
		10-12='季度4';
	run;
proc tabulate data=ex.sales_halfyear;
	title1 '北美销售概况';
	title2 '产品类型和季度角度分析';
	class type month ;
	var   amount;
	table  type='产品类型'*(month all='半年汇总') all='汇总' ,amount=''*(n mean='平均销售金额' sum='销售金额之和');
	format month quarter.;
	keylabel n='销售次数';
	run;

****formats****;
proc format;
	value $gender
		‘M’='Male'
		‘F’='Female'
		Other='Wrong Code';
	run;
proc format;
	value $grade
		Low-59='Under Grade'
		60-80='Average'
		81-90='Good'
		91-High='Excellent';
	run;

****5.21****;
proc tabulate data=ex.sales_halfyear;
	title1 '北美销售概况';
	title2 '产品类型和季度角度分析';
	class type month;
	var   amount;
	table  type='产品类型'*(month all='半年汇总') all='汇总',amount=''*(n='销售次数' mean='平均销售金额'*f=dollar12.2 sum='销售金额之和' *f=dollar12.2);
	format month quarter.;
	run;

*******;
proc tabulate data=ex.sales_halfyear missing;
	title1 'Sales in North America';
	title2 'Trancations in Each State';
	class state;
	class Emp_ID;
	table state;
run;

proc tabulate data=year_sales format=comma10.;
class SalesRep;
class Month Quarter / missing;
var AmountSold;
******;

******GPLOT*****;

***5.22***;
proc gplot data=ex.sales_year;
	title 'Yearly Amount in North America';
	plot N_Amount*Year;
	run;
	quit;

***5.23****;
symbol value=dot cv=red;
proc gplot data=ex.sales_year;
	title f='Albany Amt' c=blue h=3 u=2 'Yearly Amount in North America';
	footnote j=r 'Optimization Solution Co. Ltd';
	plot N_Amount*Year;
	run;
	quit;
goptions reset=all;

symbol value=dot cv=red
	   interpol=join ci=blue;
proc gplot data=ex.sales_year;
	title 'Yearly Amount in North America';
	plot N_Amount*Year;
	run;
	quit;
goptions reset=all;


symbol value=dot cv=red
	   interpol=join ci=blue;
proc gplot data=ex.sales_year;
	title 'Yearly Amount in North America';
	plot N_Amount*Year/haxis=1990 to 2012 by 5;
	run;
	quit;
goptions reset=all;

****5.24*****;
axis1  order=(1990 to 2012 by 5) 
	   minor=(color=blue number=1);
axis2  order=(13000 to 20000 by 1000)
	   minor=(color=blue height=0.25 number=1);
symbol value=dot cv=red
	   interpol=join ci=blue;
proc gplot data=ex.sales_year;
	title 'Yearly Amount in North America';
	plot N_Amount*Year/haxis=axis1 vaxis=axis2;
	run;
	quit;
goptions reset=all;

****5.25*****;
axis1  order=(1990 to 2012 by 5) 
	   minor=(color=blue number=1);
axis2  order=(13000 to 20000 by 1000)
	   minor=(color=blue height=0.25 number=1);
symbol value=dot cv=red
	   interpol=join ci=blue;
proc gplot data=ex.sales_year;
	title 'Yearly Amount Series';
	plot N_Amount*Year E_Amount*Year/haxis=axis1 vaxis=axis2;
	run;
	quit;
goptions reset=all;

****5.26*****;
axis1  order=(1990 to 2012 by 5) 
	   minor=(color=blue number=1);
axis2  order=(13000 to 20000 by 1000)
	   minor=(color=blue height=0.25 number=1);
symbol1 value=dot cv=red
	   interpol=join ci=red;
symbol2 value=# cv=green interpol=join ci=green line=4;
proc gplot data=ex.sales_year;
	title 'Yearly Amount Series';
	plot N_Amount*Year E_Amount*Year/overlay legend haxis=axis1 vaxis=axis2;
	run;
	quit;
goptions reset=all;

****5.27*****;
axis1  order=(1990 to 2012 by 5) 
	   minor=(color=blue number=1);
axis2  order=(13000 to 20000 by 1000)
	   minor=(color=blue height=0.25 number=1);
axis3  major=(number=8)
       minor=(number=1);
symbol1 value=dot cv=red
	   interpol=join ci=red;
symbol2 value=diamond cv=green height=2 interpol=join ci=green line=10;
proc gplot data=ex.sales_year;
	title 'Yearly Amount Series';
	plot N_Amount*Year /legend haxis=axis1 vaxis=axis2;
	plot2 N_Transations*Year/legend vaxis=axis3;
	run;
	quit;
goptions reset=all;

*****5.28*****;
axis1  order=(1990 to 2012 by 5) 
	   minor=(color=blue number=1);
axis2  minor=(color=blue height=0.25 number=1);
symbol value=: height=2 interpol=join;
proc gplot data=ex.sales_year_by_area;
	title 'Yearly Amount Series By Area';
	plot Amount*Year=Area/haxis=axis1 vaxis=axis2 ;
	run;
	quit;
goptions reset=all;

*******5.29*******;
axis1  order=(1990 to 2012 by 5) 
	   minor=(color=blue number=1);
axis2  minor=(color=blue height=0.25 number=1);
legend1 cborder=blue cshadow=lightblue across=2 position=(bottom center) 
	   label=(color=lightpurple height=1.5 font='Courier New' 'Global');
symbol value=: height=2 interpol=join;
proc gplot data=ex.sales_year_by_area;
	title 'Yearly Amount Series By Area';
	plot Amount*Year=Area/haxis=axis1 vaxis=axis2 legend=legend1;
	run;
	quit;
goptions reset=all;

**************;

*****5.30*****;
axis2  minor=(color=blue height=0.25 number=1);
proc gplot data=ex.sales_year;
	title 'Yearly Sales Overview';
	bubble E_Amount*Year=E_Transactions/vaxis=axis2
										bcolor=red bsize=12;
	where year>=1999;
	run;
	quit;
goptions reset=all;

****5.31****;
proc gchart data=ex.sales_halfyear;
	title 'Monthly Transaction Summary';
	vbar state;
	vbar3d state;
	hbar state;
	hbar3d state;
	run;
	quit;
goptions reset=all;

***5.32****;
proc gchart data=ex.sales_halfyear;
	title 'Monthly Transaction Summary';
	vbar month/discrete ;
	vbar month/level=2 range;
	vbar month/midpoints=1 to 6 by 2;
	run;
	quit;
goptions reset=all;

***5.33****;
proc gchart data=ex.sales_halfyear;
	title 'Sales Summary Across State';
	hbar state/sumvar=amount type=sum descending;
	run;
	quit;
goptions reset=all;

***5.34****;
proc gchart data=ex.sales_halfyear;
	title 'Sales Summary Across State';
	hbar state/sumvar=amount 
			   type=sum descending
               sum mean;
	run;
	quit;
goptions reset=all;

****5.35*****;
proc gchart data=ex.sales_halfyear;
	title 'Sales Summary Across State';
	vbar state/sumvar=amount 
			   type=sum 
               outside=sum inside=pct 
               width=10;
	format amount dollar10.2;
	run;
	quit;
goptions reset=all;

****5.36*****;
goptions colors=(verylightred verylightgreen verylightorange 
				 verylightpurple);
pattern1 c=lightred;
pattern2 c=lightgreen;
pattern3 c=lightblue;
pattern4 c=lightpurple;

proc gchart data=ex.sales_halfyear;
	title 'Sales Summary Across State';
	vbar state/sumvar=amount 
			   type=sum 
               outside=sum inside=pct 
               width=10 patternid=midpoint ;
	format amount dollar10.2;
	run;
	quit;
goptions reset=all;

**********;

proc gchart data=ex.sales_halfyear;
	title 'Sales Summary Across State';
	vbar state/sumvar=amount 
			   group=type;         
	vbar state/sumvar=amount
	           subgroup=type;
	run;
	quit;
goptions reset=all;

*********;
proc gchart data=ex.sales_halfyear;
	title 'Sales Summary Across State';
	vbar state/sumvar=amount 
			   group=type patternid=group;         
	vbar state/sumvar=amount
	           subgroup=type;
	run;
	quit;
goptions reset=all;

************;

*****5.37*****;
axis1  order=(0 to 4000 by 1000)
	   major=(height=2 ) 
	   minor=(color=blue number=2 height=0.5)
	   label=(color=blue height=2 'Total Amount');
axis2  label=(color=verylightblue height=1.5 'State Across America');
axis3  label=(color=lightblue height=2 'Product Type');
proc gchart data=ex.sales_halfyear;
	title 'Sales Summary Across State';
	vbar state/sumvar=amount 
			   group=type patternid=group 
			   raxis=axis1 
	           maxis=axis2
   			   gaxis=axis3;   
	run;
	quit;
goptions reset=all;

****5.38****;
proc gchart data=ex.sales_halfyear;
	title 'Sales Percentage';
	pie emp_name/sumvar=amount type=pct
			     group=type ;         
	run;
	quit;
goptions reset=all;

******ods********;
proc contents data=sashelp.class;
	run;

ods listing close;
ods trace on/ label;
proc contents data=sashelp.class;
	run;
ods trace off;


****5.39****;

ods listing;
/*modify OVERALL selection list*/
ods select moments;
/*modify HTML selection list*/
ods html select Quantiles;
proc univariate data=sashelp.prdsale;
	var actual;
	run;
ods listing close;

*****5.40****;

ods html close;
ods rtf file="C:\Users\vdmrace\Desktop\data\prdsale.rtf" style=science;
ods rtf select moments quantiles;

proc univariate data=sashelp.prdsale;
	var actual;
	run;

proc gchart data=sashelp.prdsale;
	hbar country /group=prodtype sumvar=actual
				  patternid=group;
	run;
	quit;

ods rtf close;
ods html;

***5.41****;

proc sort data=sashelp.prdsale out=prdsale;
	by country;
	run;

ods html close;
ods pdf file="C:\Users\vdmrace\Desktop\data\prdsale.pdf";

proc univariate data=prdsale;
	by country;
	var actual;
	run;

ods pdf close;
ods html;

****5.42*****;

proc sort data=sashelp.prdsale out=prdsale;
	by country;
	run;
ods html path='C:\Users\vdmrace\Desktop\data' 
         body='prdsalebody.html'
		 frame='prdsaleframe.html'
		 contents='prdsalecontents.html';

proc tabulate data=prdsale; 
	class region division prodtype; 
	var actual; keyword all sum; 
	keylabel all='Total'; 
	table (region all)*(division all), 
			(prodtype all)*(actual*f=dollar10.) / misstext=[label='Missing'] 
												box=[label='Region by Division and Type'];
    run;

ods select ExtremeObs Quantiles Moments;
proc univariate data=prdsale; 
	by Country; 
	var actual;
	run;

ods html close;

****5.43*****;

proc sort data=sashelp.prdsale out=prdsale;
	by country;
	run;
ods html path='C:\Users\vdmrace\Desktop\data' 
         body='prdsalebody.html'
		 frame='prdsaleframe.html'
		 contents='prdsalecontents.html' newfile=proc
         ;

proc tabulate data=prdsale; 
	class region division prodtype; 
	var actual; keyword all sum; 
	keylabel all='Total'; 
	table (region all)*(division all), 
			(prodtype all)*(actual*f=dollar10.) / misstext=[label='Missing'] 
												box=[label='Region by Division and Type'];
    run;

ods select ExtremeObs Quantiles Moments;
proc univariate data=prdsale; 
	by Country; 
	var actual;
	run;

ods html close;

***5.44*****;
ods output ExtremeObs=work.ExtremeObs Moments=work.Moments ;
proc univariate data=sashelp.prdsale; 
	var actual predict;
	run;
ods output close;


ods trace on;
proc print data=sashelp.prdsale(obs=10);
run;
ods trace off;

***5.45****;
ods output ExtremeObs(match_all=esets) =work.ExtremeObs Moments(match_all=msets) =work.Moments;
proc univariate data=sashelp.prdsale; 
	var actual predict;
	run;
ods output close;
%put esets=&esets.  Msets=&msets.;

***5.46****;
proc sort data=sashelp.prdsale out=prdsale;
	by country;
	run;

ods document name=work.prddocuments(write);

proc tabulate data=prdsale; 
	class region division prodtype; 
	var actual; keyword all sum; 
	keylabel all='Total'; 
	table (region all)*(division all), 
			(prodtype all)*(actual*f=dollar10.) / misstext=[label='Missing'] 
												box=[label='Region by Division and Type'];
    run;

ods select ExtremeObs Quantiles Moments;
proc univariate data=prdsale; 
	by Country; 
	var actual;
	run;

ods document close;


