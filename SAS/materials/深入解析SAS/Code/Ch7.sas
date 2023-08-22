/*ex7-3*/
%let town = Detroit;

data work.city;
	input city $ state $;
	datalines;
 Detroit MI
 Chicago IL
 ;
run;

data work.city2 ;
	set work.city;
	where city = '&town';
run;

data work.city3;
	set work.city;
	where city = "&town";
run;

/*ex7-4*/

%let Custid = 9; 
%let Name9 = kirsty; 
%put &&&Name&Custid;

/*ex7-5*/
%let name = SaleQ;
data work.&name.1 work.&name.2 work.&name.3 work.&name.4;
	set sashelp.orsales;
	if (substr(quarter,5, 2) = 'Q1' ) then
		output work.&name.1;
	else if  (substr(quarter,5, 2)  = 'Q2' ) then
		output work.&name.2;
	else if (substr(quarter,5, 2) ='Q3') then
		output work.&name.3;
	else output work.&name.4;
run;

/**********************************/
%let year = 2001; 
%put year = &year; 


/*ex7-6*/
OPTIONS SYMBOLGEN;
%let Year = 2003;
data _null_;
	Current_year = &Year;
run;

/*ex7-7*/
%let year = 2001;

data orsales&year;
	set sashelp.orsales;
	if year = &year;
run;

proc print data = orsales&year;
	Title "Sales Record in Year&year";
	footnote1 "Created &systime &sysday, &sysdate9";
	footnote2 "on the &sysscp System Using SAS &sysver";
run;

%SYMDEL year; 
%put &year;
%SYMDEL sysday; 

/*ex7-8*/
%put eval(2+2) =  %eval(2+2);
%put eval(7/4) = %eval(7/4);
%put eval(10 gt 2) = %eval(10 gt 2);
%put eval(2+2.1) = %eval(2+2.1);

/*ex7-9*/
%let a = 2; 
%let b = 2.1;
%put The result with SYSEVALF is: %sysevalf(&a + &b);
%put BOOLEAN conversion: %sysevalf(&a + &b, boolean);
%put INTEGER conversion: %sysevalf(&a + &b, integer);
%put CEIL conversion: %sysevalf(&a +&b, ceil);
%put FLOOR conversion: %sysevalf(&a +&b, floor);

