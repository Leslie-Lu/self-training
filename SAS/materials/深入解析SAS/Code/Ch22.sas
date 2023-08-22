proc optmodel; 
	number i; 
	do i =1, 3, 5; 
	    put i; 
	end;
quit;


proc optmodel; 
	number i; 
	set S = {1, 3, 5}; 
	do i = S; 
	    put i; 
	end; 
quit;


proc optmodel;
	number i; 
	set S = {1, 3, 5}; 
	    do i = S while (i ne 5); 
	    put i; 
	end; 
quit;


proc optmodel;
	number i; 
	do i = 1 to 5 by 2; 
	     put i; 
	end;
quit;


proc optmodel;	
	set FROM = {'NYC', 'NJ', 'Boston'}; 
	string origin;
	do origin = FROM; 
	    put origin;
	end;
quit;


proc optmodel; 
	number i ; 
	i =1; 
	do until(i=3); 
	    put i; 
	    i = i+1; 
	end;
quit;


proc optmodel; 
	number i ; 
	i =1;
	set A = {2, 5, 7}; 
	do until(i<3 and i IN A); 
	    put i; 
	    i = i+1; 
	end;
quit;


proc optmodel; 
	number i ; 
	i =1; 
	do while(i<3); 
	    put i; 
	    i = i+1; 
	end;
quit;


proc optmodel; 
	for {i in 1..2, j in {'a', 'b'}}
	put i = j =;
quit;


proc optmodel; 
	set <string> FROM = /'??', '???'/;
	set <string> START = / '??',  '??'/;

	for {s in START} do; 
	    if s in FROM 
 		then put s "is in the FROM"; 
	    else 
		put  s "is not in the FROM"; 
	end;
quit; 


proc optmodel;	
	put (and{i in 1..5} i<10);   *first put statement;
	put (and{i in 1..5} i NE 3); *second put statement;
quit;


proc optmodel;
	put (or{i in 1..5} i<3);   *first put statement;
	put (or{i in 1..5} i>6); *second put statement;
quit;


proc optmodel; 
	put (card(1..5));
quit;


proc optmodel; 
	set <string> ORIGIN= {'??', '??'}; 
	set <string> DESTINATION = {'??', '??', '??'};
	set<string, string> ROUTE = ORIGIN cross DESTINATION;
	put 'ROUTE is: ' ROUTE ;
quit;


proc optmodel;
	set<string> DESTINATION1 = {'??', '??', '??'};
	set<string> DESTINATION2 = {'??'};

	set<string> DESTINATION3 =DESTINATION1 diff DESTINATION2;
	put 'DESTINATION3 is: ' DESTINATION3;
quit;


proc optmodel;
	set<string> DESTINATION1 = {'??', '??', '??'};
	set<string> DESTINATION2 = {'??'};

	set<string> DESTINATION3 =DESTINATION1 inter  DESTINATION2;
	put 'DESTINATION3 is: ' DESTINATION3;
quit;


proc optmodel; 
	set<string> ORIGIN = {'??', '??'}; 
	set<string> ORIGIN2 = {'??', '??'}; 
	put (ORIGIN symdiff ORIGIN2);
quit; 


proc optmodel; 
	set<string> DESTINATION = {'??', '??', '??'};
	put('??' IN DESTINATION); 
	put('??' NOT IN DESTINATION);
quit;


proc optmodel;
	put (max{i in 2..5} 1/i); 
	put (min{i in 2..5} 1/i);
quit;


proc optmodel; 
	number n =5; 
	put(prod{i in 1..5} i);
quit;


proc optmodel; 
	set<string,string> ROUTE ={<'??','??'>,<'??','??'>,<'??','??'>,<'??','??'>,<'??','??'>,<'??','??'>};

	set <string> DESTINATION1 = slice(<'??', *>, ROUTE); 
	put DESTINATION1; *first put statement;

	set <string> DESTINATION2 = slice(<*, '??'>, ROUTE); 
	put DESTINATION2; *second put statement;

	put (slice(<*,2, *>, {<1, 2, 3>, <2, 3, 4>, <5, 2, 6>})); *third put statement;
quit;


