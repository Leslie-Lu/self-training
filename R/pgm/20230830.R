#------------------------------------------------------------#
# R in Action (3rd ed): Chapter 7                            #
# Basic statistics                                           #
# requires the Hmisc, pastecs, psych, dplyr, carData, vcd    #
#    gmodels, ggm, and MASS packages                         #
# install.packages(c("Hmisc", "pastecs", "psych", "dplyr",   #   
#                    "carData", "vcd", "gmodels", "ggm",     #   
#                    "MASS"))                                #
#------------------------------------------------------------#

library(magrittr)

# Listing 7.1 Descriptive statistics with summary()
myvars <- c("mpg", "hp", "wt")
summary(mtcars[myvars])

# Listing 7.2 Descriptive statistics via sapply()
mystats <- function(x, na.omit=FALSE){
  if (na.omit)
    x <- x[!is.na(x)]
  m <- mean(x)
  n <- length(x)
  s <- sd(x)
  skew <- sum((x-m)^3/s^3)/n
  kurt <- sum((x-m)^4/s^4)/n - 3
  return(c(n=n, mean=m, stdev=s, 
           skew=skew, kurtosis=kurt))
}

myvars <- c("mpg", "hp", "wt")
sapply(mtcars[myvars], mystats)

# Listing 7.3 Descriptive statistics via describe() in the Hmisc package
library(Hmisc)
myvars <- c("mpg", "hp", "wt")
describe(mtcars[myvars])

# Listing 7.4 Descriptive statistics via stat.desc() in the pastecs package 
library(pastecs)
myvars <- c("mpg", "hp", "wt")
stat.desc(mtcars[myvars])

# Listing 7.5 Descriptive statistics via describe() in the psych package
library(psych)
myvars <- c("mpg", "hp", "wt")
describe(mtcars[myvars])

# Listing 7.6 Descriptive statistics by group using by()
dstats <- function(x)sapply(x, mystats)
myvars <- c("mpg", "hp", "wt")
by(mtcars[myvars], mtcars$am, dstats)

# Listing 7.7 Descriptive statistics for groups defined by multiple variables
dstats <- function(x)sapply(x, mystats, na.omit=TRUE)
myvars <- c("mpg", "hp", "wt")
by(mtcars[myvars], 
   list(Transmission=mtcars$am,
        Engine=mtcars$vs), 
   FUN=dstats)

# Section 7.1.4
# Summarizing data interactively with dplyr

library(dplyr)
library(carData)
Salaries %>%
  summarize(med = median(salary), 
            min = min(salary), 
            max = max(salary))

Salaries %>%
  group_by(rank, sex) %>%
  summarize(n = length(salary),
            med = median(salary), 
            min = min(salary), 
            max = max(salary))

Salaries %>%
  group_by(rank, sex) %>%
  select(yrs.service, yrs.since.phd) %>%
  summarize_all(mean)

# Section 7.2 
# Frequency tables
library(vcd)
head(Arthritis)

# one way table
mytable <- table(Arthritis$Improved)
mytable                       # counts
prop.table(mytable)           # proportions
prop.table(mytable)*100       # percents

# two way table
mytable <- xtabs(~ Treatment+Improved, data=Arthritis)
mytable  # counts

margin.table(mytable, 1)    # total counts for Treatment 
prop.table(mytable, 1)      # row proportions (rows add to 1)

margin.table(mytable, 2)    # total counts for Improved
prop.table(mytable, 2)      # column proportions (columns add to 1)

prop.table(mytable)         # cell proportions (all cells add to 1)
addmargins(mytable)         # cell counts with row and column sums
addmargins(prop.table(mytable)) # cell proportions with row and column proportions

addmargins(prop.table(mytable, 1), 2) # row proportions with row sums
addmargins(prop.table(mytable, 2), 1) # column proportions with column sums

# Listing 7.8 Two-way table using CrossTable
library(gmodels)
CrossTable(Arthritis$Treatment, Arthritis$Improved)