OPTIONS NOSYMBOLGEN:
/*ex7-10*/
%let text1 = %str(A AND B);
%let text2 = %str(Joan%'s Report);
%put text1: &text1;
%put text2: &text2;

/*ex7-11*/
%let Period = %str(Jan&Feb); 
%put Period resolved to : &Period; 
%let Period = %nrstr(Jan&Feb); 
%put Peorid resolved to : &Period; 

/*ex7-12*/
OPTIONS MCOMPILENOTE = ALL;
%macro time;
	%put The current time is %sysfunc(time(),timeampm.);
%mend time;
title;
footnote; 
/*ex7-13*/
%macro count(opts, start, stop);
	proc freq data = sashelp.orsales;
		where year between &start and &stop;
		table product_line/&opts;
			title1 "Order Between &start and &stop ";	
	run;
%mend count;

%count(nocum, 1999, 2000)


/*ex7-14*/
%macro count(opts= , start=1999, stop=2000);
 proc freq data = sashelp.orsales;
  where year between &start and &stop; 
  table product_line/&opts; 
  title1 "Order between &start and &stop"; 
  run;
%mend count;
%count()
%count(opts = nocum nopercent)
%count(stop=2000, opts = nocum)

/*ex7-15*/
%macro count(opts , start=1999, stop=2000);
	proc freq data = sashelp.orsales;
		where year between &start and &stop;
		table product_line/&opts;
			title1 "Order between &start and &stop";
	run;
%mend count;

%count(2000, nocum, 2001)
%count(nocum, start = 2000, stop = 2001)
%count(, start = 2000, stop = 2001)


/*ex7-15*/
%macro NullMacro;
	%let i = 1;
	%put inside macro i = &i;
%mend NullMacro;
%NullMacro;
%put outside macro i = &i;


/*ex7-16*/
%macro NullMacro;
%global i; 
%let i = 1;  
%put inside macro i = &i;
%mend NullMacro;
%NullMacro; 
%put outside macro i = &i;


/*ex7-17*/
%macro outer;
	%local x; 
	%let x=1; 
	%inner
%mend outer; 
%macro inner;
	%local y ;
	%let y = &x; 
	%PUT y=&y; 
%mend inner ;   
%let x = 0; 
%outer; 

/*ex7-18*/
/*no code*/


/*ex7-19*/
data order_fact;
	informat order_date ddmmyy10.;
	input order_date order_type quantity retail_price;
	datalines;
	05/01/2013 1 1 117.60
	07/02/2013 2 2 656.6
	07/02/2013 1 2 129.0
	09/02/2013 1 2 36.2
	16/02/2013 2 1 29.4
	27/02/2013 1 5 192.0
	;
run;

%let month = 2;
%let year = 2013;

data orders;
	keep order_date order_type quantity retail_price;
	set order_fact end=final;
	where year(order_date)=&year and month(order_date)=&month;
	if order_type=3 then Number+1;
	if final then do;
			put Number=;
			if Number=0 then do;
					%let foot= No Type 3 Order;
			end;
			else do;
					%let foot= Some Type 3 Order;
				end;
		end;
run;

proc print data=orders;
    format order_date mmddyy10.;
	title "Order in &year-&month";
	footnote "&foot";
run;

/*ex7-20*/

%let month = 2;
%let year = 2013;
data orders;
	keep order_date order_type quantity retail_price;
	set order_fact end=final;
	where year(order_date)=&year and month(order_date)=&month;
	if order_type=3 then Number+1;
	if final then do;
			put Number=;
			if Number=0 then do;
					call symputx('foot',' No Type 3 Order ');
			end;
			else do;
					call symputx('foot',' Some Type 3 Order ');
				end;
		end;
run;

proc print data=orders;
	title "Order in &year-&month";
	footnote "&foot";
run;


/*ex7-21*/
footnote; title;

%let L1 = easy; 
%let L2 = moderate; 
%let L3 = hard; 

data work.student;
	input name $ level $;
	datalines;
  Steve L1
  Jim L2
  Abby L1
  Scott L3
  Peter L2
  ;
run;

data work.student_level;
	set work.student;
	intensity = symget(level);
run;

proc print data = work.student_level noobs;
	title"Using SYMGET Function in DATA Step";
run;

/*ex7-22*/
proc sql noprint; 
 select sum(profit) format = dollar8. into: total
 from sashelp.orsales
 where quarter = '1999Q1'; 
quit;
%put the total profit of 1991Q1 is: &total;


/*ex7-23*/
proc sql noprint; 
	select distinct product_line into: all_product_lines 
         separated by ', '
	from sashelp.orsales; 
quit; 
%put all distinct product lines are: &all_product_lines;

/*ex7-24*/
%let place = Us;
%macro empty; 
	%if &place = US %then %put Not case sensitive; 
	%else %put macro comparison is case sensitive; 
%mend; 
%empty



/*ex7-25 this not executable since it depends on date. 
thus, the data daily_order is not included*/

%macro reports;
    %if &sysday=Friday %then 
        %do;
            proc means data=daily_order n sum mean;
                where order_date between "&sysdate9"d-6 and "&sysdate9"d;
                var quantity total_price;
                title "Weekly sales: &sysdate9";
            run;
        %end;
    %else 
        %do;  
           proc sql; 
 	      select *
     		from daily_order
         	    where order_date="&sysdate9"d;
               title "Daily sales: &sysdate9";
 	  quit; 
        %end; 
%mend reports;
%reports



/*ex7-26*/
%macro func1;
    %do i=1 %to 3; 
    %end;  
    %put inside func1; 
%mend; 
%macro func2; 
    %do i=1 %to 3; 
	%func1
	%put func2;
    %end; 
%mend; 
%func2

/*ex7-27*/
data _null_;
	set sashelp.class end=no_more;
	call symput('name'||left(_N_),(trim(name)));
	if no_more then
		call symput('count',_N_);
run;
%macro putloop;
	%local i;
	%do i=1 %to &count;
		%put name&i is &&name&i;
	%end;
%mend 
%putloop;


/*ex7-28*/
%macro print_multiplies(dsns);
	%let i = 1;
	%let current_data = %scan(&dsns, &i,' ');
	%do %while (&current_data ne );
		proc print data = &current_data;
		run;
		%let i=%eval(&i+1);
		%let current_data = %scan(&dsns, &i, ' ');
	%end;
%mend;

%print_multiplies(sashelp.class sashelp.classfit)

