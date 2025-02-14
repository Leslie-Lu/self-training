libname ex "\\scnwex\Book\Data";

****Ex 17.1*****;
proc timeseries data=ex.stockdaily out=ex.stockmonthly;
	id date interval=month
	          accumulate=average
		 setmissing=missing
		 start="01Oct1995"d end="28Feb2011"d;
	var volume;
run;

***Ex 17.2*****;

proc expand data=ex.stockdaily
			  out=work.stockdaily
			  from=weekday
			  align=beginning
			  method=none;
	id date;
	convert volume;
	convert logvolume;
	where date>='01Jan2010'd;
run;

*****Ex 17.3****;

proc arima data=work.stockdaily;
	/*identify the series initially*/
	identify var=volume nlag=12;
	where date>="01Jan2010"d;
	run;
quit;


*******Ex 17.4********;

/*----  Simulated Series   ----*/

data work.armaExamples; 
   array Y(8); 
   array LagY(8); 
   array Lag2Y(8); 
   /*----  (1) Initialize all 8 series to mean 0  ----*/ 
   do i=1 to 8; 
      LagY(i)=0; 
      Lag2Y(i)=0; 
   end; 
   LagError=0;
   Lag2Error=0;  

   /*----  (2) Generate as labeled  ----*/
   do t=-100 to 1600; 
      Date = intnx('day','31dec2006'd,t); 
      error = normal(1234567);  
      Y(1) = 0.9*LagY(1) + error;                       * AR(1) ;
      Y(2) = 0.1*LagY(2) + 0.72*Lag2Y(2) + error;      * AR(2) ; 
      Y(3) = 1.8*cos(2*constant('pi')/9)*LagY(3) - 0.81*Lag2Y(3) + error; * AR(2) complex roots;
      Y(4) = error - 0.9*LagError;                       * MA(1) ; 
      Y(5) = error - 0.1*LagError -0.72*Lag2Error;      * MA(2) ; 
      Y(6) = error - 1.8*cos(2*constant('pi')/9)*LagError + 0.81*Lag2Error; * MA(2) complex roots; 
      Y(7) = 0.9*LagY(7) + error + 0.8*LagError;         * ARMA(1,1);
      Y(8) = error;                                       * white noise;        
	  if t>0 then output; 
      Lag2Error=LagError; 
      LagError=error; 
      do i=1 to 8; 
         Lag2Y(i)=LagY(i); 
         LagY(i)=Y(i); 
      end; 
   end; 
   keep t date Y1-Y8;
run;

proc arima data=work.armaExamples plots=series(corr);
	identify var=Y1 nlag=12;
	identify var=Y2 nlag=12;
	identify var=Y3 nlag=12;
	identify var=Y4 nlag=12;
	identify var=Y5 nlag=12;
	identify var=Y6 nlag=12;
	identify var=Y7 nlag=12;
	identify var=Y8 nlag=12;
run;
quit;

*****Ex 17.5 *****;

proc timeseries data=work.armaExamples plots=(corr acf pacf iacf);
	var Y1;
	id date interval=day;
run;

*****Ex 17.6******;

/*----  ESACF  ----*/
proc arima data=work.armaExamples;
	identify var=Y7 nlag=12
		     esacf 
			 p=(0:12) q=(0:12) perror=(3:12);
run;

/*----  SCAN  ----*/
proc arima data=work.armaExamples;
	identify var=Y7 nlag=12
		     scan 
			 p=(0:12) q=(0:12) perror=(3:12);
run;

/*----  MINIC  ----*/
proc arima data=work.armaExamples;
	identify var=Y7 nlag=12
		     minic 
			 p=(0:12) q=(0:12) perror=(3:12);
run;

proc arima data=work.armaExamples;
	identify var=Y7 nlag=12
		     minic esacf scan
			 p=(0:12) q=(0:12) perror=(3:12);
run;

*****Ex 17.7******;

proc arima data=work.armaExamples;
	identify var=Y7 nlag=12 noprint;
	estimate p=1 q=1 ml;
run;

proc arima data=work.armaExamples;
	identify var=Y7 nlag=12 noprint;
	estimate p=1 q=1 method=ml outest=work.armap1q1;
run;