# Listing 7.9 Three-way contingency table
mytable <- xtabs(~ Treatment+Sex+Improved, data=Arthritis) 
mytable          
margin.table(mytable, 1)  # totals for Treatment
margin.table(mytable, 2)  # totals for Sex
margin.table(mytable, 3)  # totals for Improved
margin.table(mytable, c(1, 3)) # totals for Treatment by Improved

# Treatment by Sex for each Level of Improved
ftable(mytable)
ftable(prop.table(mytable, c(1, 2))) # proportions sum to 1 over index omitted
ftable(addmargins(prop.table(mytable, c(1, 2)), 3)) 
ftable(addmargins(prop.table(mytable, c(1, 2)), 3)) * 100

# Listing 7.10 Chi-square test of independence
library(vcd)
mytable <- xtabs(~Treatment+Improved, data=Arthritis)          
chisq.test(mytable)

mytable <- xtabs(~Improved+Sex, data=Arthritis)              
chisq.test(mytable) 

# Fisher's exact test
mytable <- xtabs(~Treatment+Improved, data=Arthritis)
fisher.test(mytable)

# Chochran-Mantel-Haenszel test
mytable <- xtabs(~Treatment+Improved+Sex, data=Arthritis)
mantelhaen.test(mytable)

# Listing 7.11 Measures of association for a two-way table
library(vcd)
mytable <- xtabs(~Treatment+Improved, data=Arthritis)
assocstats(mytable)

# Listing 7.12 Covariances and correlations
states<- state.x77[,1:6]
cov(states)
cor(states)
cor(states, method="spearman")

x <- states[,c("Population", "Income", "Illiteracy", "HS Grad")]
y <- states[,c("Life Exp", "Murder")]
cor(x,y)

# partial correlations
library(ggm)
colnames(states)
pcor(c(1,5,2,3,6), cov(states))

# Listing 7.13 Testing a correlation coefficient for significance
cor.test(states[,3], states[,5])

# Listing 7.14 Correlation matrix and tests of significance via corr.test()
library(psych)
corr.test(states, use="complete")

# t-tests
# t.test(y ~ x, data) #y, numerical; x, dichotomous
# # equal to
# t.test(y1, y2) #y1, y2, numerical
library(MASS)
UScrime %>% str()
t.test(Prob ~ So, data=UScrime) #default setting: var.equal= false
# t.test(y1, y2, paired= TRUE)
sapply(UScrime[c("U1","U2")], function(x)(c(mean=mean(x),sd=sd(x))))
with(UScrime, t.test(U1, U2, paired=TRUE))

# Mann-Whitney U-test
with(UScrime, by(Prob, So, median))
wilcox.test(Prob ~ So, data=UScrime)
# Wilcox signed rank sum test
sapply(UScrime[c("U1","U2")], median)
with(UScrime, wilcox.test(U1, U2, paired=TRUE))

# one-way design
# Kruskal-Wallis test
# kruskal.test(y ~ A, data)
states <- data.frame(state.region, state.x77)
states %>% str()
kruskal.test(Illiteracy ~ state.region, data=states)
# nonparametric multiple pairwise comparisons while controlling the Type I error rate
# source("https://rkabacoff.com/RiA/wmc.R") 
source("C:/Library/Applications/Typora/data/self-training/R/pgm/macros/wmc.R")              
# wmc(y ~ A, data, method) #method, the approach used to limit Type I errors
wmc(Illiteracy ~ state.region, data=states, method="holm")

# repeated measures design or (paired multiple, ge 3, groups) or randomized block design
# Friedman test
# friedman.test(y ~ A | B, data) #y, numrical; A, grouping variable; B, blocking variable that identifies matched observations


#-------------------------------------------------------------------------#
# R in Action (3rd ed): Chapter 9                                         #
# Analysis of variance                                                    #
# requires the multcomp, car, effects, rrcov, and mvoutlier, dplyr, and   #
#    ggplot2 packages                                                     # 
# install.packages(c("multcomp", "car", "effects", "rrcov", "mvoutlier",  #
#    "dplyr", "ggplot2"))                                                 # 
#-------------------------------------------------------------------------#