proc optmodel; 
	set <string> ORIGIN1= {'??', '??'};
	set <string> ORIGIN2 = {'???','??'};
	put(ORIGIN1 UNION ORIGIN2);
quit;


proc optmodel; 
	set <string> ORIGIN1= {'??', '??'};
	set <string> ORIGIN2= {'??'};
	set <string> ORIGIN3= {'??', '??'};
	put (ORIGIN2 within ORIGIN1); *first put statement;
	put (ORIGIN3 within ORIGIN1); *second put statement;
	put (ORIGIN3 NOT within ORIGIN1); *third put statement;
quit;

proc optmodel; 
	set<str, str> ARCS =/ <??,??>, <??, ??>/;
	set<str> FROM = setof{<i, j> in ARCS}<i>;
	put FROM; 
quit;


proc optmodel; 
	put (setof{i in 1..3}<i, i*i, i**3>); 
quit;


/*example 22.1*/
proc optmodel; 
	var x>=3; 
	var y; 
	con c1: y<=4; 
	con c2: x+y<=7; 
	max f=x+2*y;
	solve with lp/presolver  = NONE; 
	solve with lp/presolver = automatic ; 
quit;


data product_data;
   	input Item $ Selling_Price  R1 R2  Labor;
   	datalines;
A 1100 7 3 1
B 1000 10 5 1
C 950 5 4 1
D 1000 1 3 6
run;	
data resource_data;
	input Resource $ Cost Amount_Available;
	datalines;
R1 10 1000
R2 6 850
Labor  8 1000
run;


/*example 22.2*/

proc optmodel;
   /* declare sets and parameters */
   set <str> PRODUCTS, RESOURCE;
   num Cost{RESOURCE}, Availability{RESOURCE};
   num Selling_Price{PRODUCTS};
   num Required{PRODUCTS, RESOURCE}; 

   /* read data from SAS data sets */
   read data resource_data into Resource=[Resource] 
     Cost Availability=Amount_Available;

   read data product_data into PRODUCTS=[Item]  
     {r in RESOURCE} <Required[item, r]=col(r)>
     Selling_Price;

	var x{PRODUCTS} >= 0;
	/*    for {i in ITEMS: i = 'A'} fix x[i] = 40;*/

	impvar Revenue = sum{p in PRODUCTS}Selling_Price[p]*x[p];
	impvar Amount_Used{r in RESOURCE} = sum{p in PRODUCTS} Required[p, r]*x[p];
	impvar Total_Cost = sum{r in RESOURCE} Cost[r]*Amount_Used[r];
	impvar Profit{p in PRODUCTS} = ( Selling_Price[p] -  sum{r in RESOURCE} Cost[r]*Required[p, r] ) * x[p];

	/* declare constraints */
	con Usage{r in RESOURCE}: Amount_Used[r] <= Availability[r];

	PRODUCTS = PRODUCTS union /E/;
    Selling_Price['E'] = 1000;
    Required['E', 'R1'] = 2; 
    Required['E', 'R2'] = 4; 
	Required['E', 'Labor'] = 3; 

	/* declare objective */
	max Net_Profit = Revenue - Total_Cost;

	solve ;
	print x;
quit;


/*example 22.3*/
proc optmodel;
   /* declare sets and parameters */
   set <str> PRODUCTS, RESOURCE;
   num Cost{RESOURCE}, Availability{RESOURCE};
   num Selling_Price{PRODUCTS};
   num Required{PRODUCTS, RESOURCE}; 

   /* read data from SAS data sets */
   read data resource_data into Resource=[Resource] 
     Cost Availability=Amount_Available;

   read data product_data into PRODUCTS=[Item]  
     {r in RESOURCE} <Required[item, r]=col(r)>
     Selling_Price;

	var x{PRODUCTS} >= 0;
	/*    for {i in ITEMS: i = 'A'} fix x[i] = 40;*/

	impvar Revenue = sum{p in PRODUCTS}Selling_Price[p]*x[p];
	impvar Amount_Used{r in RESOURCE} = sum{p in PRODUCTS} Required[p, r]*x[p];
	impvar Total_Cost = sum{r in RESOURCE} Cost[r]*Amount_Used[r];
	impvar Profit{p in PRODUCTS} = ( Selling_Price[p] -  sum{r in RESOURCE} Cost[r]*Required[p, r] ) * x[p];

	/* declare constraints */
	con Usage{r in RESOURCE}: 
	 Amount_Used[r] <= Availability[r];

	PRODUCTS = PRODUCTS union /E/;
    Selling_Price['E'] = 1000;
    Required['E', 'R1'] = 2; 
    Required['E', 'R2'] = 4; 
	Required['E', 'Labor'] = 3; 

	/* declare objective */
	max Net_Profit = Revenue - Total_Cost;

	fix x['B'] = 30;
	fix x['C'] = 40;

	solve ;
	print x;