proc arima data=work.armaExamples plots(only)=(forecast(forecast));
	identify var=Y7 nlag=12 noprint;
	estimate p=1 q=1 method=ml ;
	forecast lead=60 id=date interval=day out=work.forecasting;
run;
quit;


****Ex 17.8*****;

proc arima data=ex.weeklysales plots=all plots(unpack);
	identify var=part1 nlag=14
			 esacf minic scan 
			 p=(0:12) q=(0:12) perror=(3:12);
run;

proc arima date=ex.weeklysales plots=all plots(unpack);
	identify var=part2 nlags=14
			 esacf minic scan 
			 p=(0:12) q=(0:12) perror=(3:12);
	identify var=part3 nlags=14
			 esacf minic scan 
			 p=(0:12) q=(0:12) perror=(3:12);
run;

proc arima data=ex.weeklysales plots(only)=(forecast(forecast));
	identify var=part1 noprint;
	estimate p=(2 3) ml outest=work.est_part1 noprint;
	forecast lead=8 id=date interval=week out=work.forecast_part1;
	identify var=part2 noprint;
	estimate p=1  ml outest=work.est_part2 noprint;
	forecast lead=8 id=date interval=week out=work.forecast_part2;
	identify var=part3 noprint;
	estimate q=4 outest=work.est_part3 noprint;
	forecast lead=8 id=date interval=week out=work.forecast_part3;
run;

proc arima data=ex.weeklysales;
	identify var=part1 noprint;
	estimate p=2 ml outest=work.est_part1;
/*	identify var=part2 noprint;*/
/*	estimate p=1 ml outest=work.est_part2;*/
/*	identify var=part3 noprint;*/
/*	estimate q=3 ml outest=work.est_part3;*/
run;
quit;


****Ex 17.10****;
proc arima data=ex.production plots=(forecast(forecast)) ;
	identify var=prod(1) nlag=12 stationarity=(adf=(0 1));
	estimate q=1  ml;
	forecast lead=10;
run;

****Ex 17.9*****;

data work.testdata;
	do t=1 to 50;
		var1=4+3*t+5*rannor(999999);
		var2=4+3*t+2*t*t+500*rannor(999997);
		var3=4+3*log(t)+rannor(9999991);
		output;
	end;
run;

data work.testdata;
	set work.testdata end=eof;
	attrib _LINEAR_ label="Linear Term"
		   _QUAD_    label="Quadratic Term"
		   _LOG_     label="Logarithm Term"; 
	retain _LINEAR_ 0;
	_LINEAR_+1;
	_QUAD_=_LINEAR_*_LINEAR_;
	_LOG_=log(_LINEAR_);
	output;
	if eof then do future=1 to 10;
		t+1;
		_LINEAR_+1;
		var1=.;
		var2=.;
		var3=.;
		_QUAD_=_LINEAR_*_LINEAR_;
		_LOG_=log(_LINEAR_);
		output;
	end;
run;

proc arima data=work.testdata plots(only)=(forecast(forecast));
	identify var=var1 cross=(_LINEAR_);
	estimate input=(_LINEAR_) ml;
	forecast lead=10 ;
	identify var=var2 cross=(_LINEAR_ _QUAD_);
	estimate input=(_LINEAR_ _QUAD_) ml;
	forecast lead=10;
	identify var=var3 cross=(_LOG_);
	estimate input=(_LOG_) ml;
	forecast lead=10;
run;

****Ex 17.11****;

proc timeseries data=ex.demanding out=work.temp
				  print=(descstats)
				  plot=(series decomp tcc sc corr acf pacf iacf wn)
				  seasonality=12;
	id date interval=month;
	var demand;
	decomp tcc sc / mode=mult;
run;

proc arima data=ex.demanding plots=all;
	identify var=demand stationarity=(adf=(0 1 2));
run;
quit;

data work.demanding;
	set ex.demanding end=eof;
	_LINEAR_+1;
	_SQUARE_=_LINEAR_*_LINEAR_;
	output;
	if eof then do t=1 to 24;
		_LINEAR_+1;
		_SQUARE_=_LINEAR_*_LINEAR_;
		demand=.;
		date=intnx('month',date,1);
		output;
	end;
	drop t;
run;


