
####################################################
# 临床预测模型方法与应用
# 第十六章
###################################################

####################################################
# 1. 模拟数据
####################################################
# install required pacakages and library them
library(lulab.utils)
test_mirror("China")
packages= c("LaplacesDemon", "dplyr", "magrittr")
for (i in packages){
  if (!suppressMessages(require(i, character.only = TRUE))) {
    install.packages(i)
  }
}

generate_values= function(n, mean, sd, condition) {
  X = c()
  j = 0
  for (i in 1:10000) {
    x = rnorm(1, mean, sd)
    if (condition(x)) {
      X = c(X, x)
      j = j + 1
    }
    if (j == n) {
      break
    }
  }
  return(X)
}

rnorm_truncated = function(n, mean, sd, ...) {
  # 将附加参数存储在 additional_arguments 列表中。
  # 根据附加参数的数量和名称，定义不同的条件函数 condition：
  # 如果只有一个参数且名称为 a，条件为 x >= a。
  # 如果只有一个参数且名称为 b，条件为 x <= b。
  # 如果有两个参数，条件为 a <= x <= b。
  # 如果参数不符合预期，抛出错误。
  additional_arguments = list(...)
  if (length(additional_arguments) == 1 && names(additional_arguments)[[1]] == "a") {
    condition = function(x) x >= additional_arguments[[1]]
  } else if (length(additional_arguments) == 1 && names(additional_arguments)[[1]] == "b") {
    condition = function(x) x <= additional_arguments[[1]]
  } else if (length(additional_arguments) == 2) {
    condition = function(x) x >= additional_arguments[[1]] && x <= additional_arguments[[2]]
  } else {
    stop("Wrong input")
  }
  return(generate_values(n, mean, sd, condition))
}

# 数据
set.seed(1234)
N= 5000
# design matrix
x1= round(rnorm_truncated(N, 62, 5, a=18, b=130), 0) # round to integer
x2= rbinom(N, 1, .42+.001*x1) #伯努利试验，概率为0.42+0.001*x1
x3= round(
  (1-x2)*rnorm_truncated(N, 20, 5, 13, 49)+
    x2*rnorm_truncated(N, 23, 5, 15, 50), 1
) # round to 1 decimal
x4= round(rnorm_truncated(N, 110, 18, 20, 300), 0)
x5= rbinom(N, 1, .13+.005*x2+.02*(x4>140))
x6= rbinom(N, 1, .23+.0005*x1)
x7= rbinom(N, 1, .29+.01*x2)
x8= rbinom(N, 1, .2)
x9= rcat(N, c(.68, .2, .12)) # 三分类变量，概率分别为0.68, 0.2, 0.12
x10= round(rnorm_truncated(N, 4.4+.1*x2, 1.1, 0, 100), 2) # round to 2 decimals
x11= round(exp(rnorm(N, log(2.8), .2)), 2)
x12= rpois(N, .3)
x13= rpois(N, .05+.01*x1)
x14= rbinom(N, 1, .08)
x15= rbinom(N, 1, .02)
x16= rcat(N, c(.19, .5, .25, .06))
# survival time
tEvent= round(
  rexp(N,
       rate= .0001+log(1.0003)*x1+log(1.00002)*x1^2+
         log(1.1)*x2+log(1.0002)*x3+log(1.3)*x5+
         log(1.2)*x7+log(1.0004)*log(x11)+log(1.02)*x2*x6+
         log(1.01)*x2*x15*x16+log(1.02)*I(x4>150)), 4
)
endTime= 7
c= runif(N, 1, endTime)
tDeath= rexp(N, rate = .002+log(1.02)*x1)
t= pmin(tEvent, endTime, c)
Censored= ifelse(t == tEvent, 1, 0)
y_binary= rbinom(N, 1,
                 .02-.0001*x1+.05*x2+.1*x5+.04*I(x9==1)+.02*I(x10>=4.5))
dataset= cbind(
  ID=1:N,
  x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16,
  tEvent, Censored, y_binary
) %>%
  data.frame() %>%
  mutate(type= "raw")
dataset %>%
  head()

