/*libname ex '\\scnwex\Book\Data';*/

data ex.cars_types ex.cars_test ;
	Set sashelp.cars(keep = Make Model Type EngineSize MPG_City Weight Wheelbase Length);
	by make type;
	where type in ("SUV", "Sedan", "Sports");
	if first.type then do;
		if Origin in ("USA" ,"Europe") 
		then  output  ex.cars_types;
		else output  ex.cars_test;	
	end;
run;


proc discrim data = ex.cars_types testdata =  ex.cars_test method = normal pool = test distance list testout =  ex.car_results; 
	class type; 
	var Weight Wheelbase Length MPG_City EngineSize; 
run;



data ex.cars_test_notype;
	set ex.cars_test; 
	Type = " "; 
run;



proc sql; 
	create table ex.cars_all as
	select * from ex.cars_types
	union
	select * from ex.cars_test_notype
;
quit;  

proc candisc data = ex.cars_all out = ex.cars_all_results distance; 
	class type; 
	var Weight Wheelbase Length MPG_City EngineSize; 
run;


Proc discrim data =  ex.cars_all_results method = normal                                                                                               
	pool=test out =  ex.cars_results2 ; 
	class type; 
	var can1 can2; 
run;


proc stepdisc method = stepwise data = ex.cars_all;
	class type; 
	var Weight Wheelbase Length MPG_City EngineSize; 
run;


proc discrim data =  ex.cars_types testdata =  ex.cars_test method = normal pool = test
	distance list testout =  ex.car_results; 
	class type; 
	var Weight EngineSize MPG_City Wheelbase; 
run;
