
******case 1******;
data work.data_shipped_items;
	length item_id $8;
	do i=1 to 200;
		item_id="XITEM"||left(trim(i));
		weight_kilo=input(ranuni(9999)*100,5.2);
		volume_cfeet=input(ranuni(999999)*75, 5.2);
		output;
	end;
run;

%let weight_ub=2000;
%let cubicfeet_ub=1000;

proc sql;
	select sum(weight_kilo) as weight_kilo, sum(volume_cfeet) as volume_cfeet
	from work.data_shipped_items;
quit;

proc sql;
	select count(item_id) into :item_cnt
	from work.data_shipped_items;
quit;

proc optmodel;
	set <str> ITEM;
	set <num> CONTID=1..&item_cnt;
	set ITEM_CONTID ={i in ITEM, c in CONTID};
	num weight{ITEM} init 0;
	num cubicfeet{ITEM} init 0;

	read data work.data_shipped_items nomiss into 
		ITEM=[item_id] 
        weight=weight_kilo
	    cubicfeet=volume_cfeet;

	var Container{CONTID} binary;                
	var ItemInContainer{ITEM_CONTID} binary;   
/*	impvar WeightOfContainer{c in CONTID} = sum{<i,(c)> in ITEM_CONTID} (ItemInContainer[i,c]*weight[i]);*/

	impvar WeightOfContainer{c in CONTID} = sum{i in ITEM:<i,c> in ITEM_CONTID} (ItemInContainer[i,c]*weight[i]);

	impvar CubicOfContainer{c in CONTID} = sum{<i,(c)> in ITEM_CONTID} (ItemInContainer[i,c]*cubicfeet[i]);

	/*one item should only exist in only one container*/
	con Oneitem_in_onecontainer{<i> in ITEM}:
		 sum{<(i),c> in ITEM_CONTID} ItemInContainer[i,c]=1;

	/*the total weights in one container should not exceed the upper bound*/
	con Container_weight_bound{c in CONTID}:
		WeightOfContainer[c]<=Container[c]*&weight_ub.;

	/*the total cubic feet in one container should not exceed the upper bound*/
	con Container_cubicfeet_bound{c in CONTID}:
	    CubicOfContainer[c]<=Container[c]*&cubicfeet_ub.;

	min MiniCounts=sum{c in CONTID}Container[c];

/*	expand;*/
    solve with milp /maxtime=600;

	/*output result*/
	for {<i, c> in ITEM_CONTID} ItemInContainer[i,c]=round(ItemInContainer[i,c]);
	create data work.item_in_container from [item_id container_id]={<i, c> in ITEM_CONTID: ItemInContainer[i,c]=1} weight_kilo=Weight[i] volume_cfeet=cubicfeet[i];
	create data work.container_kpi from [container_id]={<c> in CONTID: Container[c]=1} Total_Weight=WeightOfContainer[c] Total_Cubic=CubicOfContainer[c];

quit;

proc sql;
	select avg(Total_Weight),avg(Total_Cubic) into :avgweight, :avgcubicfeet
	from   container_kpi;
quit;


