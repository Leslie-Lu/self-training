/*ex6-1*/
title;

proc sql;
	title"Generating A New Column";
	select cars.make, cars.model, cars.msrp, cars.msrp*0.06 as tax 
		from sashelp.cars;
quit;

/*ex6-2*/
proc sql;
	title "不使用distinct关键字";
	select make from sashelp.cars;
	title "使用distinct关键字";
	select distinct make from sashelp.cars;
quit;

/*ex6-3*/
proc sql;
	select cars.make, cars.model, cars.msrp, cars.msrp*0.06 as tax 
		from sashelp.cars
			where msrp<=40000;
quit;

proc sql;
	select cars.make, cars.model, cars.msrp, cars.msrp*0.06 as tax 
		from sashelp.cars
			where tax <= 2400;
quit;

/*ex6-4*/
proc sql;
	select cars.make, cars.model, cars.msrp, cars.msrp*0.06 as tax 
		from sashelp.cars
			where calculated tax <= 2400;
quit;

/*ex6-5*/
proc sql;
	select cars.make, cars.model, cars.msrp, cars.msrp*0.06 as tax 
		from sashelp.cars
			where calculated tax<=2400
				order by msrp, make desc, model;
quit;

/*ex6-6*/
proc sql;
	select count(distinct make) as number_of_maker
		from sashelp.cars;
quit;

/*ex6-7*/
proc sql;
	select count(distinct cats(make, model) ) as N_combination
		from sashelp.cars;
quit;

/*ex6-8*/
proc sql;
	select make , avg(msrp) as average_price
		from sashelp.cars
			group by make
				order by calculated average_price;
quit;

/*ex6-9*/
proc sql;
	select make , avg(msrp) as average_price
		from sashelp.cars
			group by make
				having average_price <= 20000 
					order by make;
quit;

footnote;

/*ex6-10*/
proc sql outobs = 10 number;
	title "The First Ten Car Models In The List";
	select distinct cars.make, cars.model
		from sashelp.cars;
quit;

/*ex6-11*/
proc sql outobs = 10 number;
	title "The first ten car models in the list";
	create table work.fist_ten_models as 
		select distinct cars.make, cars.model
			from sashelp.cars;
quit;

footnote;

/*ex6-12*/
data work.spending;
	input ID max_spending;
	datalines;
	 1 16000
 	 2 20000
 	 3 24000
 	 4 18000
 	 5 23000
	 ;
run;

proc sql;
	title" Recommended Brands";
	select cars.make, avg(cars.msrp) as avg_msrp
		from sashelp.cars
			group by cars.make
				having avg(cars.msrp) <= (select avg(max_spending) from work.spending);
quit;

/*ex6-13*/
data donors;
	input name$ amount;
	datalines;
 	 John 5000
 	 Chirs 10000
 	 Peter 7000
 	 Paul 6500
 	 Aby 20000
 	 Tracy 15000
 	 ;
run;

data donor_current;
	input name$;
	datalines;
	John
 	Peter
  	Tracy
	;
run;

proc sql;
	title"Donors From Other Years";
	select * from donors
		where not exists(
			select name from donor_current
				where donor_current.name = donors.name);
quit;

/*ex6-14*/
data work.class;
	input name $ sex $ age height;
	datalines;
	Alice F 14 56.5
	Carol F 14 62.8
	James M 12 57.3 
	;
run;

data work.classfit;
	input student_name $ weight;
	datalines;
	James 83
	Carol 102.5
	;
run;

proc sql;
	title "Students Fitness ";
	select c.name, c.sex, c.age, c.height, cfit.weight
		from work.class as c, work.classfit as cfit
			where c.name = cfit.student_name;
quit;

title;

/*ex6-15*/
data a;
	input x value1 $;
	datalines;
	  1 a
	  2 b
	  5 d
  	  ;
run;

data b;
	input x value2 $;
	datalines;
	  2 x
	  3 c
 	  4 v
	  ;
run;

proc sql;
	select *
		from a 连接条件 b
			on a.x = b.x;
quit;