quit;

/*example 22.4*/
proc optmodel;
   /* declare sets and parameters */
   set <str> PRODUCTS, RESOURCE;
   num Cost{RESOURCE}, Availability{RESOURCE};
   num Selling_Price{PRODUCTS};
   num Required{PRODUCTS, RESOURCE}; 

   /* read data from SAS data sets */
   read data resource_data into Resource=[Resource] 
     Cost Availability=Amount_Available;

   read data product_data into PRODUCTS=[Item]  
     {r in RESOURCE} <Required[item, r]=col(r)>
     Selling_Price;

	var x{PRODUCTS} >= 0;

 
	impvar Revenue = sum{p in PRODUCTS}Selling_Price[p]*x[p];
	impvar Amount_Used{r in RESOURCE} = sum{p in PRODUCTS} Required[p, r]*x[p];
	impvar Total_Cost = sum{r in RESOURCE} Cost[r]*Amount_Used[r];
	impvar Profit{p in PRODUCTS} = ( Selling_Price[p] -  sum{r in RESOURCE} Cost[r]*Required[p, r] ) * x[p];

	/* declare constraints */
	con Usage{r in RESOURCE}: 
	 Amount_Used[r] <= Availability[r];

	PRODUCTS = PRODUCTS union /E/;
    Selling_Price['E'] = 1000;
    Required['E', 'R1'] = 2; 
          Required['E', 'R2'] = 4; 
	Required['E', 'Labor'] = 3; 

	/* declare objective */
	max Net_Profit = Revenue - Total_Cost;

	fix x['B'] = 30;
	fix x['C'] = 40;
	x['D'].ub = 100;
	x['A'].lb = 20; 
	x['E'].lb = 20;

	solve ;
	print x;
	print amount_used;
quit;


/*example 22.5*/
proc optmodel;
   /* declare sets and parameters */
   set <str> PRODUCTS, RESOURCE;
   num Cost{RESOURCE}, Availability{RESOURCE};
   num Selling_Price{PRODUCTS};
   num Required{PRODUCTS, RESOURCE}; 

   /* read data from SAS data sets */
   read data resource_data into Resource=[Resource] 
     Cost Availability=Amount_Available;

   read data product_data into PRODUCTS=[Item]  
     {r in RESOURCE} <Required[item, r]=col(r)>
     Selling_Price;

	var x{PRODUCTS} >= 0;
	var extra_r1 >=0 <=200;
 
	impvar Revenue = sum{p in PRODUCTS}Selling_Price[p]*x[p];
	impvar Amount_Used{r in RESOURCE} = sum{p in PRODUCTS} Required[p, r]*x[p];
	impvar Total_Cost = sum{r in RESOURCE} Cost[r]*Amount_Used[r]+0.5*extra_r1 ;
	impvar Profit{p in PRODUCTS} = ( Selling_Price[p] -  sum{r in RESOURCE} Cost[r]*Required[p, r] ) * x[p];

	/* declare constraints */
	con Usage{r in RESOURCE}: 
	 Amount_Used[r] <= Availability[r] + if (r='R1') then extra_r1;

	PRODUCTS = PRODUCTS union /E/;
    Selling_Price['E'] = 1000;
    Required['E', 'R1'] = 2; 
    Required['E', 'R2'] = 4; 
	Required['E', 'Labor'] = 3; 

	/* declare objective */
	max Net_Profit = Revenue - Total_Cost;

	fix x['B'] = 30;
	fix x['C'] = 40;
	x['D'].ub = 100;
	x['A'].lb = 20; 
	x['E'].lb = 20;


	solve ;
	print x;
	print amount_used; 
	print extra_r1;
	print Availability ;