# anova and lm are both specical cases of the general linear model
# the results of lm() and aov() are equivalent
# aov(formula, data)
# banlanced design vs. unbalanced design
# Because there is an equal number of observations in each treatment condition, you have a balanced design. 
# When the sample sizes are unequal across the cells of a design, you have an unbalanced design.

# the order of formula terms:
# note that the Anova() function in the car package (not to be confused with the standard anova() function) 
# provides the option of using the Type II or Type III approach, rather than the Type I approach used by the aov() function

# one-way between-groups anova, a factorial anova, formula: y ~ A
# Assessing test assumptions
# Assessing normality
library(car)
qqPlot(lm(response ~ trt, data=cholesterol), simulate=TRUE, main="Q-Q Plot")
# The data falls within the 95% confidence envelope, suggesting that the normality assumption has been met fairly well
# Assessing homogeneity of variances
bartlett.test(response ~ trt, data=cholesterol) #Bartlett’s test
# Other possible tests include the Fligner–Killeen test (provided by the fligner .test() function) and the Brown–Forsythe test (provided by the hov() function in the HH package)
# Assessing outliers, analysis of variance methodologies can be sensitive to the presence of outliers
outlierTest(fit) #From the output, you can see that there’s no indication of outliers in the cholesterol data (NA occurs when p > 1)

data(cholesterol, package="multcomp")
library(dplyr)
plotdata <- cholesterol %>%
  group_by(trt) %>%
  summarize(n = n(),
            mean = mean(response),
            sd = sd(response),
            ci = qt(0.975, df = n - 1) * sd / sqrt(n))
plotdata
fit <- aov(response ~ trt, data=cholesterol)                                  
summary(fit)
# A regression approach to the Anova problem
levels(cholesterol$trt)
fit.lm <- lm(response ~ trt, data=cholesterol)
summary(fit.lm)
# Because linear models require numeric predictors, when the lm() function
# encounters a factor, it replaces that factor with a set of numeric variables representing contrasts among the
# levels. If the factor has k levels, k – 1 contrast variables are created
# R provides five built-in methods for creating these contrast variables
# By default, treatment contrasts are used for unordered factors, and orthogonal polynomials are used for ordered factors.
# - contr.helmert:
#   Contrasts the second level with the first, the third level with the average of the first two, the fourth
#   level with the average of the first three, and so on
# - contr.poly:
#   Contrasts are used for trend analysis (linear, quadratic, cubic, and so on) based on orthogonal
#   polynomials. Used for ordered factors with equally spaced levels.
# - contr.sum:
#   Contrasts are constrained to sum to zero. Also called deviation contrasts, they compare the mean of
#   each level to the overall mean across levels.
# - contr.treatment:
#   Contrasts each level with the baseline level (first level by default). Also called dummy coding.
# - contr.SAS:
#   Similar to contr.treatment, but the baseline level is the last level. This produces coefficients
#   similar to contrasts used in most SAS procedures.
contrasts(cholesterol$trt) #With treatment contrasts, the first level of the factor becomes the reference group, and each subsequent level is compared with it
# fit.lm <- lm(response ~ trt, data=cholesterol, contrasts = 'contr.helmert') #change the default contrasts
# # equal
# options(contrasts = c('contr.SAS', 'contr.helmert')) #would set the default contrast for unordered factors to contr.SAS and for ordered factors to contr.helmert
# plot anova
library(ggplot2)
ggplot(plotdata, 
       aes(x = trt, y = mean, group = 1)) +
  geom_line(linetype="dashed", color="darkgrey") + 
  geom_errorbar(aes(ymin = mean - ci, 
                    ymax = mean + ci), 
                width = .2) +
  geom_point(size = 3, color="red") +
  theme_bw() + 
  labs(x="Treatment",
       y="Response",
       title="Mean Plot with 95% Confidence Interval") 