proc arima data=work.demanding plots=all ;
	identify var=demand noprint;
	estimate/* p=1  ml*/;
/*	forecast lead=12 id=date interval=month out=work.AR1;*/
run;

proc arima data=work.demanding plots=all;
	identify var=demand(1) nlag=12 noprint;
	estimate p=1 ml ;
	forecast lead=12 id=date interval=month out=work.D1_AR1;
run;

proc arima data=work.demanding plots=all;
	identify var=demand crosscorr=(_linear_ _square_) noprint;
	estimate input=(_linear_ _square_) ml;
	forecast lead=0 out=work.resi;
run;
quit;

/*proc arima data=work.resi;*/
/*	identify var=RESIDUAL stationarity=(adf=(0 1 2));*/
/*run;*/

proc arima data=work.demanding plots=all;
	identify var=demand crosscorr=(_linear_ _square_) noprint;
	estimate input=(_linear_ _square_) p=1 ml;
	forecast lead=12 id=date interval=month out=work.Quad;
run;
quit;

***Ex 17.12****;
proc arima data=work.demanding;
	identify var=demand(1) noprint;
	estimate p=1 ml;
	outlier type=(ao ls tc(5)) maxnum=9 id=date;
quit;

data work.demanding;
	set work.demanding;
	AO_OCT2005=('01OCT2005'd <=date<='31OCT2005'd);
	AO_JUL2003=('01JUL2003'd <=date<='31JUL2003'd);
	AO_MAR2003=('01MAR2003'd <=date<='31MAR2003'd);
	AO_AUG2005=('01AUG2005'd <=date<='31AUG2005'd);
	AO_MAR2009=('01MAR2009'd <=date<='31MAR2009'd);
	AO_JUN2008=('01JUN2008'd <=date<='30JUN2008'd);
	LS_JUN2003=(date>='01JUN2003'd);
	TC5_JAN2004=('01JAN2004'd <=date<='31MAY2004'd);
	TC5_FEB2003=('01FEB2003'd <=date<='30JUN2003'd);
run;

proc arima data=work.demanding plots=all;
	identify var=demand
	         crosscorr=(_linear_ _square_ AO_OCT2005 AO_JUL2003 
			           AO_MAR2009 AO_JUN2008 TC5_JAN2004 TC5_FEB2003 /*TC5_NOV2005*/
                        AO_MAR2003 AO_AUG2005 LS_JUN2003) noprint;
	estimate p=(1 3) input=(_linear_ _square_ AO_OCT2005 AO_JUL2003 
			            AO_MAR2009 AO_JUN2008 TC5_JAN2004 TC5_FEB2003 /* TC5_NOV2005*/
                        AO_MAR2003 AO_AUG2005 LS_JUN2003) ml outest=see;
	forecast lead=12 id=date interval=month ;
run;
quit;

***Ex 17.13****;

proc forecast data=ex.demanding 
                out=work.demandARfor
				outall
				outest=work.paramerters
				method=stepar
				ar=6
				trend=3
				interval=month
				lead=12;
	var demand;
	id date;
run;

****Ex 17.14****;
proc autoreg data=work.demanding;
	model demand = _square_ AO_OCT2005 AO_JUL2003
				/nlag=6 backstep;
	output out=Autoreg_Demand UCL=U95 LCL=L95 Predicted=Forecast;
run;

data work.exampleautoreg;
	input x @@;
	t=_N_;
	datalines;
3.03 8.46 10.22 9.80 11.96 2.83
8.43 13.77 16.18 16.84 19.57 13.26
14.78 24.48 28.16 28.27 32.62 18.44
25.25 38.36 43.70 44.46 50.66 33.01
39.97 60.17 68.12 68.84 78.15 49.84
62.23 91.49 103.20 104.53 118.18 77.88
94.75 138.36 155.68 157.46 177.69 117.15
;
run;

proc sgplot data=work.exampleautoreg;
	scatter x=t y=x;
	series x=t y=x;
run;

proc arima data=work.exampleautoreg;
	identify var=x(1) /*stationarity=(adf=(0 1 2))*/;
run;

proc autoreg data=work.exampleautoreg;
	model x = t /nlag=12 backstep;
	output out=work.Autoreg_output UCL=U95 LCL=L95 Predicted=Forecast;
