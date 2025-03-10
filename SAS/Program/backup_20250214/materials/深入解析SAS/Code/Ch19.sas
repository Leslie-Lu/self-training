proc optmodel;
	/*declare variables*/
	var Product1 >=0 integer, Product2>=0 integer;

	/*maximize objective funtion (profit)*/
	maximize profit = 4*Product1+6*Product2;

	/*subject to constraitns*/
	con materialA: 2*Product1+3*Product2 <=18;
	con materialB: 2*Product1+1*Product2 <=10;
	con materialC: 1*Product1+4*Product2 <=16;

	/*solve MILP*/
	solve with MILP;

	/*display solution*/
	print Product1 Product2;

quit;

data work.product;
	length Name $10.;
	input Name $ profit;
datalines;
Product1 4
Product2 6
;
run;
data work.required;
	length Name $10.;
	input Name $ A B C;
datalines;
Product1 2 2 1
Product2 3 1 4
;
run;
data work.material;
	length material $1.;
	input material $ available;
datalines;
A 18
B 10
C 16
;
run; 
proc optmodel;
	/*declare sets and data indexed by sets	*/
	set<string>  PRODUCT;
	set<string> MATERIAL;
	num profit{PRODUCT};
	num required{PRODUCT,MATERIAL};
	num available{MATERIAL};

	/*declare variables*/
	var Units{PRODUCT} >=0 integer;

	/*maximize objective funtion (profit)*/
	maximize totalprofit=sum{p in PRODUCT}profit[p]*Units[p];

	/*subject to constraitns*/
	con availablity{m in MATERIAL}:
	sum{p in PRODUCT} required[p,m]*Units[p]<=available[m];

	/*abstract algebaric model that captures the structure of 
	  the optimization problem has been defined without 
	  referring to a single data constant            		*/

	/*populate model by reading in the specific data instance*/
	read data work.product into PRODUCT=[name] profit;
	read data work.material into MATERIAL=[material] available;
	read data work.required into PRODUCT=[name] {m in MATERIAL} <required[name,m]=col(m)>;

	/*solve MILP*/
	solve with MILP;

	/*display solution*/
	print Units;
quit;