quit;


/*example 22.6*/
proc optmodel;
   /* declare sets and parameters */
   set <str> PRODUCTS, RESOURCE;
   num Cost{RESOURCE}, Availability{RESOURCE};
   num Selling_Price{PRODUCTS};
   num Required{PRODUCTS, RESOURCE}; 

   /* read data from SAS data sets */
   read data resource_data into Resource=[Resource] 
     Cost Availability=Amount_Available;

   read data product_data into PRODUCTS=[Item]  
     {r in RESOURCE} <Required[item, r]=col(r)>
     Selling_Price;

	var x{PRODUCTS} >= 0;
	var extra_r1 >=0 <=200;

	impvar Revenue = sum{p in PRODUCTS}Selling_Price[p]*x[p];
	impvar Amount_Used{r in RESOURCE} = sum{p in PRODUCTS} Required[p, r]*x[p];
	impvar Total_Cost = sum{r in RESOURCE}Cost[r]*Amount_Used[r]+0.5*extra_r1;
	impvar Profit{p in PRODUCTS} = ( Selling_Price[p] -  sum{r in RESOURCE} Cost[r]*Required[p, r] ) * x[p];

	/* declare constraints */
	con Usage{r in RESOURCE}: 
	 Amount_Used[r] <= Availability[r] + if (r='R1') then extra_r1 ;

	PRODUCTS = PRODUCTS union /E/;
    Selling_Price['E'] = 1000;
    Required['E', 'R1'] = 2; 
    Required['E', 'R2'] = 4; 
	Required['E', 'Labor'] = 3; 

	/* declare objective */
	max Net_Profit = Revenue - Total_Cost;

	fix x['B'] = 30;
	fix x['C'] = 40;
	x['D'].ub = 100;
	x['A'].lb = 20; 
	x['E'].lb = 20;

	drop  Usage['R2'];
	solve ;
	print x;
	print amount_used; 
quit;

/*example 22.7*/

data route; 
	input Origin $13. Destination $14. cost; 
	datalines; 
Toronto       Chicago       105
Toronto       Los Angel     120
Toronto       San Francisco 135
Chicago       ShangHai      600
Chicago       TianJin	    621
Los Angel     ShangHai      680
Los Angel     TianJin       650
Los Angel     HongKong      610
San Francisco TianJin       710
San Francisco HongKong      650
ShangHai 	  BeiJing 	    55
TianJin	      BeiJing 	    45
HongKong	  BeiJing	    100
;
run;


data capacity; 
	input Warehouse $13. Capacity; 
	datalines; 
Toronto       1500
Chicago       300
Los Angel     350
San Francisco 200 
HongKong      400
ShangHai      300
TianJin       300
BeiJing       2000
; 
run;


proc optmodel; 
   /* declare sets and parameters */
   set <str,str> Arcs; 
   set <str> Nodes ; 

   num Cost{Arcs};
   num Capacity{Nodes};
   num Supply{Nodes} init 0;
   num Demand{Nodes} init 0;

   /* read data from SAS data sets */
   read data route into Arcs=[Origin Destination] Cost;
   read data capacity into Nodes = [Warehouse] Capacity;

   /* assign supply and demand values */
   Supply['Toronto'] = 800;
   Demand['BeiJing'] = 800;

   /* declare variables */
   var x{Arcs} >= 0 <= 350;

   impvar Flow_In{k in Nodes} = sum{<i,(k)> in Arcs} x[i,k];

   impvar Flow_Out{k in Nodes} = sum{<(k),j> in Arcs} x[k,j]; 

   /* declare constraints */
   con Flow_Balance{k in Nodes}: 
     Flow_In[k] + Supply[k] = Flow_Out[k] + Demand[k];

	con Flow_Node{k in Nodes}:
		 Flow_In[k] + Supply[k]<=Capacity[k];

   /* declare objective */
   min Total_Cost = sum{<i,j> in Arcs} Cost[i,j] * x[i,j];

   solve with lp / solver=ns;

   create data network_flows from [Origin Destination]=
     {<i,j> in Arcs: x[i,j]>0} Amount=x;

   quit; 
