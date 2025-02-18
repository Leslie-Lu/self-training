
/********************************************************************
 Survival Analysis Models
 *******************************************************************/
/* 
the exponential model and the Weibull model are proportional hazards models.
for the cox model, the baseline hazard function is unspecified.
most simulation studies of the Cox regression model assume that the survival times follows an exponential or Weibull distribution.
an exponential distribution of survival times implies that the baseline hazard function is constant over time.
*/

/* to simulate data from an exponential distribution with scale parameter sigma */
/* 
the exponential distribution models the ime betwwen events that occur at a constant avarage rate.
the exponential distribution is a continuous analog of the geometric distribution.
the exponential distributionwith scale parameter sigma has density function f(t) = (1/sigma) * exp(-t/sigma) for t > 0.
atlternatively, we can use lambda = 1/sigma as the rate parameter.
the rate parameter describes the rate at which events occur.
the following example simulates 100 observations from an exponential distribution with sigma = 10.
*/
proc template;
    define statgraph ContPDF;
    dynamic _X _T _Y _Title _HAlign
            _binstart _binstop _binwidth;
    begingraph;
        entrytitle halign=center _Title;
        layout overlay /xaxisopts=(linearopts=(viewmax=_binstop));
            histogram _X / name='hist' SCALE=DENSITY binaxis=true 
                endlabels=true xvalues=leftpoints binstart=_binstart binwidth=_binwidth;
            seriesplot x=_T y=_Y / name='PDF' legendlabel="PDF" lineattrs=(thickness=2);
            discretelegend 'PDF' / opaque=true border=true halign=_HAlign valign=top 
                    across=1 location=inside;
        endlayout;
    endgraph;
end;
run;
%macro ContPlot(DistName, binstart, binstop, binwidth);
data Cont;
   merge &DistName work.PDF;
run;
proc sgrender data=Cont template=ContPDF;
   dynamic _X="X" _T="T" _Y="Y" _HAlign="right"
	   _binstart=&binstart _binstop=&binstop _binwidth=&binwidth
	   _Title="Sample from &DistName Distribution (N=&N)";
run;
%mend;
%let N = 100;
data work.Exponential(keep=x);
    call streaminit(4321);
    sigma = 10;
    do i = 1 to &N;
        x = sigma * rand("Exponential");    /* X ~ Expo(10) */
        output;
    end;
run;
data work.PDF;
    do t = 1 to 45;
        Y = pdf("Exponential", t, 10);
        output;
    end;
run;
%ContPlot(work.Exponential, 0.0, 45, 5);
/* if X is distributed according to an expotential distribution with unit scale parameter, 
then Y= sigma*X is distributed according to an exponential distribution with scale parameter sigma.
the expected value of Y is sigma and the variance of Y is sigma^2. */
%macro RandExp(sigma);
    ((&sigma) * rand("Exponential"))
%mend;
/* 
some distributions include the exponential distribution for particular values of the distribution parameters.
for exmaple, a Weibull(1, b) distribution is an exponential distribution with scale parameter b.
*/
data work.Weibull(keep=x);
    call streaminit(4321);
    b = 10;
    do i = 1 to &N;
        x = rand("weibull", 1, b);    /* X ~ Weibull(1, 10) */
        output;
    end;
run;
data work.PDF;
    do t = 1 to 45;
        Y = pdf("Weibull", t, 1, 10);
        output;
    end;
run;
%ContPlot(work.Weibull, 0.0, 45, 5);
proc compare base=work.Exponential compare=work.Weibull;
run;


/* simulating survival data */
/* 
in the simplest situation, the event of intetst occurs at a common constant rate, which is called the hazard rate.
a constant rate is equivalent to an exponential distribution of the survival time.
we can analyze the survival time by using the lifetest procedure, as follows.
*/
data LifeData;
    call streaminit(1);
    do PatientID= 1 to 100;
        t= %RandExp(1/0.01); /* hazard rate = 0.01, the hazard rate for each subject is 0.01 events per day */
        output;
    end;
run;
proc lifetest data= LifeData;
    time t;
    ods select Quartiles Means;
run;



/* censored observations */
data CensoredData(keep= PatientID t Censored);
    call streaminit(1);
    HazardRate= .01;
    CensorRate= .001;
    EndTime= 365; /* the study lasts for 365 days */
    do PatientID= 1 to 100;
        tEvent= %RandExp(1/HazardRate); 
        c= %RandExp(1/CensorRate);
        t= min(tEvent, c, EndTime); 
        Censored= (c < tEvent | tEvent > EndTime); /* censored if c < tEvent or tEvent > EndTime */
        output;
    end;
run;
proc lifetest data=CensoredData plots=(survival(atrisk CL)); /*plot=(图表名(选项))*/
    time t*Censored(1);
    ods select Quartiles Means CensoredSummary SurvivalPlot;
run;



/* for survival models, the more useful exponential parameter is the rate parameter, which is 1/sigma */
/* the survival time and the censoring time are exponentially distributed */
%let N = 100;
data PHData(keep=x1 x2 t censored);
    array xx1{&N} _temporary_;
    array xx2{&N} _temporary_ ;
    call streaminit(1);
    /* read or simulate fixed effects */
    do i = 1 to &N;
        xx1{i} = rand("Normal"); xx2{i} = rand("Normal");
    end;
    /* simulate regression model */
    baseHazardRate = 0.002; /* rate at which subject experiences event */
    censorRate = 0.001; /* rate at which subject drops out of the study is 0.001 per day */
    do i = 1 to &N;
        x1 = xx1{i}; x2 = xx2{i};
        eta = -2*x1 + 1*x2; /* form the linear predictor */
        /* construct time of event and time of censoring */
        tEvent = %RandExp( 1/(baseHazardRate * exp(eta)) ); /* the liner predictor is used to simulate an event time */ 
        c = %RandExp( 1/censorRate ); /* rate parameter = censorRate */
        t = min(tEvent, c); /* time of event or censor time */
        censored = (c < tEvent); /* indicator variable: censored? */
        output;
    end;
run;
/* 
in sas, the PHREG procedure is used to fit proportional hazards models.
we can use the PHREG procedure to estimate the parameters of the Cox model and 
to estimate the survival function at specific values of the covariates, as follows:
*/
ods graphics on;
proc phreg data=PHData plots(overlay CL)= (survival);
    model t*censored(1)= x1-x2;
    ods select CensoredSummary ParameterEstimates
               ReferenceSet SurvivalPlot;
run;


/***********************************************************************/
/* 
when analyzing two or more samples of survival data, an important task is determining 
whether the undelying populations have identical survival functions.
the survivor function (or survival distribution function (SDF)) is the probability that a subject survives beyond a certain time.
the following data step simulates survival data from two populations that have different survival functions.
for simplicity, the model assumes that a subject is censored with probability 0.2.
*/
%let N=100;
data survsamp(keep=Treatment t Censored);
    call streaminit(1);
    array rate{2} (0.05 0.08);
    do Treatment=1 to dim(rate);
        do i=1 to &N;
            Censored= rand("Bernoulli", 0.2);
            t= %RandExp(1/rate{Treatment});
            output;
        end;
    end;
run;
/* 
the lifetest procedure can test whether two samples are likely to have come from the same survivor function.
*/
ods graphics on;
proc lifetest data=survsamp plots=(survival);
    strata Treatment;
    time t*Censored(1);
    ods select Quartiles HomTests SurvivalPlot;
run;
/* 
the median survival time for the first treatment group is 15.6.
the units--days, months, years--depend on the units for the rate function.
each of the tests for equality indicate that it is unlikely that these two samples come from the sanme survivor function.
*/