proc sql;
	footnote"连接条件：left join";
	select *
		from a left join b
			on a.x = b.x;
quit;

proc sql;
	footnote"连接条件：right join";
	select *
		from a right join b
			on a.x = b.x;
quit;

proc sql;
	footnote"连接条件：full join";
	select *
		from a full join b
			on a.x = b.x;
quit;

title;
footnote;
/*ex6-16*/
data a;
	input ID X$;
	datalines;
 1 a 
 1 b
 1 c
 1 a
 2 b
 ;
run;

data b;
	input ID Y$;
	datalines;
1 b
2 b
3 c 
3 c
4 d
;
run;

proc sql;
	title "Combining Two Tables Vertically Using EXCEPT";
	Select * from A
		Except 
	Select * from B
	;
quit;

proc sql;
	title "Combining Two Tables Vertically Using EXCEPT ALL";
	Select * from A
		Except all
	Select * from B
	;
quit;

/*ex6-17*/
proc sql;
	title "Combining Two Tables Vertically Using EXCEPT CORR";
	Select * from B
		Except corr
	Select * from A
	;
quit;

/*ex6-18*/
proc sql;
	title "Combining Two Tables Vertically Using EXCEPT CORR ALL";
	select * from B
		except corr all
	select * from A
	;
quit;

/*ex6-19*/
data a;
	input ID X$;
	datalines;
 1 a 
 1 a
 2 b
 3 c
 ;
run;

data b;
	input ID Y$;
	datalines;
1 a
1 b
3 c 
3 d
;
run;

title;

proc sql;
	footnote "连接方式1：intersect";
	select * from A
		intersect
	select * from B
	;
quit;

proc sql;
	footnote "连接方式2：intersect all";
	select * from A
		intersect all
	select * from B
	;
quit;

proc sql;
	footnote "连接方式3：intersect all corr";
	select * from A
		intersect all corr
	select * from B
	;
quit;

/*ex6-20*/
footnote;

proc sql;
	title"Combining Two Tables Vertically Using UNION";
	select * from a
		union
	select * from b;
quit;

/*ex6-21*/
proc sql;
	title"Combining Two Tables Vertically Using UNION ALL";
	select * from a
		union all
	select * from b;
quit;

/*ex6-22*/
title;
footnote;

proc sql;
	title"Combining Two Tables Vertically Using UNION CORR";
	select * from A
		union corr
	select * from B;
quit;

/*ex6-23*/
proc sql;
	title"Combining Two Tables Vertically Using UNION ALL CORR";
	select * from A
		union all corr
	select * from B;
quit;

/*ex6-24*/
data a;
	input ID X$;
	datalines;
 1 a 
 1 a
 2 b
 ;
run;

data b;
	input ID Y$;
	datalines;
2 b
3 c 
1 a
;
run;

proc sql;
	title"表1";
	footnote "连接方式：outer union";
	select * from a
		outer union
			select * from b;
quit;

proc sql;
	title"表2";
	footnote "连接方式：outer union corr";
	select * from a
		outer union corr 
			select * from b;
quit;

/*ex6-25*/
proc sql;
	describe table sashelp.class;
quit;

/*ex6-26*/
proc sql;
	create table work.new_class 
		like sashelp.class;
quit;

/*ex6-27*/
proc sql;
	drop table work.new_class;
quit;

footnote;

/*ex6-28*/
proc sql;
	title"New_class";
	insert into new_class
		set Name = 'Meaghan', 
			Sex = 'F', 
			Age=19,
			Height = 56,
			Weight = 140
		set Name = 'Jack', 
			Sex = 'M', 
			Age=21,
			Height = 63,
			Weight = 160;
	title "Insert New Observations Using SET";
	select * from new_class
	;
quit;

/*ex6-29*/
proc sql;
	insert into new_class (Name, Sex, Age, Height, Weight)
		values ('Meaghan', 'F', 19, 56, 140)
		values ('Jack', 'M', 21, 63, 160);
	title "Insert New Observations Using VALUE";
	select * from new_class;
quit;