# 外部数据
N= 3000
# design matrix
x1= round(rnorm_truncated(N, 61, 7, a=18, b=120), 0) # round to integer
x2= rbinom(N, 1, .43+.001*x1) #伯努利试验，概率为0.42+0.001*x1
x3= round(
  (1-x2)*rnorm_truncated(N, 19, 6, 13, 49)+
    x2*rnorm_truncated(N, 24, 5, 15, 50), 1
) # round to 1 decimal
x4= round(rnorm_truncated(N, 120, 20, 10, 400), 0)
x5= rbinom(N, 1, .14+.004*x2+.02*(x4>140))
x6= rbinom(N, 1, .23+.0005*x1)
x7= rbinom(N, 1, .28+.015*x2)
x8= rbinom(N, 1, .22)
x9= rcat(N, c(.54, .3, .16)) # 三分类变量，概率分别为0.68, 0.2, 0.12
x10= round(rnorm_truncated(N, 4.5+.1*x2, 1.1, 0, 100), 2) # round to 2 decimals
x11= round(exp(rnorm(N, log(3), .23)), 2)
x12= rpois(N, .32)
x13= rpois(N, .07+.008*x1)
x14= rbinom(N, 1, .08)
x15= rbinom(N, 1, .03)
x16= rcat(N, c(.2, .5, .24, .06))
# survival time
tEvent= round(
  rexp(N,
       rate= .0002+log(1.0004)*x1+log(1.2)*x2+
         log(1.0003)*x3+log(1.25)*x5+
         log(1.15)*x7+log(1.0006)*log(x11)+log(1.03)*x2*x6+
         log(1.04)*I(x4>140)), 4
)
endTime= 7
c= runif(N, 1, endTime)
tDeath= rexp(N, rate = .0015+log(1.03)*x1)
t= pmin(tEvent, endTime, c)
Censored= ifelse(t == tEvent, 1, 0)
y_binary= rbinom(N, 1,
                 .03-.0002*x1+.07*x2+.1*x5+.03*I(x9==1)+.01*I(x10>=4.7)+.1*x15)
dataset_external= cbind(
  ID=1:N,
  x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16,
  tEvent, Censored, y_binary
) %>%
  data.frame() %>%
  mutate(type= "external")
dataset_external %>%
  head()

dataset_final= rbind(dataset, dataset_external)
saveRDS(dataset_final, "R/materials/dataset_final.rds")

####################################################
# 2. 描述数据
####################################################
packages= c("tableone", "dplyr", "magrittr", "rms",
            "stringr", "R.utils", "biostat3", "spatstat")
for (i in packages){
  if (!suppressMessages(require(i, character.only = TRUE))) {
    install.packages(i)
  }
}
# 计算二项分布的精确置信区间
exactBinomialCI= function(x, n, conf_level= .95) {
  alpha= 1-conf_level
  upper= qbinom((1-alpha/2), size = n, prob = x/n)
  lower= qbinom(alpha/2, size = n, prob = x/n)
  return(c(lower, upper))
}
summary_binary_outcome= function(outcome, data, digit=2,
                                 groups= c("raw", "external"), ...)
{
  require(magrittr)
  require(dplyr)
  additional_arguments= list(...)
  if ("weight" %in% names(additional_arguments)) {
    data= data %>%
      mutate(weight= .data[[additional_arguments$weight]])
  }else {
    data$weight= 1
  }
  if("exposure" %in% names(additional_arguments)) {
    data= data %>%
      mutate(exposure= .data[[additional_arguments$exposure]])
    levels(data$exposure)= groups
    incid_trt= data %>%
      group_by(exposure) %>%
      summarise(
        n= round(sum(weight), digit),
        event= round(sum(.data[[outcome]]*weight), digit),
        rate= round(event/n*100, digit),
        lci= round(exactBinomialCI(event, n)[1]/n*100, digit),
        uci= round(exactBinomialCI(event, n)[2]/n*100, digit)
      )
  }else {
    data$exposure= "all"
    incid_trt= data %>%
      group_by(exposure) %>%
      summarise(
        n= round(sum(weight), digit),
        event= round(sum(.data[[outcome]]*weight), digit),
        rate= round(event/n*100, digit),
        lci= round(exactBinomialCI(event, n)[1]/n*100, digit),
        uci= round(exactBinomialCI(event, n)[2]/n*100, digit)
      )
  }
  incid_trt %<>%
    as.data.frame() %>%
    mutate(rate= paste0(rate, " (", lci, "-", uci, ")")) %>%
    select(-all_of(c("lci", "uci")))
  colnames(incid_trt)= c("Group", "N", "Event", "Incidence Rate (%)")
  return(incid_trt)
}

dataset_final= readRDS("R/materials/dataset_final.rds")
# 命名
names(dataset_final)= c(
  "ID", "Age", "male", "BMI", "SBP", "MI", "HF", "COPD",
  "cancer", "albuminuria", "TC", "LDLC", "No_outpatient",
  "No_inpatient", "liver_disease", "hypoglycemia", "CKD_stage",
  "AKI_time", "AKI_status", "AKI_binary", "type"
)
dataset_final %>%
  head()
