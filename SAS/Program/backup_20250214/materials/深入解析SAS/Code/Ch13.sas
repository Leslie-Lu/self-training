data work.stock;
	title'Stock Dividends';
	length Stock $3.;
	input Stock $ div_2010 div_2011 div_2012 div_2013;
	datalines;
S1  8.4  8.2  8.4  8.1 
S2  7.9  8.9  10.4 8.9
S3  9.7  10.7 11.4 7.8
S4  6.5  7.2  7.3  7.7
S5  6.5  6.9  7.0  7.2
S6  5.9  6.4  6.9  7.4
S7  7.1  7.5  8.4  7.8
S8  6.7  6.9  7.0  7.0
S9  6.7  7.3  7.8  7.9
S10 5.6  6.1  7.2  7.0
;
run;
proc distance data=work.stock method=DCORR out=work.distdcorr;
	var interval(div_2010 div_2011 div_2012 div_2013);
	id Stock;
run;

libname ex '\\scnwex\Book\Data';


proc fastclus data=ex.food_cal maxc=5maxiter=10 out=work.clus;
	var kcal fat protein;
run;


proc cluster data = ex.nutrition
	outtree = work.tree
	method = ave ccc pseudo;
	var Magnesium_mg percent_water Protein_g Saturate_Fat_g;
	id food;
run;


Proc cluster data=work.distdcorr method=Ward outtree=work.Tree ;
	id Stock;
run;

axis1 order=(0 to 1 by 0.1);


proc tree data=work.Tree haxis=axis1 horizontal;
	height _rsq_;
	id Stock;
run;
