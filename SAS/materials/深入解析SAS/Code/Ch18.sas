libname ex "\\scnwex\Book\Data";

proc means data = ex.smbl N NMISS; 
	var _numeric_;
run;



%macro FreqBar(ds, varname);
proc freq data=&ds;
tables &varname / plots(only)=freqplot;
run;
%mend;
%FreqBar(ex.smbl, local)
%FreqBar(ex.smbl, creditlevel)
%FreqBar(ex.smbl, bad)
%FreqBar(ex.smbl, education)
%FreqBar(ex.smbl, indarea)
%FreqBar(ex.smbl, reason) 




proc means data = ex.smbl N nmiss min mean median max std; 
	   var age creditage delinq debtinc numemployee profitrate 
             rent revenue storearea yropen;
run;


/*ex18-2*/
proc freq data = ex.smbl; 
	tables reason*bad; 
run;

/*18-2 part2*/
proc freq data = ex.smbl; 
	tables (Creditlevel Education IndArea Local)*Bad/chisq
nocol nopercent;
run;


/*part3*/
%macro plottrend(ds, varname, obsingroup);

data temp; *生成一个仅包含待分析变量的子数据集;
	set &ds(keep = &varname  BAD);
run;

proc sort data = temp out = tmp;  *对子数据集进行排序;
	by &varname; 
run;

data tmp; *对排序完的子数据集进行分组标记;
	set tmp; 
	group = ceil(_N_ /&obsingroup);
run;

data plot; *根据分组标记，对每组内的观测求平均，将平均值存储为新的数据集plot;
	set tmp; 
	by group;
	if first.group then sum =0; 
		if last.group then do; avg = (sum/&obsingroup); output; end; 
			else sum + BAD; 
run;

proc sgplot data = plot; *画图;
	title"&varname - Bad Trend";
	series x= group y = avg / markers; 
run;
%mend;

%plottrend(ex.smbl, age, 1200)
%plottrend(ex.smbl, yropen, 600)
%plottrend(ex.smbl, revenue, 600)
%plottrend(ex.smbl, rent, 600)
%plottrend(ex.smbl, debtinc, 600)
%plottrend(ex.smbl, delinq, 600)			
%plottrend(ex.smbl, profitrate, 600)
%plottrend(ex.smbl, creditage,600)
%plottrend(ex.smbl, storearea,600)

/*ex18-3*/

%macro partition(train_percent, validate_percent);
proc sql noprint; select count(ID) into: TotalObs from ex.smbl ;quit;
%let train_obs = %sysevalf(&train_percent*&TotalObs); *训练数据集观测数;
%let validate_obs = %sysevalf(&validate_percent*&TotalObs); *验证数据集观测数;

proc surveyselect data = ex.smbl out = split seed = 9999
group = (&train_obs, &validate_obs);
run;

data smbl_train smbl_validate ;
	set split; 
	if GroupID =1 then do; drop GroupID; output smbl_train; end;
		else do; drop GroupID;output smbl_validate; end;
	run;
%mend; 
%partition(0.7, 0.3)

/*ex18-4*/
proc means data = ex.smbl n nmiss mean p90  ;
	var debtinc delinq creditage age revenue;
run;

data smbl_train_impute; 
	set smbl_train; 
	if (debtinc = . )then debtinc  = 41.78;
	if (delinq = .) then delinq = 2;
	if (creditage = .) then creditage =6.9;
	if (Age = .) then Age = 39;
	if (revenue = .) then revenue = 100349;
	drop indarea local reason;
run;


data smbl_validate_impute; 
	set smbl_validate; 
	if (debtinc = . )then debtinc  = 41.78;
	if (delinq = .) then delinq = 2;
	if (creditage = .) then creditage = 86.9;
	if (Age = .) then Age = 39;
	if (revenue = .) then revenue = 100349;
	drop indarea local reason;
run;

/*ex18-5*/
proc logistic data = smbl_train_impute desc ; 
	class creditlevel ;
	model bad = creditlevel  delinq debtinc  profitrate  revenue  yropen 
                 /selection = none; 
run;


proc logistic data = smbl_train_impute desc outdesign = work.design; 
	class creditlevel ;
	model bad = creditlevel delinq debtinc profitrate revenue yropen 
		  /selection = none; 
run;


proc logistic data = work.design desc  ; 
	model bad = creditlevel1 creditlevel3 delinq debtinc  profitrate  revenue  
		yropen /selection = none; 
run;

/*ex18-7*/
proc logistic data = work.design des coutmodel = work.estimate1 ; 
	model bad = creditlevel1 creditlevel3 delinq debtinc  profitrate  revenue  
		yropen /selection = none; 
	score data= work.design out=scores1;
run;

/*18-7 part2*/

proc logistic data = work.smbl_validate_impute desc outdesign = work.design2; 
	class creditlevel; 
	model bad = creditlevel delinq debtinc profitrate revenue yropen
		/selection = none; 
run;

proc logistic inmodel=work.estimate1 ;
	score data= work.design2 out=work.scores2;
run;

/*18-7 part3*/
proc freq data = work.scores1; 
	title ‘数据集smbl_train_impute的预测分类效果’;
	table F_BAD*I_BAD; 
run;
proc freq data = work.scores2; 
	title ‘数据集smbl_validate _impute的预测分类效果’;
	table F_BAD*I_BAD; 
run;

/*ex18-8*/
proc sort data = work.scores1 out = work.sorted_s1; by descending P_1; run;

data work.temp; 
	set work.sorted_s1; 
	group = ceil(_N_ /420);
run;

data work.plot; *根据分组标记，对每组内的观测求p值;
	set work.temp; 
	by group;
	if first.group then sum =0; 
		if last.group then
			do;
				avg = (sum/420); 
				p = (100*avg)/(859/4200); 
		output; 
			end; 
		else sum + BAD; 
run;

proc sgplot data = work.plot; *画图;
	title"训练数据集LIFT图";
	series x= group y = p / markers; 
run;


/*18-8 part2*/
proc sort data = work.scores2 out = work.sorted_s2; by descending P_1; run;

data temp; 
	set work.sorted_s2; 
	group = ceil(_N_ /180);
run;

data plot; *根据分组标记，对每组内的观测求p值;
	set temp; 
	by group;
	if first.group then sum =0; 
		if last.group then
			do; 
				avg = (sum/180); 
				p = (100*avg)/(336/1800); 
			output; 
			end; 
		else sum + BAD; 
run;
proc sgplot data = plot; *画图;
	title"验证数据集LIFT表";
	series x= group y = p / markers; 
run;