# Tukey HSD pairwise group comparisons, EER
pairwise <- TukeyHSD(fit)
pairwise
# plot
plotdata <- as.data.frame(pairwise[[1]])
plotdata$conditions <- row.names(plotdata)
ggplot(data=plotdata, aes(x=conditions, y=diff)) + 
  geom_errorbar(aes(ymin=lwr, ymax=upr, width=.2)) +
  geom_hline(yintercept=0, color="red", linetype="dashed") +
  geom_point(size=3, color="red") +
  theme_bw() +
  labs(y="Difference in mean levels", x="", 
       title="95% family-wise confidence level") +
  coord_flip()
# Multiple comparisons the multcomp package
library(multcomp)
tuk <- glht(fit, linfct=mcp(trt="Tukey")) 
summary(tuk)
# plot
labels1 <- cld(tuk, level=.05)$mcletters$Letters
labels2 <- paste(names(labels1), "\n", labels1)
ggplot(data=fit$model, aes(x=trt, y=response)) +
  scale_x_discrete(breaks=names(labels1), labels=labels2) +
  geom_boxplot(fill="lightgrey") +
  theme_bw() +
  labs(x="Treatment",
       title="Distribution of Response Scores by Treatment",
       subtitle="Groups without overlapping letters differ signifcantly (p < .05)")
# Groups (represented by box plots) that have the same letter don’t have significantly different means. You
# can see that 1time and 2times aren’t significantly different (they both have the letter a)
# competitor drugE was superior to both drugD and all three dosage strategies for the focus drug

# one-way within-groups anova, formula: y ~ A + Error(Subject / A)
# A is called a within-groups factor because each patient is measured under both levels
# Because each subject is measured more than once, the design is also called a repeated measures ANOVA


# one-way ancova (analysis of covariance), formula: y ~ x + A, x, contimuous vraible, a confounding factor/ a nuisance variable
# ANCOVA designs make the same normality and homogeneity of variance assumptions described for ANOVA
# designs, and you can test these assumptions using the same procedures
# In addition, standard ANCOVA designs assume homogeneity of regression slopes. In this case, it’s assumed
# that the regression slope for predicting birth weight from gestation time is the same in each of the four
# treatment groups. A test for the homogeneity of regression slopes can be obtained by including a gestation × dose interaction term 
# in your ANCOVA model. A significant interaction would imply that the relationship
# between gestation and birth weight depends on the level of the dose variable
# Testing for homegeneity of regression slopes
fit2 <- aov(weight ~ gesttime*dose, data=litter)
summary(fit2)
# The interaction is nonsignificant, supporting the assumption of equality of slopes. If the assumption is
# untenable, you could try transforming the covariate or dependent variable, using a model that accounts for
# separate slopes, or employing a nonparametric ANCOVA method that doesn’t require homogeneity of
# regression slopes. See the sm.ancova() function in the sm package for an example of the latter

litter %>%
  group_by(dose) %>%
  summarise(n=n(), mean=mean(gesttime), sd=sd(gesttime))
fit <- aov(weight ~ gesttime + dose, data=litter)                             
summary(fit)
# Obtaining adjusted means
# Because you’re using a covariate, you may want to obtain adjusted group means—that is, the group means
# obtained after partialing out the effects of the covariate
# install.packages('effects')
library(effects)
effect("dose", fit)
#  Multiple comparisons using user supplied contrasts
# Suppose you’re interested in whether the no-drug condition differs from the three-drug condition
contrast <- rbind("no drug vs. drug" = c(3, -1, -1, -1)) #The contrast c(3, -1, -1, -1) specifies a comparison of the first group with the average of the other three
summary(glht(fit, linfct=mcp(dose=contrast))) # The hypothesis is tested with a t-statistic
# Therefore, you can conclude that the no-drug group has a higher birth weight than the drug conditions
# Visualizing a one-way ANCOVA
pred <- predict(fit)
ggplot(data = cbind(litter, pred),
       aes(gesttime, weight)) + geom_point() +
  facet_grid(. ~ dose) + geom_line(aes(y=pred)) +
  labs(title="ANCOVA for weight by gesttime and dose") +
  theme_bw() +
  theme(axis.text.x = element_text(angle=45, hjust=1),
        legend.position="none")