proc optmodel;
	set <str> ITEM;
	set <num> CONTID;
	set <str,num> INITIAL_ITEM_CONTID;
	set ITEM_CONTID ={i in ITEM, c in CONTID};
	num weight{ITEM} init 0;
	num cubicfeet{ITEM} init 0;
	num avgweight = &avgweight.;
	num avgcfeet = &avgcubicfeet.;

	var ItemInContainer{ITEM_CONTID} binary;   
	var W{CONTID}>=0;
	var V{CONTID}>=0;

	impvar WeightOfContainer{c in CONTID} = sum{<i,(c)> in ITEM_CONTID} (ItemInContainer[i,c]*weight[i]);
	impvar CubicOfContainer{c in CONTID} = sum{<i,(c)> in ITEM_CONTID} (ItemInContainer[i,c]*cubicfeet[i]);

	/*one item should only exist in only one container*/
	con Oneitem_in_onecontainer{<i> in ITEM}:
		 sum{<(i),c> in ITEM_CONTID} ItemInContainer[i,c]=1;

	/*the total weights in one container should not exceed the upper bound*/
	con Container_weight_bound{c in CONTID}:
		WeightOfContainer[c]<=&weight_ub.;

	/*the total cubic feet in one container should not exceed the upper bound*/
	con Container_cubicfeet_bound{c in CONTID}:
	    CubicOfContainer[c]<=&cubicfeet_ub.;

	con Lb_weight{c in CONTID}: WeightOfContainer[c]-avgweight<=W[c];
	con Ub_weight{c in CONTID}: avgweight-WeightOfContainer[c]<=W[c];
	con Lb_volume{c in CONTID}: CubicOfContainer[c]-avgcfeet<=V[c];
	con Ub_volume{c in CONTID}: avgcfeet-CubicOfContainer[c]<=V[c];

	min Variance=sum{c in CONTID} (W[c]+V[c]);

	read data work.data_shipped_items nomiss into 
		ITEM=[item_id] 
        weight=weight_kilo
	    cubicfeet=volume_cfeet;

	read data work.container_kpi nomiss into 
		CONTID=[container_id];

	read data work.item_in_container nomiss into 
		INITIAL_ITEM_CONTID=[item_id container_id];

	/*assign initial solution*/
	for {<i,c> in INITIAL_ITEM_CONTID} ItemInContainer[i,c]=1;
	for {c in CONTID} do;
		W[c]=&weight_ub.;
		V[c]=&cubicfeet_ub.;
	end;

	solve with milp / primalin maxtime=400;

	/*output result*/
	create data work.blance_item_in_container from [item_id container_id]={<i, c> in ITEM_CONTID: ItemInContainer[i,c]=1} weight_kilo=Weight[i] volume_cfeet=cubicfeet[i];
	create data work.balance_container_kpi from [container_id]={<c> in CONTID} Total_Weight=WeightOfContainer[c] Total_Cubic=CubicOfContainer[c];
quit;

************************;
******case 2******;

data work.allocation;
	length warehouse $3 package $8;
	input warehouse $ package $ color $ allocation bklg;
	datalines;
WH1	EXCELLE	BLACK	300	7
WH2	EXCELLE	BLACK	100	6
WH3	EXCELLE	BLACK	80	3
WH4	EXCELLE	BLACK	400	1
WH5	EXCELLE	BLACK	500	2
WH6	EXCELLE	BLACK	250	7
WH7	EXCELLE	BLACK	460	4
WH8	EXCELLE	BLACK	320	9
WH9	EXCELLE	BLACK	540	6
WH1	EXCELLE	GREY	600	7
WH2	EXCELLE	GREY	300	4
WH3	EXCELLE	GREY	720	9
WH4	EXCELLE	GREY	300	8
WH5	EXCELLE	GREY	600	3
WH6	EXCELLE	GREY	200	5
WH7	EXCELLE	GREY	700	2
WH8	EXCELLE	GREY	400	1
WH9	EXCELLE	GREY	730	7
WH1	TENNAL	RED	40	6
WH2	TENNAL	RED	30	10
WH3	TENNAL	RED	40	9
WH4	TENNAL	RED	70	8
WH5	TENNAL	RED	45	6
WH6	TENNAL	RED	57	8
WH7	TENNAL	RED	25	4
WH8	TENNAL	RED	53	6
WH1	TENNAL	BLACK	112	1
WH2	TENNAL	BLACK	300	2
WH3	TENNAL	BLACK	230	7
WH4	TENNAL	BLACK	120	4
WH5	TENNAL	BLACK	340	8
WH6	TENNAL	BLACK	200	6
WH7	TENNAL	BLACK	75	10
WH8	TENNAL	BLACK	125	3
WH9	TENNAL	BLACK	190	6
WH1	TENNAL	GREY	120	4
WH2	TENNAL	GREY	320	1
WH3	TENNAL	GREY	230	6
WH4	TENNAL	GREY	100	5
WH5	TENNAL	GREY	450	6
WH6	TENNAL	GREY	230	4
WH7	TENNAL	GREY	222	4
WH8	TENNAL	GREY	72	1
WH9	TENNAL	GREY	156	10
;
run;

data work.production;
	input package $ color $ weekday $ quantity dow;
	datalines;
TENNAL	RED	Mon	70 1
TENNAL	RED	Tue	80 2
TENNAL	RED	Wed	90 3
TENNAL	RED	Thu	100 4
TENNAL	BLACK	Mon	300 1
TENNAL	BLACK	Tue	340 2
TENNAL	BLACK	Wed	340 3
TENNAL	BLACK	Thu	350 4
TENNAL	BLACK	Fri	350 5
EXCELLE	BLACK	Mon	400 1
EXCELLE	BLACK	Tue	450 2
EXCELLE	BLACK	Wed	500 3
EXCELLE	BLACK	Thu	500 4
EXCELLE	BLACK	Fri	500 5
EXCELLE	BLACK	Sat	300 6
EXCELLE	BLACK	Sun	300 7
EXCELLE	GREY	Mon	600 1
EXCELLE	GREY	Tue	600 2
EXCELLE	GREY	Wed	650 3
EXCELLE	GREY	Thu	600 4
EXCELLE	GREY	Fri	600 5
EXCELLE	GREY	Sat	700 6
EXCELLE	GREY	Sun	600 7
TENNAL	GREY	Mon	500 1
TENNAL	GREY	Tue	450 2
TENNAL	GREY	Wed	450 3
TENNAL	GREY	Thu	500 4
;
run;