# 分类变量的注释
dataset_final$CKD_stage %>% table()
dataset_final %<>%
  mutate(
    albuminuria= case_when(
      albuminuria == 1 ~ "normaltoMild",
      albuminuria == 2 ~ "moderate",
      albuminuria == 3 ~ "severe"
    ),
    albuminuria= factor(albuminuria, levels= c("normaltoMild", "moderate", "severe")),
    CKD_stage= case_when(
      CKD_stage == 1 ~ "G1_2",
      CKD_stage == 2 ~ "G3a",
      CKD_stage == 3 ~ "G3b",
      CKD_stage == 4 ~ "G4"
    ),
    CKD_stage= factor(CKD_stage, levels= c("G1_2", "G3a", "G3b", "G4"))
  )
dataset_binary= dataset_final %>%
  select(all_of(c(
    "ID", "Age", "male", "BMI", "SBP", "MI", "HF", "COPD",
    "cancer", "albuminuria", "TC", "LDLC", "No_outpatient",
    "No_inpatient", "liver_disease", "hypoglycemia", "CKD_stage",
    "AKI_binary", "type"
  )))
dataset_binary %>%
  head()
# table1
dataset_binary$type %<>% factor(., levels= c("raw", "external"))
dataset_binary$male %<>% factor(., levels= c(0, 1))
dataset_binary$MI %<>% factor(., levels= c(0, 1))
dataset_binary$HF %<>% factor(., levels= c(0, 1))
dataset_binary$COPD %<>% factor(., levels= c(0, 1))
dataset_binary$cancer %<>% factor(., levels= c(0, 1))
dataset_binary$liver_disease %<>% factor(., levels= c(0, 1))
dataset_binary$hypoglycemia %<>% factor(., levels= c(0, 1))
lulab.utils::Table1(
  df= dataset_binary,
  ycol = "type",
  xcol= setdiff(names(dataset_binary), c("type", "ID", "AKI_binary")),
  result_dir = "R/materials/",
)
# 终点事件发生率
tmp_data= dataset_binary %>%
  filter(type == "raw")
summary_binary_outcome("AKI_binary", tmp_data, digit= 2)
tmp_data= dataset_binary %>%
  filter(type == "external")
summary_binary_outcome("AKI_binary", tmp_data, digit= 2)
summary_binary_outcome("AKI_binary", dataset_binary, digit= 2, exposure= "type")
# 转换协变量
dataset_binary_trans= dataset_final %>%
  mutate(
    Age_square= Age^2, # 年龄的平方
    log_LDLC= log(LDLC), # LDLC的对数
    age_standard= (Age- mean(Age))/sd(Age),
    age_min_max= (Age- min(Age))/(max(Age)- min(Age)),
    age_category= case_when(
      Age < 50 ~ "<50",
      Age >= 50 & Age < 60 ~ "50-59",
      Age >= 60 & Age < 70 ~ "60-69",
      Age >= 70 & Age < 80 ~ "70-79",
      Age >= 80 ~ ">=80"
    ),
    age_category= factor(age_category, levels= c("<50", "50-59", "60-69", "70-79", ">=80")),
    BMI_category= case_when(
      BMI < 18.5 ~ "underweight",
      BMI >= 18.5 & BMI < 25 ~ "normal",
      BMI >= 25 & BMI < 30 ~ "overweight",
      BMI >= 30 ~ "obesity"
    ),
    BMI_category= factor(BMI_category, levels= c("underweight", "normal", "overweight", "obesity")),
    TC_category= cut(TC, breaks= quantile(TC, probs= seq(0, 1, .25)), include.lowest = TRUE),
    TC_category= relevel(TC_category, ref= levels(TC_category)[1]),
    TC_rcs_1= Hmisc::rcspline.eval(TC, nk= 4, norm=0, knots.only= FALSE, inclx= TRUE)[, 1],
    TC_rcs_2= Hmisc::rcspline.eval(TC, nk= 4, norm=0, knots.only= FALSE, inclx= TRUE)[, 2],
    TC_rcs_3= Hmisc::rcspline.eval(TC, nk= 4, norm=0, knots.only= FALSE, inclx= TRUE)[, 3],
    age_male= Age*(male==1), # 交互项
    male_cancer= male*cancer,
    male_CKD_stage_G3a= (male==1)*(CKD_stage=="G3a"),
    male_CKD_stage_G3b= (male==1)*(CKD_stage=="G3b"),
    male_CKD_stage_G4= (male==1)*(CKD_stage=="G4"),
    age_TC= Age*TC,
    age_BMI_TC= Age*BMI*TC
  )
dataset_binary_trans$TC_category %>% levels()
dataset_internal= dataset_binary_trans %>%
  filter(type == "raw")
dataset_external= dataset_binary_trans %>%
  filter(type == "external")
saveRDS(dataset_internal, "R/materials/dataset_internal.rds")
saveRDS(dataset_external, "R/materials/dataset_external.rds")