# Here you can see that the regression lines for predicting birth weight from gestation time are parallel in
# each group but have different intercepts
# The lines are parallel because they’ve been specified to be. If you used the code:
ggplot(data = litter, aes(gesttime, weight)) +
  geom_point() + geom_smooth(method="lm", se=FALSE) +
  facet_wrap(~ dose, nrow=1)
# instead, you’d generate a plot that allows both the slopes and intercepts to vary by group. This approach is
# useful for visualizing the case where the homogeneity of regression slopes doesn’t hold.

# two-way ancova, formula: y ~ x1 + x2 + A*B, x1 and x2, continuous variables


# Two-way factorial ANOVA, formula: y ~ A*B, equal, y ~ A + B + A:B
data(ToothGrowth)
ToothGrowth$dose <- factor(ToothGrowth$dose)
stats <- ToothGrowth %>%
  group_by(supp, dose) %>%
  summarise(n=n(), mean=mean(len), sd=sd(len),
            ci = qt(0.975, df = n - 1) * sd / sqrt(n))
stats
fit <- aov(len ~ supp*dose, data=ToothGrowth)
summary(fit)
# Although I don’t cover the tests of model assumptions and mean comparison procedures, they’re a natural
# extension of the methods you’ve seen so far. Additionally, the design is balanced, so you don’t have to
# worry about the order of effects
# plotting interactions
pd <- position_dodge(0.2)
ggplot(stats, 
       aes(x = dose, y = mean, 
           group=supp, 
           color=supp, 
           linetype=supp)) +
  geom_point(size = 2, 
             position=pd) +
  geom_line(position=pd) +
  geom_errorbar(aes(ymin = mean - ci, ymax = mean + ci), 
                width = .1, 
                position=pd) +
  theme_bw() + 
  scale_color_manual(values=c("blue", "red")) +
  labs(x="Dose",
       y="Mean Length",
       title="Mean Plot with 95% Confidence Interval") 

#  Repeated measures ANOVA with one between-groups and one within-groups factor, two-way factorial anova with one between-groups and one within-groups factor
# When a factorial design includes both between-groups and within-groups factors, it’s also called a mixed model ANOVA. 
# The current design is a two-way mixed-model factorial ANOVA 
# formula: y ~ B*W + Error(Subject / W), B, between-groups, W, within-groups
data(CO2)
CO2$conc <- factor(CO2$conc)
w1b1 <- subset(CO2, Treatment=='chilled')
w1b1 %>% head() #wide format
CO2 %>% head() #long format
# Datasets are typically in wide format, where columns are variables and rows are observations, and there’s a single row for each subject.
# When dealing with repeated measures designs, you typically need the data in long format before fitting models. In long
# format, each measurement of the dependent variable is placed in its own row. 
# Luckily, the tidyr package can easily reorganize your data into the required format.

fit <- aov(uptake ~ (Type*conc) + Error(Plant/(conc)), w1b1)
summary(fit)
# The ANOVA table indicates that the Type and concentration main effects and the Type × concentration
# interaction are all significant at the 0.01 level
plotdata <- CO2 %>%
  group_by(conc, Type) %>%
  summarise(mean_conc = mean(uptake))
ggplot(data=plotdata, aes(x=conc, y=mean_conc, group=Type, color=Type,
                          linetype=Type)) +
  geom_point(size=2) +
  geom_line(linewidth=1) +
  theme_bw() + theme(legend.position="top") +
  labs(x="Concentration", y="Mean Uptake", 
       title="Interaction Plot for Plant Type and Concentration") #In this case, I've left out confidence intervals to keep the graph from becoming too busy
ggplot(data=CO2, aes(x=conc, y=uptake, fill=Type)) +
  geom_boxplot() +
  theme_bw() + theme(legend.position="top") +
  scale_fill_manual(values=c("aliceblue", "deepskyblue"))+
  labs(x="Concentration", y="Uptake", 
       title="Chilled Quebec and Mississippi Plants")