data work.stock;
	input package $ color $ stock;
	datalines;
EXCELLE	GREY	200
TENNAL	RED	20
TENNAL	BLACK	12
;
run;

data work.ship_direct_route;
	length warehouse $3 shared_route $6;
	infile datalines dsd missover;
	input warehouse $ shared_route $ Mon Tue Wed Thu Fri Sat Sun NextMon NextTue;
	datalines;
WH1,DIRECT,,350,,200,300,,,200	
WH2,WH2WH3,,300,,150,,150,,			
WH3,WH2WH3,,350,,,350,,350		
WH4,WH4WH5									
WH5,WH4WH5,300,,300,,,300,,,300,,,300
WH7,DIRECT,330,230,,230,,230,,330	
WH8,DIRECT,230,,,230,,,230		
;
run;

data work.ship_shared_route;
	length shared_route $6;
	infile datalines dsd missover;
	input shared_route $ Mon Tue Wed Thu Fri Sat Sun NextMon NextTue;
	datalines;
WH2WH3,,250,,150,,,250
WH4WH5,,150,,,,250,,,150
;
run;

data work.train_schedule;
	length warehouse $3;
	infile datalines dsd missover;
	input warehouse $ Mon Tue Wed Thu Fri Sat Sun NextMon NextTue;
	datalines;
WH4,150,,,150,,,,150
WH5,,150,,,,290,,,150
WH6,290,,,,290,,,290
WH8,,150,,,150,,,150
;
run;

data work.stock_at_port;
	length mode $5 warehouse $3;
	input mode warehouse stock_at_port;
	datalines;
ship	WH1	10
ship	WH5	20
ship	WH7	14
ship	WH8	15
train	WH4	20
train	WH6	18
;
run;

*** copy data into work ***;
data work.data_allocation;set work.allocation;run;
data work.data_production;set work.production;run;
data work.data_stock;set work.stock;run;
data work.data_train_schedule; set work.Train_schedule; run;
data work.data_ship_direct_route; set work.Ship_direct_route; run;
data work.data_ship_shared_route; set work.Ship_shared_route; run;
data work.data_stock_at_port; set work.stock_at_port; mode=upcase(mode); run;

proc transpose data=work.data_train_schedule(drop=warehouse) out=work.day_of_week_ext(keep=_name_); run;
data work.day_of_week_ext; set work.day_of_week_ext; label _name_='day of week extention'; index=_n_; run;

