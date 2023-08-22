
**ex9.1***;
proc means data=sashelp.fish mean median mode maxdec=2;
	title "Descriptive Statistics of Tendency";
	var weight length1 length2 length3 height width;
run;

**ex9.2***;
proc means data=sashelp.fish mean std var cv range qrange;
	title "Descriptive Statistics of Dispersion";
	var weight length1 length2 length3 height width;
run;
proc means data=sashelp.fish mean;
	title "Descriptive Statistics of Tendency Using Class";
	class species;
	var weight;
run;

**ex9.3**;
proc freq data=sashelp.fish;
	tables species / missing; /*treat missing values as nonmissing*/
run;
proc univariate data=sashelp.fish plot;
	where species="Bream";
	title "Descriptive Statistics Using Proc Univariate";
	var height;
	histogram / normal(mu=est sigma=est) kernel;
	probplot / normal(mu=est sigma=est);
	inset skewness kurtosis / position=ne;
run;

**ex9.4***;
proc means data=sashelp.shoes mean median sum std;
	title "Output Descriptive Statistics to SAS Dataset";
	class region product;
	var sales inventory;
	output out=work.outstat mean(sales)=sales_mean sum(sales)=sales_sum mean(inventory)=invnt_mean sum(inventory)=invnt_sum;
run;
proc print data=work.outstat;
run;
***********;
proc means data=sashelp.shoes noprint nway;
	title "Output Decsriptive Statistics to SAS Dataset";
	class region product;
	var sales inventory;
	output out=work.outstat mean(sales)=sales_mean sum(sales)=sales_sum mean(inventory)=invnt_mean sum(inventory)=invnt_sum;
run;
proc print data=work.outstat;
run;