/*ex6-30*/
proc sql;
	insert into new_class 
		select Name, Sex, Age, Height, Weight
			from sashelp.classfit
				where Age=12;
	title"Insert New Observations Using Query Results";
	select * from new_class;
quit;

/*ex6-30*/
proc sql;
	create table class as 
		select * from sashelp.class;
quit;

proc sql;
	delete from class 
		where (class.weight/class.height)>1.5;
quit;

/*ex6-13*/
proc sql;
	title"其它年份的捐款人";
	select * from donors
		where not exists(
			select name from donor_current
				where donor_current.name = donors.name);
quit;

/*ex6-14*/
data cars_copy;
	set sashelp.cars;;
run;

proc sql;
	create table cars_copy as 
		select * from sashelp.cars;
quit;

/*ex6-15*/
proc sql;
	create table new_class 
		(
		Name char(12) label='姓名',
		Sex char(4) label='性别',
		Age num label='年龄',
		Height num label='身高（英寸）',
		Weight num label='体重（磅）'
		)
	;
quit;

proc sql;
	create table new_class 
		like sashelp.class;
quit;

/*ex6-16*/
proc sql;
	create table new_class (drop = Age)
		like sashelp.class;
quit;

/*ex6-17*/
proc sql;
	title"New_class";
	insert into new_class
		set Name = 'Meaghan', 
			Sex = 'F', 
			Age=19,
			Height = 56,
			Weight = 140
		set Name = 'Jack', 
			Sex = 'M', 
			Age=21,
			Height = 63,
			Weight = 160;
	title "使用set语句插入新的观测值";
	select * from new_class
	;
quit;

/*ex6-18*/
proc sql;
	insert into new_class (Name, Sex, Age, Height, Weight)
		values ('Meaghan', 'F', 19, 56, 140)
		values ('Jack', 'M', 21, 63, 160);
	title "使用value语句插入新的观测值";
	select * from new_class;
quit;

/*ex6-19*/
proc sql;
	insert into new_class 
		select Name, Sex, Age, Height, Weight
			from sashelp.classfit
				where Age=12;
	title"将查询结果插入表中";
	select * from new_class;
quit;

/*ex6-20*/
proc sql;
	create table class as 
		select * from sashelp.class;
quit;

proc sql;
	delete from class 
		where (class.weight/class.height)>1.5;
quit;

/*ex6-21*/
proc sql;
	create table class as 
		select * from sashelp.class;
quit;

proc sql;
	update class 
		set height = height*1.05, weight = weight *1.05 where age in (11, 12);
	update class 
		set height = height*1.06, weight = weight *1.05 where age in (13, 14);
	update class 
		set height = height*1.04, weight = weight *1.05 where age in (15, 16);
	update class
		set age = age+1;
quit;

proc sql outobs=6;
	title "更新前后对比";
	select class.* ,c.Age as age_before label= '原年龄', 
		c.Height as h_before  label = '原身高', 
		c.Weight as w_before label = '原体重'
	from class, sashelp.class as c
		where class.name = c.name;
quit;

/*ex6-22*/
proc sql;
	create table class as 
		select * from sashelp.class;
quit;

proc sql;
	update class 
		set height = height*
			case 
				when age in (11, 12) then 1.05
				when age in (13, 14) then 1.06
				else 1.04
	end;

	update class 
		set weight = weight*
			case 
				when age in (11, 12) then 1.05
				when age in (13, 14) then 1.06
				else 1.04
	end;

	update class 
		set age = age+1;
quit;

proc sql outobs=6;
	title "更新前后对比（2）";
	select class.* ,c.Age as age_before label= '原年龄', 
		c.Height as h_before  label = '原身高', 
		c.Weight as w_before label = '原体重'
	from work.class, sashelp.class as c
		where class.name = c.name;
quit;

/*ex 6-23*/
proc sql;
	create table work.class as 
		select * from sashelp.class;
quit;

proc sql;
	alter table work.class 
		add Student_ID num format = 4., 
			Boarding char(1)
		drop Age, Sex
			modify Height format = 8.1 label = 'ModifiedHeight';