***Data validation****;
%macro DataValidation;
	***validate allocation table and only keep set 
	<package color> with positive allocations and
	nonnegative bklg ***;
	data work.exp_allocation(keep=package color error)
		work.data_allocation(drop=error);
		set work.data_allocation;
		if allocation <= 0 or bklg < 0 then do;
			error = 'nonpositive allocation or negative backlog';
			output work.exp_allocation;
		end;
		else output work.data_allocation;
	run;

	data work.temp_allocation(keep=package color); set work.data_allocation; run;
	proc sort nodup data=work.temp_allocation
			out=work.val_package_color; by package color; run;

	proc sql; select count(*) into :exp_allocation from work.exp_allocation; quit;
	%put exp=&exp_allocation;

	*** validate production/stock table and
		create data_production_stock table ***;
	data work.exp_production
		work.data_production(drop=error);
		length package $8 color $8;
		if _n_=1 then do;
			declare hash h(dataset:'work.val_package_color');
			h.definekey('package','color');
			h.definedone();
			call missing(package,color);
		end;

		set work.data_production;

		if h.find()^=0 then do;
			error = 'no such (package,color) in allocation table';
			output work.exp_production;
		end;
		else if quantity<0 then do;
			error = 'negative production quantity';
			output work.exp_production;
		end;
		else output work.data_production;
	run;
	proc sql; select count(*) into :exp_production from work.exp_production; quit;

	data work.exp_stock
		work.data_stock(drop=error);
		length package $8 color $8;
		if _n_=1 then do;
			declare hash h(dataset:'work.val_package_color');
			h.definekey('package','color');
			h.definedone();
			call missing(package,color);
		end;

		set work.data_stock;

		if h.find()^=0 then do;
			error = 'no such (package,color) in allocation table';
			output work.exp_stock;
		end;
		else if stock<0 then do;
			error = 'negative stock value';
			output work.exp_stock;
		end;
		else output work.data_stock;
	run;
	proc sql; select count(*) into :exp_stock from work.exp_stock; quit;

	data work.temp_production;
		set work.val_package_color;
	run;
	%do i=1 %to 7;
		proc sql;
			create table work.temp_production_1 as 
			select a.*, 
				%if &i=1 %then b.quantity as Mon;
				%else %if &i=2 %then b.quantity as Tue;
				%else %if &i=3 %then b.quantity as Wed;
				%else %if &i=4 %then b.quantity as Thu;
				%else %if &i=5 %then b.quantity as Fri;
				%else %if &i=6 %then b.quantity as Sat;
				%else b.quantity as Sun;
			from work.temp_production as a left join work.data_production(where=(dow=&i)) as b
			on a.package = b.package
			and a.color = b.color;
		quit;
		data work.temp_production;
			set work.temp_production_1;
		run;
	%end;


	proc sql;
		create table work.data_production_stock as 
		select a.*, stock
		from work.temp_production as a left join work.data_stock as b
		on a.package = b.package
		and a.color = b.color;
	quit;


	*** Only consider route with allocation defined ***;
	data work.val_route(keep=warehouse); set work.data_allocation; run;
	proc sort nodup data=work.val_route; by warehouse; run;

	data work.exp_ship_direct_route(keep=warehouse error)
		work.data_ship_direct_route(drop=error);
		length warehouse $3;
		if _n_=1 then do;
			declare hash route(dataset:'work.val_route');
			route.definekey('warehouse');
			route.definedata('warehouse');
			route.definedone();
			call missing(warehouse);
		end;
		
		set work.data_ship_direct_route;

		if route.find()^=0 then do;
			error = 'no such route in allocation table';
			output work.exp_ship_direct_route;
		end;
		else output work.data_ship_direct_route;
	run;
	proc sql; select count(*) into :exp_ship_direct_route from work.exp_ship_direct_route; quit;

	data work.exp_train_schedule(keep=warehouse error)
		work.data_train_schedule(drop=error);
		length warehouse $3;
		if _n_=1 then do;
			declare hash route(dataset:'work.val_route');
			route.definekey('warehouse');
			route.definedata('warehouse');
			route.definedone();
			call missing(warehouse);
		end;
		
		set data_train_schedule;

		if route.find()^=0 then do;
			error = 'no such route in allocation table';
			output work.exp_train_schedule;
		end;
		else output work.data_train_schedule;
	run;
	proc sql; select count(*) into :exp_train_schedule from work.exp_train_schedule; quit;

	*** Only consider stock with known route ***;
	data work.exp_stock_at_port(keep=warehouse error)
		work.data_stock_at_port(drop=error);
		length warehouse $3;
		if _n_=1 then do;
			declare hash ship(dataset:'work.Data_ship_direct_route');
			ship.definekey('warehouse');
			ship.definedata('warehouse');
			ship.definedone();
			call missing(warehouse);

			declare hash train(dataset:'work.Data_train_schedule');
			train.definekey('warehouse');
			train.definedata('warehouse');
			train.definedone();
			call missing(warehouse);
		end;

		set work.data_stock_at_port;

		if mode='TRAIN' and train.find()^=0 then do;
			error = 'no such route in train schedule';
			output work.exp_stock_at_port;
		end;
		else if mode='SHIP' and ship.find()^=0 then do;
			error = 'no such route in ship route';
			output work.exp_stock_at_port;
		end;
		else output work.data_stock_at_port;
	run;
	proc sql; select count(*) into :exp_stock_at_port from work.exp_stock_at_port; quit;

	*** aggregate exceptions into exp_status table ***;
	proc sql;
		create table work.exp_status 
		(
			table	char 32 	label='table name',
			remove	num			label='removed records'
		);

		insert into work.exp_status
			values('data_allocation',&exp_allocation)
			values('data_production',&exp_production)
			values('data_stock',&exp_stock)
			values('data_ship_direct_route',&exp_ship_direct_route)
			values('data_train_schedule',&exp_train_schedule)
			values('data_stock_at_port',&exp_stock_at_port);
	quit;

	proc datasets library=work NOPRINT;
		delete temp_:
			val_:;
	quit;			
