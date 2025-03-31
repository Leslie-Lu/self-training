# sample size calculation for clinical prediction modelling

lulab.utils::test_mirror("China")
options(repos = c(CRAN = 'https://mirrors.sustech.edu.cn/CRAN/'))
# install.packages('pmsampsize')
library(pmsampsize)

# for binary outcome
# exmple 1:
pmsampsize(type = 'b', csrsquared = .288, parameters = 24, prevalence = .174)
116/24 #EPP (events per candidate predictor) = 4.83

pmsampsize(type = 'b', csrsquared = 0.0827,
           parameters = 46, prevalence = .0073)
pmsampsize(type = 'b', csrsquared = 0.0800,
           parameters = 46, prevalence = .0070)

# validation for MAPE(mean absolute prediction error):
# https://mvansmeden.shinyapps.io/BeyondEPV/
# https://github.com/MvanSmeden/Beyond-EPV

# example 2:
# for time-to-event outcome
pmsampsize(type = 's', csrsquared = .051, parameters = 30, rate = .065, timepoint = 2, meanfup = 2.07)

# example 3:
# for continuous outcome
pmsampsize(type = 'c', rsquared = .2, parameters = 25, intercept = 1.9, sd = 1.6)


1118/84

# observed:expected ratio
phi= .5
SE= .051
N= (1-phi)/(phi*SE**2)
N


# https://github.com/gscollins1973/Validation_Survival_Sample_Size/blob/main/pesudo_example.R

# continuous outcome: R square
.1/2/1.96

800/0.6*100
pmsampsize(type = 'b', csrsquared = .1089, parameters = 2, prevalence = .35)


pmsampsize(type = 'b', csrsquared = 0.0827, parameters = 18, prevalence = .0073)
pmsampsize(type = 'b', csrsquared = 0.0800,
           parameters = 18, prevalence = .0070)