# The many approaches to mixed-model designs
# The CO2 example in this section was analyzed using a traditional repeated measures ANOVA. 
# The approach assumes that the covariance matrix for any within-groups factor follows a specified form known as sphericity. 
# Specifically, it assumes that the variances of the differences between any two levels of the within-groups factor are equal. 
# In real-world data, it’s unlikely that this assumption will be met. This has led to a number of alternative approaches,
# including the following:
# - Using the lmer() function in the lme4 package to fit linear mixed models (Bates, 2005)
# - Using the Anova() function in the car package to adjust traditional test statistics to account for lack of sphericity (for example, the Geisser–Greenhouse correction)
# - Using the gls() function in the nlme package to fit generalized least squares models with specified variance-covariance structures (UCLA, 2009)
# - Using multivariate analysis of variance to model repeated measured data (Hand, 1987)


# randomizied blok, formula: y ~ B + A, B, block variable


# One-way MANOVA (multivariate analysis of variance), multiple dependent variables
# The two assumptions underlying a one-way MANOVA are multivariate normality and homogeneity of
# variance-covariance matrices. The first assumption states that the vector of dependent variables jointly
# follows a multivariate normal distribution. You can use a Q-Q plot to assess this assumption.
#  Assessing multivariate normality
center <- colMeans(y)
n <- nrow(y)
p <- ncol(y)
cov <- cov(y)
d <- mahalanobis(y,center,cov)
coord <- qqplot(qchisq(ppoints(n),df=p),
                d, main="QQ Plot Assessing Multivariate Normality",
                ylab="Mahalanobis D2")
abline(a=0,b=1)
identify(coord$x, coord$y, labels=row.names(UScereal))
# If the data follows a multivariate normal distribution, then points will fall on the line. The identify()
# function allows you to interactively identify points in the graph. Click on each point of interest and then
# press ESC or the Finish button. Here, the dataset appears to violate multivariate normality, primarily due to
# the observations for Wheaties Honey Gold and Wheaties. You may want to delete these two cases and
# rerun the analyses.
# multivariate outliers
# install.packages('mvoutlier')
library(mvoutlier)
outliers <- aq.plot(y)
outliers
# The homogeneity of variance-covariance matrices assumption requires that the covariance matrix for each
# group is equal. The assumption is usually evaluated with a Box’s M test. R doesn’t include a function for
# Box’s M, but an internet search will provide the appropriate code
# Unfortunately, the test is sensitive to
# violations of normality, leading to rejection in most typical cases. This means that we don’t yet have a good
# working method for evaluating this important assumption

data(UScereal, package="MASS")
UScereal %>% head()
shelf <- factor(UScereal$shelf) 
y <- cbind(UScereal$calories, UScereal$fat, UScereal$sugars)
y %>% head()
colnames(y) <- c("calories", "fat", "sugars")
aggregate(y, by=list(shelf=shelf), FUN=mean) #The aggregate() function provides the shelf means
round(cov(y), 2)
# The manova() function provides the multivariate test of group differences. The significant F-value indicates
# that the three groups differ on the set of nutritional measures
fit <- manova(y ~ shelf)
summary(fit)
# Because the multivariate test is significant, you can use the summary.aov() function to obtain the
# univariate one-way ANOVAs
summary.aov(fit) #one-way anova
# Here, you see that the three groups differ on each nutritional measure
# considered separately. Finally, you can use a mean comparison procedure (such as TukeyHSD) to
# determine which shelves differ from each other for each of the three dependent variables.


# Robust one-way MANOVA
# If the assumptions of multivariate normality or homogeneity of variance-covariance matrices are untenable,
# or if you’re concerned about multivariate outliers, you may want to consider using a robust or
# nonparametric version of the MANOVA test instead
# install.packages('rrcov')
library(rrcov)
Wilks.test(y,shelf, method="mcd")  # this can take a while
# From the results, you can see that using a robust test that’s insensitive to both outliers and violations of
# MANOVA assumptions still indicates that the cereals on the top, middle, and bottom store shelves differ in
# their nutritional profiles.

# multivariate analysis of covariance, MANCOVA