run;

proc sgplot data=work.Autoreg_output;
	band x=t lower=L95 upper=U95;
	scatter x=t y=x;
	series x=t y=forecast;
run;

****Ex 17.15****;

proc esm data=ex.demanding
		  outfor=work.outfor(rename=(LOWER=L95 UPPER=U95 PREDICT=Forecast))
		  print=(estimates statistics summary)
		  seasonality=12
		  lead=12;
	id date interval=month;
	forecast demand / model=linear;
run;

proc sgplot data=work.outfor;
	band x=date upper=U95 lower=L95;
	scatter x=date y=actual;
	series x=date y=forecast;
	refline '01Oct2009'd /axis=x;
run;

****Ex 17.16****;

data work.Air1990_2000;	
	set ex.airline1990_2013(where=(month<='31Dec2000'd));
	array seasons{*} mon1-mon11;
	retain mon1-mon11 . time 0;
	time+1;
	if mon1=. then do i=1 to 11;
		seasons[i]=0;
	end;
	if month(month)<12 then do;
		seasons[month(month)]=1;
		output;
		seasons[month(month)]=0;
	end;
	else output;
	drop i;
run;

data work.air1990_2000;
	set work.Air1990_2000;
	retain twopi . time 0;
	if twopi=. then twopi=2*constant("pi");
	time+1;
	s4=sin(twopi*time/4);
	c4=cos(twopi*time/4);
	s12=sin(twopi*time/12);
	c12=cos(twopi*time/12);
	format s4 c4 s12 c12 comma6.4;
	drop twopi ;
run;

proc arima data=work.Air1990_2000;
	identify var=passengers
	         crosscorr=( time mon1 mon2 mon3 mon4
   						mon5 mon6 mon7 mon8
						mon9 mon10 mon11 ) noprint;
	estimate input=(time mon1 mon2 mon3 mon4
   					mon5 mon6 mon7 mon8
					mon9 mon10 mon11 ) /*p=(1) (12)*/
			 ml;
quit;

proc arima data=work.Air1990_2000;
	identify var=passengers
	         crosscorr=( time mon1 mon2 mon3 mon4
   						mon5 mon6 mon7 mon8
						mon9 mon10 mon11 ) noprint;
	estimate input=(time mon1 mon2 mon3 mon4
   					mon5 mon6 mon7 mon8
					mon9 mon10 mon11 ) p=1
			 ml;
quit;

*********;

proc timesseries data=work.air1990_2000 plot=(series corr acf);
	id month interval=month;
	var passengers;
run;


proc arima data=work.Air1990_2000;
	identify var=passengers;
	identify var=passengers(12);
run;

****Ex 17.17******;
proc spectra data=work.air1990_2000 out=work.periodogram
			   p s;
	var passengers;
	weights parzen;
run;

proc sgplot data=work.periodogram(where=(2<period<=20));
	series x=period y=S_01/
			lineattrs=graphprediction(pattern=1 color=black)
			legendlabel="Parzen Kernel" name="series1";
	refline 2.4/axis=x
			lineattrs=graphprediction(pattern=2 color=lightblue thickness=1)
			legendlabel="Period 2.4"  name="series2";
	refline 4/axis=x
			lineattrs=graphprediction(pattern=2 color=blue thickness=3)
			legendlabel="Period 4"  name="series3";
	refline 12/axis=x
			lineattrs=graphprediction(pattern=2 color=darkblue thickness=5)
			legendlabel="Period 12"  name="series4";
	keylegend "series1" "series2" "series3" "series4"/
			location=outside position=bottom;
run;

****Ex 17.18****;
proc arima data=work.air1990_2000;
	identify var=passengers stationarity=(adf=(0 1 2));
	identify var=passengers stationarity=(adf=(0 1 2) dlag=12);
run;

****Ex 17.19*****;

proc arima data=work.air1990_2000;
	identify var=passengers(1 12) noprint;
	estimate q=(1)(12) ml;
run;

proc arima data=work.air1990_2000 plots=all;
	identify var=passengers(1 12) noprint;
	estimate p=1 q=(1)(12) ml;
	forecast lead=24 id=month interval=month;
run;
*******;