quit;

proc sql;
	title"使用SQL修改后的表";
	select * from work.class;
	title"修改前的表";
	select * from sashelp.class;
quit;

/*ex 6-24*/
proc contents data = class nodetails;
run;

proc sql;
	select count(make model) as N;
quit;

data income;
	input ID max_spending;
	datalines;
 1 16000
 2 20000
 3 24000
 4 18000
 5 23000
 ;
run;

proc print data = income noobs;
	title"计划用与买车的支出";
run;

proc sql;
	title"推荐的汽车品牌";
	select cars.make, avg(cars.msrp) as avg_msrp
		from sashelp.cars
			group by cars.make
				having avg(cars.msrp) <=
					(select avg(max_spending) from income);
quit;

data income2;
	input ID max_spending brand;
	datalines;
 1 16000 Satrun
 2 20000 MINI
 3 24000 KIA
 4 18000 Satrun
 5 23000 Suzuki
 ;
run;

data employee;
	length name $10;
	input name$ dept$ salary;
	datalines;
 Chris D1 100000
 James D1 85000
 Meaghean D1 65000
 Melissa D2 76000
 Kirsty D2 80000
 Bryan D2 65000
 ;
run;

proc print data = a noobs;
	title"表格 A";
run;

proc print data = b noobs;
	title"表格 B";
run;

title;

proc sql;
	footnote "左连接";
	select *
		from a left join b
			on a.x = b.x;
quit;

proc sql;
	footnote "右连接";
	select *
		from a right join b
			on a.x = b.x;
quit;

proc sql;
	footnote "全连接";
	select *
		from a full join b
			on a.x = b.x;
quit;

footnote;

proc print data = a noobs;
	title"表格 A";
run;

proc print data = b noobs;
	title"表格 B";
run;

proc sql;
	title "表1";
	footnote"命令1：intersect";
	select * from a
		intersect 
	select * from b
	;

proc sql;
	title "表2";
	footnote"命令2：intersect all";
	select * from a
		intersect all
	select * from b
	;

proc sql;
	title "表3";
	footnote"命令1：intersect all corr";
	select * from a
		intersect all corr
	select * from b
	;

proc sql;
	title;
	footnote;
	select * from a
		union 
	select * from b
	;

proc sql;
	title;
	footnote "使用命令union all合并表格";
	select * from a
		union all
	select * from b
	;

data c;
	input ID X $;
	datalines;
   1 A
   1 A
   1 A
   1 B
   2 B
   3 C
   3 C
   3 D
  ;
run;

proc print data = c noobs;
	title;
	footnote"使用union合并表格过程中生成的表格";
run;

footnote;
title;

proc sql;
	select distinct make, model
		from sashelp.cars;
quit;

proc sql;
	create table new_class 
		(
		Name char(12) label='姓名',
		Sex char(4) label='性别',
		Age num label='年龄',
		Height num label='身高（英寸）',
		Weight num label='体重（磅）'
		)
	;
quit;

proc sql;
	title"New_class";
	insert into new_class
		set Name = 'Meaghan', 
			Sex = 'F', 
			Age=19,
			Height = 5.6,
			Weight = 140
		set Name = 'Jack', 
			Sex = 'M', 
			Age=21,
			Height = 6.3,
			Weight = 160;
	title "使用set语句插入新的观测值";
	select * from new_class
	;
quit;

proc sql;
	insert into new_class (Name, Sex, Age, Height, Weight)
		values ('Meaghan', 'F', 19, 5.6, 140)
		values ('Jack', 'M', 21, 6.3, 160);
	title "使用value语句插入新的观测值";
	select * from new_class;
quit;

proc sql;
	insert into new_class 
		select Name, Sex, Age, Height, Weight
			from sashelp.classfit
				where Age=12;
	title"将查询结果插入表中";
	select * from new_class;
quit;

proc sql;
	create table class as 
		select * from sashelp.class;
quit;

