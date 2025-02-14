/*lp0*/
proc optmodel; 
	var x>=0 ; 
	var y>=0 ; 
	
	con 2*x-y<=3; 
	con 3*x+4*y<=9; 

	max f=5*x+4*y; 
	solve;
	print x y;
quit;



proc optmodel; 
	var x>=0 <=1 ; 
	var y>=0 ; 
	
	con 2*x-y<=3; 
	con 3*x+4*y<=9; 
	con x+y<=2;

	max f=5*x+4*y; 
	solve;
	print x y;
quit;


/*example 23.2*/
proc optmodel; 
	var x>=0 integer; 
	var y>=0 integer; 
	
	con 2*x-y<=3; 
	con 3*x+4*y<=9; 

	max f=5*x+4*y; 
	solve;
	print x y;
quit;


/*example 23.3*/
proc optmodel; 
	var x>=0 ; 
	var y>=0 integer; 
	
	con 2*x-y<=3; 
	con 3*x+4*y<=9; 

	max f=5*x+4*y; 
	solve;
	print x y;
quit;


/*example 23.4*/

data atm;
      input atm_id $ location $  capacity cost; 
      datalines; 
      A001 L1 150000 400
      A002 L1 150000 400
      A003 L1 150000 800
      A004 L1 100000 400
      A005 L1 100000 800
      A006 L1 100000 800
;
run;


/*this data contains the amount of cash withdrawed per day per atm*/
data withdraw; 
      input atm_id $  date mmddyy10. withdraw @@; 
      format date date9.;
      datalines; 
A001 05/05/2014 21000   A002 05/05/2014 24000   A003 05/05/2014 21000 
A004 05/05/2014 26000   A005 05/05/2014 19000   A006 05/05/2014 19000
A001 05/06/2014 30000   A002 05/06/2014 19000   A003 05/06/2014 27000 
A004 05/06/2014 21000   A005 05/06/2014 21000   A006 05/06/2014 21000
A001 05/07/2014 27000   A002 05/07/2014 20000   A003 05/07/2014 26000 
A004 05/07/2014 18000   A005 05/07/2014 22000   A006 05/07/2014 23000
A001 05/08/2014 20000   A002 05/08/2014 31000   A003 05/08/2014 20000 
A004 05/08/2014 20000   A005 05/08/2014 24000   A006 05/08/2014 35000
A001 05/09/2014 31000   A002 05/09/2014 21000   A003 05/09/2014 30000 
A004 05/09/2014 19000   A005 05/09/2014 18000   A006 05/09/2014 34000
A001 05/10/2014 30000   A002 05/10/2014 40000   A003 05/10/2014 55000 
A004 05/10/2014 26000   A005 05/10/2014 20000   A006 05/10/2014 25000
A001 05/11/2014 35000   A002 05/11/2014 32000   A003 05/11/2014 35000 
A004 05/11/2014 15000   A005 05/11/2014 25000   A006 05/11/2014 35000
;
run;


data initial; 
	input atm_id $  date mmddyy10. init_inv;
datalines;
A001 05/05/2014 0
A002 05/05/2014 0
A003 05/05/2014 0
A004 05/05/2014 0
A005 05/05/2014 0
A006 05/05/2014 0
;
run;


data budget; 
      input date mmddyy10. budget; 
      format date date9.;
      datalines ;
05/05/2014 600000
05/06/2014 600000
05/07/2014 600000
05/08/2014 600000
05/09/2014 800000
05/10/2014 800000
05/11/2014 800000
      ; 
run;

data vehicle; 
	input location $ vehicle_type $ count; 
	datalines; 
L1 V1 4
; 
run;



%let DailyIntrestRate = %sysevalf(0.06/360);
%let startdate = '05May2014'd;	
%let CashShortCost = 0.008;
%let ReplenishCostWeight = 0.1;
proc optmodel; 
/*	define index sets*/
	set<str> ATM; 
	set<num> DATE; 
	set<str> LOCATION;
	set<str, str> ATM_LOCATION; 
	set<str, str> LOCATION_VTYPE; 

/*define numrical variable to be read from data sets above*/
	num capacity{ATM}; 
	num cost{ATM};
	num budget{DATE};
	num withdraw{ATM, DATE}; 
	num init_inv{ATM,DATE};
	num count{LOCATION_VTYPE};

/*read data set*/
	read data atm into ATM = [atm_id] capacity cost; 
	read data atm into ATM_LOCATION = [atm_id location];

	read data budget into  DATE = [date]  budget; 
	read data withdraw into [atm_id date] withdraw;
	read data initial into [atm_id date] init_inv; 
	read data vehicle into LOCATION_VTYPE = [location vehicle_type] count ;

/*define decision variable*/
*X: the mount each atm replenished on a specific date;
	var X{ATM, DATE}>=0 integer; 
	for {a in ATM} 
	    for {d in DATE} do;
	    if weekday(d)=7 or weekday(d)=1 then fix X[a,d] = 0; *No replenish on saturday and sunday;   
	end;

	var IsReplenished{ATM, DATE} binary; 
	var splus{ATM, DATE}>=0 integer;  
	var sminus{ATM, DATE}>=0 integer;

/*ExtraCashCost: cost that results from storing capital in ATM*/
/*ReplenishCost: replenish cost each time*/
/*CashShortCost: penalty cost that result from cashout*/
	impvar ExtraCashCost = sum{a in ATM, d in DATE}sminus[a, d]*&DailyIntrestRate. ; 
	impvar ReplenishCost = sum{a in ATM, d in DATE}IsReplenished[a, d]*cost[a];
	impvar CashShortCost = sum{a in ATM, d in DATE}splus[a, d];

/*define constraints*/
	con InvPlusReplenish{a in ATM, d in DATE}: 
		x[a, d] + (if d =&startdate. then init_inv[a, d] else sminus[a, d-1]) <= capacity[a]; 

	con slackvariable{a in ATM, d in DATE}:
		x[a, d] + splus[a, d] - sminus[a, d] + (if d =&startdate. then 0 else sminus[a, d-1]) = withdraw[a, d];


	con Replenish{a in ATM, d in DATE}:
	   x[a, d] <= capacity[a]*IsReplenished[a, d]; 

	con DailyBudget{d in DATE}:
		sum{a in ATM}x[a, d] <= budget[d];

	con MaxNumReplenished{d in DATE, <l, v> in LOCATION_VTYPE}: 
		sum{a in slice(<*, l> , ATM_LOCATION)}IsReplenished[a, d]<= count[l, v];

	con SplusUB{a in ATM, d in DATE}: 
		splus[a, d] <= withdraw[a, d]; 

	con SminusUB{a in ATM, d in DATE}: 
		sminus[a, d] <= capacity[a]; 
 
 
/*define objective function */
	min TotalCost = ExtraCashCost + &ReplenishCostWeight.*ReplenishCost + &CashShortCost.*CashShortCost;

/*call solver*/
	solve; 

/*save results as data set*/
create data ReplenishPlan from [ATM DATE] Withdraw X  IsReplenished Splus Sminus; 
quit;



proc transpose data = ReplenishPlan out = DailyPlan name = ATM prefix = day;
	by ATM; 
	var x; 
run;

proc print data = DailyPlan noobs; title "??????" ;run;

proc transpose data = ReplenishPlan out = Splus name = ATM prefix = day;
	by ATM; 
	var splus; 
run;
proc print data = Splus noobs; title "??Splus???"; run;
