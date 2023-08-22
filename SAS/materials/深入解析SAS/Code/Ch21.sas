
***ex 21.1***;
proc optmodel;
	/*declare variables*/
	var Croissant>=0,Toast>=0,Baguette>=0,Cookie>=0;
	/*declare constraints*/
	con Flour: 3*Croissant+3*Toast+4*Baguette+3.5*Cookie<=130;
	con Cream: 2*Croissant+1.5*Toast+0.5*Baguette+2*Cookie<=60;
	con Butter: 2*Croissant+Toast+Baguette+Cookie<=40;
	/*declare objective*/
	max Profit=440*Croissant+330*Toast+315*Baguette+385*Cookie
		-20*(3*Croissant+3*Toast+4*Baguette+3.5*Cookie)
		-40*(2*Croissant+1.5*Toast+0.5*Baguette+2*Cookie)
		-35*(2*Croissant+Toast+Baguette+Cookie);
	solve;
	expand;
	/*print solution*/
	print Croissant Toast Baguette Cookie;
quit;

proc optmodel;
	/*declare variables*/
	var Croissant>=0,Toast>=0,Baguette>=0,Cookie>=0;
	impvar Kilos = 3*Croissant+3*Toast+4*Baguette+3.5*Cookie;
	impvar Bottles=2*Croissant+1.5*Toast+0.5*Baguette+2*Cookie;
	impvar Bags=2*Croissant+Toast+Baguette+Cookie;
	/*declare constraints*/
	con Flour: Kilos<=130,Cream: Bottles<=60,Butter: Bags<=40;
	/*declare objective*/
	max Profit=440*Croissant+330*Toast+315*Baguette+385*Cookie
		-20*Kilos-40*Bottles-35*Bags;
	solve;
	expand /impvar;
	/*print solution*/
	print Croissant Toast Baguette Cookie;
quit;

***ex 21.2****;

proc optmodel;
	set AREA=/'??' '??' '??' '??'/;
	set AGE=/'18-25?' '26-35?' '36-45?' '46-55?' '56????'/;
	num Target{AREA,AGE}=[1200 3200 2000 800 800
				1350 3600 2250 900 900
				5250 1400 8750 3500 3500
				1200 3200 2000 800 800];
	print Target;
quit;

*********;

*****ex 21.3********;

proc optmodel;
	/*declare sets and parameters*/
	set PRODUCT=/croissant toast baguette cookie/;  
	num Selling_Price{PRODUCT}=[440 330 315 385];  
	set RESOURCE=/flour cream butter/;               
	num Cost{RESOURCE}=[20 40 35];                 
	num Available{RESOURCE}=[130 60 40];           
	num Requirement{PRODUCT,RESOURCE}=[3 2 2
									  3 1.5 1
									  4 0.5 1
									  3.5 2 1];     

	/*declare variables*/
	var X{PRODUCT}>=0;               /*decision variables*/
	impvar Amount_Used{r in RESOURCE}=sum{p in PRODUCT}Requirement[p,r]*X[p]; /*implicit variables*/
	impvar Revenue=sum{p in PRODUCT}Selling_Price[p]*X[p];
	impvar Costing=sum{r in RESOURCE}Cost[r]*Amount_Used[r];

	/*declare constraints*/
	con Usage{r in RESOURCE}: Amount_Used[r]<=Available[r];

	/*declare objective*/
	max Profit=Revenue-Costing;

	expand / var impvar;
	expand Profit;
	expand Usage;

	/*call Solver*/
	solve obj Profit with lp/solver=ds;

	/*print Solution*/
	print {p in PRODUCT: X[p]>0} X ;
quit;

proc optmodel;
	num x = 4.3;
	var y{j in 1..4} init j*3.68;
	print y; /* identifier-expression */
	print (x * .265) dollar6.2; /* (expression) [format] */
	print {i in 2..4} y; /* {index-set} identifier-expression */
	print {i in 1..3}(i + i*.2345692) best7.;	/* {index-set} (expression) [format] */
	print "Line 1"; /* string */
quit;

proc optmodel;
	set R=1..6;
	set C=1..4;
	number a{i in R, j in C} = 10*i+j;
	print a;
quit;

proc optmodel;
	number a=1.7, b=2.8;
	set s={a,b};
	put a b; /* list output */
	put a= b=; /* named output */
	put 'Value A: ' a 8.1 @30 'Value B: ' b 8.; /* formatted */
	string str='Ratio (A/B) is:';
	put str (a/b); /* strings and expressions */
	put s=; /* named set output */
quit;

proc optmodel;
	number a=1.7, b=2.8;
	set s={a,b};
	put a b; 
	put a= b=; 
	put 'Value A: ' a 8.1 @30 'Value B: ' b 8.; 
	string str='Ratio (A/B) is:';
	put str (a/b); 
	put s=; 
quit;
***ex 21.4***;

proc print data=sashelp.zipcode(obs=4) label;
run;

proc optmodel;
	/*declare sets and parameters*/
	set <num> ZIPCODE;
	num Latitude{ZIPCODE},Longtitude{ZIPCODE};
	str City{ZIPCODE};

	/*read data from SAS data sets*/
	read data sashelp.zipcode(obs=5) into ZIPCODE=[zip] Longtitude=x Latitude=y City;

	put ZIPCODE=;
	print Longtitude Latitude City;
quit;

****;
data dmnd;
input loc $ day1 day2 day3 day4 day5;
datalines;
East 1.1 2.3 1.3 3.6 4.7
West 7.0 2.1 6.1 5.8 3.2
;
run;