proc sql;
	update class 
		set height = height*1.05, weight = weight *1.05 where age in (11, 12);
	update class 
		set height = height*1.06, weight = weight *1.06 where age in (13, 14);
	update class 
		set height = height*1.04, weight = weight *1.04 where age in (15, 16);
	update class
		set age = age+1;
quit;

proc sql outobs=6;
	title "更新前后对比";
	select class.* ,c.Age as age_before , 
		c.Height as h_before , 
		c.Weight as w_before 
	from class, sashelp.class as c
		where class.name = c.name;
quit;

proc sql;
	create table class as 
		select * from sashelp.class;
quit;

proc sql;
	update class 
		set height = height*
			case 
				when age in (11, 12) then 1.05
				when age in (13, 14) then 1.06
				else 1.04
	end;

	update class 
		set weight = weight*
			case 
				when age in (11, 12) then 1.05
				when age in (13, 14) then 1.06
				else 1.04
	end;

	update class 
		set age = age+1;
quit;

proc sql outobs=6;
	title "更新前后对比(2)";
	select class.* ,c.Age as age_before , 
		c.Height as h_before , 
		c.Weight as w_before 
	from class, sashelp.class as c
		where class.name = c.name;
quit;

proc sql;
	title"New_class";
	insert into new_class
		set Name = 'Meaghan', 
			Sex = 'F', 
			Age=19,
			Height = 56,
			Weight = 140
		set Name = 'Jack', 
			Sex = 'M', 
			Age=21,
			Height = 63,
			Weight = 160;
	title "使用set语句插入新的观测值";
	select * from new_class
	;
quit;

proc sql;
	insert into new_class (Name, Sex, Age, Height, Weight)
		values ('Meaghan', 'F', 19, 56, 140)
		values ('Jack', 'M', 21, 63, 160);
	title "使用value语句插入新的观测值";
	select * from new_class;
quit;

proc sql;
	insert into new_class 
		select Name, Sex, Age, Height, Weight
			from sashelp.classfit
				where Age=12;
	title"将查询结果插入表中";
	select * from new_class;
quit;

proc sql;
	select c.*, (c.weight/c.height)as ratio
		from sashelp.class as c;
quit;

proc sql;
	create table class as 
		select * from sashelp.class;
quit;

proc sql;
	delete from class 
		where (class.weight/class.height)>1.5;
quit;

data spending;
	input ID max_spending;
	datalines;
 1 16000
 2 20000
 3 24000
 4 18000
 5 23000
 ;
run;

proc print data = spending  noobs;
	title"计划用与买车的支出";
run;

proc contents data = sashelp.class nodetails;
run;

proc sql;
	select c2.*
		from sashelp.class as c1, sashelp.classfit as c2
			where c1.name = c2.name;
quit;

footnote1 "创建于 &systime &sysday, &sysdate9";
footnote2 "&sysscp 操作系统 SAS &sysver";

data orsales2001;
	set sashelp.orsales;

	if year = 2001;
run;

proc print data = orsales2001;
	title "2001年的销售记录";
	footnote1 "创建于 22：01 Monday, 21OCT2013";
	footnote2 "WIN 操作系统 SAS 9.3";
run;

%let year = 2001;

data orsales&year;
	set sashelp.orsales;

	if year = &year;
run;

proc print data = orsales&year;
	Title "&year 的销售记录";
	footnote1 "创建于 &systime &sysday, &sysdate9";
	footnote2 "&sysscp 操作系统 SAS &sysver";
run;

OPTIONS SYMBOLGEN;
%let year = 2001;

data _null_;
	current_year = &year;
run;

OPTIONS NOSYMBOLGEN;
%let year = 2001;
%put The value of the macro variable year is: &year;
%let name = quarter;

data &name.1 &name.2 &name.3 &name.4;
	set sashelp.orsales;

	if (substr(quarter,5, 2) = 'Q1' ) then
		output &name.1;
	else if  (substr(quarter,5, 2)  = 'Q2' ) then
		output &name.2;
	else if (substr(quarter,5, 2) ='Q3') then
		output &name.3;
	else output &name.4;
run;