%mend DataValidation;

%DataValidation;

proc optmodel;
	set<str> DOW_EXT;
	num index{DOW_EXT};
	read data day_of_week_ext into DOW_EXT=[_name_] index;
	set<str> DOW = {d in DOW_EXT: index[d]<=7};
	put DOW_EXT DOW ;

	set<str,str> PACKAGE_COLOR;
	num stock{PACKAGE_COLOR} init 0;
	num production{PACKAGE_COLOR, DOW} init 0;
	read data work.data_production_stock nomiss into PACKAGE_COLOR=[package color]
		stock {d in DOW}<production[package,color,d]=col(d)>;

	set<str,str,str> WH_PACKAGE_COLOR;
	num allocation{WH_PACKAGE_COLOR};
	num bklg{WH_PACKAGE_COLOR};
	read data work.Data_allocation into WH_PACKAGE_COLOR=[warehouse package color] allocation bklg;

	set<str> TRAIN_ROUTE;
	num train_cap{TRAIN_ROUTE,DOW_EXT} init 0;
	read data work.Data_train_schedule nomiss into TRAIN_ROUTE=[warehouse] 
			{d in DOW_EXT}<train_cap[warehouse,d]=col(d)>;

	set<str> SHIP_ROUTE;
	num ship_direct_cap{SHIP_ROUTE, DOW_EXT} init 0;
	str ship_shared_route{SHIP_ROUTE};
	read data work.Data_ship_direct_route nomiss into SHIP_ROUTE=[warehouse]
			ship_shared_route=shared_route {d in DOW_EXT}<ship_direct_cap[warehouse,d]=col(d)>;

	put SHIP_ROUTE;
	print ship_shared_route;

	set<str> SHIP_SHAREDROUTE;
	num ship_shared_cap{SHIP_SHAREDROUTE,DOW_EXT} init 0;
	read data work.Data_ship_shared_route nomiss into SHIP_SHAREDROUTE=[shared_route]
			{d in DOW_EXT}<ship_shared_cap[shared_route,d]=col(d)>;

	num train_stock_at_port{TRAIN_ROUTE} init 0;
	num ship_stock_at_port{SHIP_ROUTE} init 0;
	read data work.Data_stock_at_port(where=(mode='TRAIN')) nomiss into [warehouse] train_stock_at_port=stock_at_port;
	read data work.Data_stock_at_port(where=(mode='SHIP'))  nomiss into [warehouse] ship_stock_at_port=stock_at_port;

	print ship_shared_route;

	*** adjust train/ship capacities to transport stock on port ***;
	for {d in DOW_EXT} do;
		for {<w> in TRAIN_ROUTE: train_stock_at_port[w]>0} do;
			if train_stock_at_port[w]>train_cap[w,d] then do;
				train_stock_at_port[w]=train_stock_at_port[w]-train_cap[w,d];
				train_cap[w,d]=0;
			end;
			else do;
				train_cap[w,d]=train_cap[w,d]-train_stock_at_port[w];
				train_stock_at_port[w]=0;
			end;
		end;
		for {<w> in SHIP_ROUTE: ship_stock_at_port[w]>0} do;
			if ship_stock_at_port[w] > ship_direct_cap[w,d] then do;
				ship_stock_at_port[w] = ship_stock_at_port[w] - ship_direct_cap[w,d];
				ship_direct_cap[w,d] = 0;
			end;
			else do;
				ship_direct_cap[w,d] = ship_direct_cap[w,d] - ship_stock_at_port[w];
				ship_stock_at_port[w] = 0;
			end;
		end;
		for {<w> in SHIP_ROUTE: ship_shared_route[w] in SHIP_SHAREDROUTE and ship_stock_at_port[w]>0} do;
			if ship_stock_at_port[w] > ship_shared_cap[ship_shared_route[w],d] then do;
				ship_stock_at_port[w] = ship_stock_at_port[w] - ship_shared_cap[ship_shared_route[w],d];
				ship_shared_cap[ship_shared_route[w],d] = 0;
			end;
			else do;
				ship_shared_cap[ship_shared_route[w],d] = ship_shared_cap[ship_shared_route[w],d] - ship_stock_at_port[w];
				ship_stock_at_port[w] = 0;
			end;
		end;
	end;
	create data work.check_remain_train_cap from [warehouse]=TRAIN_ROUTE
			{d in DOW_EXT}<col(d)=train_cap[warehouse,d]>;
	create data work.check_remain_ship_direct_cap from [warehouse]=SHIP_ROUTE
			{d in DOW_EXT}<col(d)=ship_direct_cap[warehouse,d]>;
	create data work.check_remain_ship_share_cap from [shared_route]=SHIP_SHAREDROUTE
			{d in DOW_EXT}<col(d)=ship_shared_cap[shared_route,d]>;

	set WH = setof{<w,p,c> in WH_PACKAGE_COLOR} w;

	var Train_cart{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} >=0 	integer;
	impvar Train{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} = 10*Train_cart[w,p,c,d];
	var Ship_shared{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} >=0 	integer;
	var Ship_direct{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} >=0 	integer;
	impvar Ship{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} = Ship_shared[w,p,c,d]+Ship_direct[w,p,c,d];
	impvar Delivery{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT}
		= Ship[w,p,c,d] + Train[w,p,c,d];

	var Alloc_train{<w,p,c> in WH_PACKAGE_COLOR,d in DOW} >=0 	integer;
	var Alloc_ship{<w,p,c> in WH_PACKAGE_COLOR,d in DOW} >=0	integer;
	var Alloc_highway{<w,p,c> in WH_PACKAGE_COLOR,d in DOW} >=0 integer;
	impvar Alloc{<w,p,c> in WH_PACKAGE_COLOR,d in DOW}
		= Alloc_ship[w,p,c,d] + Alloc_train[w,p,c,d] + Alloc_highway[w,p,c,d];
	impvar Highway{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT}
		= if d in DOW then Alloc_highway[w,p,c,d] else 0;

	var Slack_train{w in TRAIN_ROUTE, d in DOW_EXT} >=0;
	var Slack_ship_direct{w in SHIP_ROUTE, d in DOW_EXT} >=0;
	var Slack_ship_shared{s in SHIP_SHAREDROUTE, d in DOW_EXT} >=0;

	*** balance constraints (note delivery balance is greater or equal because highway can be assigned freely ***;
	con delivery_balance{<w,p,c> in WH_PACKAGE_COLOR}:
		allocation[w,p,c] >= sum{d in DOW_EXT} Delivery[w,p,c,d];
	con alloc_balance{<w,p,c> in WH_PACKAGE_COLOR}:
		allocation[w,p,c] = sum{d in DOW} Alloc[w,p,c,d];

	*** delivery capacities over ship direct/ship share/train ***;
	con train_delivery_cap{w in TRAIN_ROUTE, d in DOW_EXT: train_cap[w,d]>0}:
		train_cap[w,d] = Slack_train[w,d] + sum{<(w),p,c> in WH_PACKAGE_COLOR} Train[w,p,c,d];
	con ship_direct_delivery_cap{w in SHIP_ROUTE, d in DOW_EXT: ship_direct_cap[w,d]>0}:
		ship_direct_cap[w,d] = Slack_ship_direct[w,d] + sum{<(w),p,c> in WH_PACKAGE_COLOR} Ship_direct[w,p,c,d];
	con ship_share_route_cap{s in SHIP_SHAREDROUTE, d in DOW_EXT: ship_shared_cap[s,d]>0}:
		ship_shared_cap[s,d] = Slack_ship_shared[s,d] + sum{<w,p,c> in WH_PACKAGE_COLOR
				: w in SHIP_ROUTE and ship_shared_route[w]=s} Ship_shared[w,p,c,d];

	*** delivery and allocation cannot exceed production + stock ***;
	con delivery_ub{<p,c> in PACKAGE_COLOR,d in DOW_EXT}:
		sum{<w,(p),(c)> in WH_PACKAGE_COLOR, dd in DOW: index[dd]<=index[d]} Delivery[w,p,c,dd] 
				<= stock[p,c] + sum{dd in DOW: index[dd]<=index[d]} production[p,c,dd];
	con allocation_ub{<p,c> in PACKAGE_COLOR,d in DOW}:
		sum{<w,(p),(c)> in WH_PACKAGE_COLOR, dd in DOW: index[dd]<=index[d]} Alloc[w,p,c,dd] 
				<= stock[p,c] + sum{dd in DOW: index[dd]<=index[d]} production[p,c,dd];

	*** all production have to be allocated daily ***;
	con alloc_lb{<p,c> in PACKAGE_COLOR,d in DOW}:
		sum{<w,(p),(c)> in WH_PACKAGE_COLOR} Alloc[w,p,c,d] >= production[p,c,d];

	*** allocation >= delivery over ship/train (note allocation highway = delivery highway) ***;
	con alloc_accum_train_lb{<w,p,c> in WH_PACKAGE_COLOR,d in DOW: index[d]<7}:
		sum{dd in DOW: index[dd]<=index[d]} Alloc_train[w,p,c,dd] 
			>= sum{dd in DOW: index[dd]<=index[d]} Train[w,p,c,dd];
	con alloc_accum_ship_lb{<w,p,c> in WH_PACKAGE_COLOR,d in DOW: index[d]<7}:
		sum{dd in DOW: index[dd]<=index[d]} Alloc_ship[w,p,c,dd] 
			>= sum{dd in DOW: index[dd]<=index[d]} Ship[w,p,c,dd];

	*** in total allocation = delivery over ship/train ***;
	con alloc_accum_train_eq{<w,p,c> in WH_PACKAGE_COLOR}:
		sum{d in DOW} Alloc_train[w,p,c,d] = sum{d in DOW_EXT} Train[w,p,c,d];
	con alloc_accum_ship_eq{<w,p,c> in WH_PACKAGE_COLOR}:
		sum{d in DOW} Alloc_ship[w,p,c,d] = sum{d in DOW_EXT} Ship[w,p,c,d];

	*** allocation in day horizon {1..a} need to be delivered in day horizon {1..a+2}, i.e. 
		no stock stays at port for more than 2 days ***;
	con train_stock{<w,p,c> in WH_PACKAGE_COLOR,d in DOW}:
		sum{dd in DOW: index[dd]<=index[d]} Alloc_train[w,p,c,dd] 
		<= sum{dd in DOW_EXT: index[dd]<=index[d]+2} Train[w,p,c,dd];
	con ship_stock{<w,p,c> in WH_PACKAGE_COLOR,d in DOW}:
		sum{dd in DOW: index[dd]<=index[d]} Alloc_ship[w,p,c,dd] 
		<= sum{dd in DOW_EXT: index[dd]<=index[d]+2} Ship[w,p,c,dd];

	*** Penalize under capacitiy ***;
	min Penalty = sum{w in TRAIN_ROUTE, d in DOW_EXT} (10-index[d])*Slack_train[w,d]
			+ sum{w in SHIP_ROUTE, d in DOW_EXT} (10-index[d])*Slack_ship_direct[w,d]
			+ sum{s in SHIP_SHAREDROUTE, d in DOW_EXT} (10-index[d])*Slack_ship_shared[s,d];
	max Priority = sum{<w,p,c> in WH_PACKAGE_COLOR, d in DOW_EXT} bklg[w,p,c]*(10-index[d])
			*(Ship[w,p,c,d] + Train[w,p,c,d]) - Penalty;

	for {<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} do;
		if w not in SHIP_ROUTE then fix Ship_shared[w,p,c,d]=0;
		for {s in SHIP_SHAREDROUTE: w in SHIP_ROUTE and ship_shared_route[w]=s and ship_shared_cap[s,d]=0} fix Ship_shared[w,p,c,d]=0;
		if w not in SHIP_ROUTE or ship_direct_cap[w,d]=0 then fix Ship_direct[w,p,c,d]=0;
		if w in SHIP_ROUTE and ship_shared_route[w]='DIRECT' then fix Ship_shared[w,p,c,d]=0;
		if w not in TRAIN_ROUTE or train_cap[w,d]=0 then fix Train_cart[w,p,c,d]=0;
	end;
	solve obj Priority with milp / maxtime=100;

	/*Output solution*/
	num sol_train{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} = round(Train[w,p,c,d].sol);
	num sol_ship{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} = round(Ship[w,p,c,d].sol);
	num sol_highway{<w,p,c> in WH_PACKAGE_COLOR,d in DOW_EXT} = round(Highway[w,p,c,d].sol);
	num sol_alloc_train{<w,p,c> in WH_PACKAGE_COLOR,d in DOW} = round(Alloc_train[w,p,c,d].sol);
	num sol_alloc_ship{<w,p,c> in WH_PACKAGE_COLOR,d in DOW} = round(Alloc_ship[w,p,c,d].sol);
	num sol_alloc_highway{<w,p,c> in WH_PACKAGE_COLOR,d in DOW} = round(Alloc_highway[w,p,c,d].sol);

	create data work.sol_ship from [warehouse package color]=WH_PACKAGE_COLOR {d in DOW_EXT}<col(d)=sol_ship[warehouse,package,color,d]>;
	create data work.sol_train from [warehouse package color]=WH_PACKAGE_COLOR {d in DOW_EXT}<col(d)=sol_train[warehouse,package,color,d]>;
	create data work.sol_highway from [warehouse package color]=WH_PACKAGE_COLOR {d in DOW_EXT}<col(d)=sol_highway[warehouse,package,color,d]>;

	create data work.sol_alloc_ship from [warehouse package color]=WH_PACKAGE_COLOR {d in DOW}<col(d)=sol_alloc_ship[warehouse,package,color,d]>;
	create data work.sol_alloc_train from [warehouse package color]=WH_PACKAGE_COLOR {d in DOW}<col(d)=sol_alloc_train[warehouse,package,color,d]>;
	create data work.sol_alloc_highway from [warehouse package color]=WH_PACKAGE_COLOR {d in DOW}<col(d)=sol_alloc_highway[warehouse,package,color,d]>;

	*** solution analysis ***;
	num ship_daily{w in WH, d in DOW_EXT} = sum{<(w),p,c> in WH_PACKAGE_COLOR} sol_ship[w,p,c,d];
	num train_daily{w in WH, d in DOW_EXT} = sum{<(w),p,c> in WH_PACKAGE_COLOR} sol_train[w,p,c,d];
	num highway_daily{w in WH, d in DOW_EXT} = sum{<(w),p,c> in WH_PACKAGE_COLOR} sol_highway[w,p,c,d];
	num total_delivery_daily{w in WH, d in DOW_EXT} = ship_daily[w,d] + train_daily[w,d] + highway_daily[w,d];

	num alloc_ship_daily{w in WH, d in DOW} = sum{<(w),p,c> in WH_PACKAGE_COLOR} sol_alloc_ship[w,p,c,d];
	num alloc_train_daily{w in WH, d in DOW} = sum{<(w),p,c> in WH_PACKAGE_COLOR} sol_alloc_train[w,p,c,d];
	num alloc_highway_daily{w in WH, d in DOW} = sum{<(w),p,c> in WH_PACKAGE_COLOR} sol_alloc_highway[w,p,c,d];
	num total_alloc_daily{w in WH, d in DOW} = alloc_ship_daily[w,d] + alloc_train_daily[w,d] + alloc_highway_daily[w,d];

	create data sol_ship_daily from 	[warehouse]=WH {d in DOW_EXT}<col(d)=ship_daily[warehouse,d]>;
	create data sol_train_daily from 	[warehouse]=WH {d in DOW_EXT}<col(d)=train_daily[warehouse,d]>;
	create data sol_highway_daily from 	[warehouse]=WH {d in DOW_EXT}<col(d)=highway_daily[warehouse,d]>;
	create data sol_total_delivery_daily from 	[warehouse]=WH {d in DOW_EXT}<col(d)=total_delivery_daily[warehouse,d]>;

	create data sol_alloc_ship_daily from 	[warehouse]=WH {d in DOW}<col(d)=alloc_ship_daily[warehouse,d]>;
	create data sol_alloc_train_daily from 	[warehouse]=WH {d in DOW}<col(d)=alloc_train_daily[warehouse,d]>;
	create data sol_alloc_highway_daily from 	[warehouse]=WH {d in DOW}<col(d)=alloc_highway_daily[warehouse,d]>;
	create data sol_total_alloc_daily from 	[warehouse]=WH {d in DOW}<col(d)=total_alloc_daily[warehouse,d]>;

	set<str> ROUTES init {};
	num capcity{ROUTES, DOW_EXT} init 0;
	num shipment{ROUTES, DOW_EXT} init 0;
	for {r in SHIP_SHAREDROUTE, d in DOW_EXT} do;
		ROUTES = ROUTES union {r};
		capcity[r,d]=ship_shared_cap[r,d];
		for {w in SHIP_ROUTE: ship_shared_route[w]=r} do; 
			shipment[r,d]=shipment[r,d]+ sum{<(w),p,c> in WH_PACKAGE_COLOR} Ship_shared[w,p,c,d].sol;
		end;
	end;
	for {w in SHIP_ROUTE, d in DOW_EXT} do;
		ROUTES = ROUTES union {w};
		capcity[w,d]=ship_direct_cap[w,d];
		shipment[w,d]= sum{<(w),p,c> in WH_PACKAGE_COLOR} Ship_direct[w,p,c,d].sol;
	end;
	create data work.check_ship from [route]=ROUTES {d in DOW}<col(d)=(shipment[route,d]||'/'||capcity[route,d])>;
	create data work.check_train from [warehouse]=TRAIN_ROUTE {d in DOW}<col(d)=(train_daily[warehouse,d]||'/'||train_cap[warehouse,d])>;
quit;