/*Example 1*/
data indata;
	input j k;
datalines;
1 2
;
proc optmodel;
	num j,k;
	read data indata into j k;
	put j= k=;
quit;

/*Example 2*/
data work.invdata;
	input item $ invcount;
datalines;
table 100
sofa 250
chair 80
;
proc optmodel;
	set<string> ITEMS;
	number Invcount{ITEMS};
	read data work.invdata into ITEMS=[item] Invcount;
	print invcount;
quit;


/*Example 3*/
data work.exdata;
input column1 column2;
datalines;
1 2
3 4
;
proc optmodel;
	number n init 2;
	set<num> indx;
	number p{indx}, q{indx};
	read data work.exdata into
	indx=[_N_] p=column1 q=col("column"||n);
	print p q;
quit;

/*Example 4*/
data work.dmnd;
input loc $ day1 day2 day3 day4 day5;
datalines;
East 1.1 2.3 1.3 3.6 4.7
West 7.0 2.1 6.1 5.8 3.2
;
proc optmodel;
	set DOW = 1..5; /* days of week, 1=Monday, 5=Friday */
	set<string> LOCS; /* locations */
	number demand{LOCS, DOW};
	read data work.dmnd
	into LOCS=[loc]
	{d in DOW} < demand[loc, d]=col("day"||d) >;

/*	read data work.dmnd into LOCS=[loc]*/
/*		demand[loc,1]=day1 */
/*		demand[loc,2]=day2*/
/*		demand[loc,3]=day3*/
/*		demand[loc,4]=day4*/
/*		demand[loc,5]=day5;*/
	print demand;
quit;

*****Ex 21.5****;

proc optmodel;
	/*declare sets and parameters*/
	set <str> PRODUCT, RESOURCE;
	num Cost{RESOURCE},Available{RESOURCE};
	num Selling_Price{PRODUCT};
	num Requirement{PRODUCT,RESOURCE};

	/*read data from SAS data sets*/
	read data work.resource_data into RESOURCE=[Res] Cost Available=Amount;
/*	read data work.resource_data into RESOURCE=[Res] Cost[Res]=Cost Available[Res]=Amount;*/

	read data work.product_data into PRODUCT=[prod] Selling_Price {r in RESOURCE}<Requirement[prod,r]=col(r)>;

	print Cost dollar. Available;
	print Selling_Price dollar. Requirement;
quit;

****Ex 21.6*****;
data work.inventory;
	input pkg $ colr $ inventory;
	datalines;
Excelle Yellow 20
Excelle Grey 30
Excelle Black 40
Excelle Blue 10
Malibu Red 30
Malibu White 30
Malibu Grey 20
;
run;
proc optmodel;
	/*declare sets and parameters*/
	set <str,str> PACKAGE_COLOR;
	num Initinv{PACKAGE_COLOR};

	/*read data from SAS data sets*/
	read data work.inventory into PACKAGE_COLOR=[pkg colr] Initinv=inventory;

	put PACKAGE_COLOR=;
	print Initinv;
quit;

proc optmodel;
	set <num> INDX=1..10;
	num sq{i in INDX} = i*i;
	create data work.squares from [Obs=INDX/format=hex2./length=3] sequence=sq/format=6.2;
run;
proc print data=work.squares;
run;

****Ex 21.7****;
data work.resource_data;
	input Res $ cost Amount;
	datalines;
flour 20 130
cream 40  60
butter 35 40
;
run;

data work.product_data;
	length prod $9;
	input prod $ Selling_Price flour cream butter;
	datalines;
croissant 440 3 2 2 
toast 330 3 1.5 1
baguette 315 4 0.5 1
cookie 385 3.5 2 1
;
run;

proc optmodel;
	/*declare sets and parameters*/
	set <str> PRODUCT, RESOURCE;
	num Cost{RESOURCE},Available{RESOURCE};
	num Selling_Price{PRODUCT};
	num Requirement{PRODUCT,RESOURCE};

	/*read data from SAS data sets*/
	read data work.resource_data into RESOURCE=[Res] Cost Available=Amount;
	read data work.product_data into PRODUCT=[prod] Selling_Price {r in RESOURCE}<Requirement[prod,r]=col(r)>;

	/*declare variables*/
	var X{PRODUCT}>=0;               /*decision variables*/
	impvar Amount_Used{r in RESOURCE}=sum{p in PRODUCT}Requirement[p,r]*X[p]; /*implicit variables*/
	impvar Revenue=sum{p in PRODUCT}Selling_Price[p]*X[p];
	impvar Costing=sum{r in RESOURCE}Cost[r]*Amount_Used[r];

	/*declare constraints*/
	con Usage{r in RESOURCE}: Amount_Used[r]<=Available[r];

	/*declare objective*/
	max Profit=Revenue-Costing;

	/*call Solver*/
	solve obj Profit with lp/solver=ds;

	/*create data sets*/
	create data work.opt_solution from [Products]={p in PRODUCT: X[p]>0} Volume_Produced=X 
				Profit= (Selling_Price[p]*X[p] - sum{r in RESOURCE}Cost[r]*Requirement[p,r]*X[p])/format=comma8.;
	create data work.resource_usage from [Resources]={r in RESOURCE} Amount_Used[r] 
				TotalCost=(Cost[r]*Amount_Used[r])/format=comma8. Usage=(Amount_Used[r]/Available[r]) /format=percent10.2;
quit;

proc print data= work.opt_solution;
run;
proc print data= work.resource_usage;
run;

