###### Set up ######

rm(list = ls(all = TRUE))

# Load packages
packages <- c("ggplot2", "dplyr", "tidyr", "lme4", "simr", "future")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)

sample <- 'unbalanced' # 'unbalanced'
audit_coding <- 'continuous' # continuous
total_n <- 560
dropout_rate <- 0.25

plan(multisession, workers = 2) 
simnum = 100
glmerctrlist <- glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa")

###### create DF ######

n <- total_n*(1-dropout_rate)

trial <- factor(1:5)
condition <- factor(1:5)
subj <- factor(1:n)
version <- factor(1:2)
group <- (factor(1:2))


if (sample == 'balanced') {
  trial_full <- rep(trial, n*5)
  condition_full <- rep(rep(condition, each=5), n)
  subj_full <- rep(subj, each=25)
  version_full <- rep(rep(version, each=((n*5*5/2)/2), 2))
  group_full <- rep(group, each=n*5*5/2)
  
  audit_sum_low <- sample(c(0:7), n/2, replace = TRUE)
  audit_sum_high <- sample(c(8:20), n/2, replace = TRUE)
  audit_sum <- c(audit_sum_low, audit_sum_high)
  audit_full <- rep(audit_sum, each=25)
} else {
  trial_full <- rep(trial, n*5)
  condition_full <- rep(rep(condition, each=5), n)
  subj_full <- rep(subj, each=25)
  version_full <- c((rep(version[1], n*1/3*5*5)), (rep(version[2], n*2/3*5*5)))
  group_full <- c(rep(group[1], 70*5*5), rep(group[2], 70*5*5), rep(group[1], 140*5*5), rep(group[2], 140*5*5))
  
  audit_sum_low_small <- sample(c(0:7), n/3/2, replace = TRUE)
  audit_sum_high_small <- sample(c(8:20), n/3/2, replace = TRUE)
  audit_sum_low_large <- sample(c(0:7), (n*(2/3))/2, replace = TRUE)
  audit_sum_high_large <- sample(c(8:20), (n*(2/3))/2, replace = TRUE)
  audit_sum <- c(audit_sum_low_small, audit_sum_high_small, audit_sum_low_large, audit_sum_high_large)
  audit_full <- rep(audit_sum, each=25)
}

power_df_full <- data.frame(id=as.factor(subj_full), trial=as.factor(trial_full), condition=as.factor(condition_full), version=as.factor(version_full), group=as.factor(group_full), audit=audit_full)
power_df_lowrisk_control <- power_df_full[(power_df_full$version == 1 & power_df_full$group == 1), ]
power_df_alcohol <- power_df_full[power_df_full$version == 2, ]

###### Model 1 ######

contrasts(power_df_lowrisk_control$condition) <- contr.treatment(5, base = 5)

fixed <- c(-1.9,
           3.7, 2.4, 1.5, 2.6)
rand <- list(1.1)
res <- 3.3

model1 <- simr::makeGlmer(y ~ condition + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_lowrisk_control)
model1

sim_model1_condition2vs5 <- powerSim(model1, nsim=simnum, test = fixed("condition2", "z"), fitOpts=list(control=glmerctrlist))
sim_model1_condition2vs5
sim_model1_condition4vs5 <- powerSim(model1, nsim=simnum, test = fixed("condition4", "z"), fitOpts=list(control=glmerctrlist))
sim_model1_condition4vs5

###### Model 2 ######

contrasts(power_df_lowrisk_control$condition) <- contr.treatment(5, base = 3)

fixed <- c(-0.4,
           2.3, 0.9, 1.1, -1.5)
rand <- list(1.1)
res <- 3.3

model2 <- simr::makeGlmer(y ~ condition + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_lowrisk_control)
model2

sim_model2_condition2vs3 <- powerSim(model2, nsim=simnum, test = fixed("condition2", "z"), fitOpts=list(control=glmerctrlist))
sim_model2_condition2vs3
sim_model2_condition4vs3 <- powerSim(model2, nsim=simnum, test = fixed("condition4", "z"), fitOpts=list(control=glmerctrlist))
sim_model2_condition4vs3

###### Model 3 ######

# Model 3a based on alcohol context data only

contrasts(power_df_alcohol$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_alcohol$version) <- contr.treatment(2, base = 2)
contrasts(power_df_alcohol$group) <- contr.treatment(2, base = 1)

if (audit_coding == 'binary') {
 
  fixed <- c(-1.9,
             3.8, 2.4, 1.5, 2.7,
             -5,
             0, 20, 0, 20)
  rand <- list(1.4)
  res <- 3.3
  
  model3a <- simr::makeGlmer(y ~ condition*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_alcohol)
  model3a
  
  sim_model3a_group_condition2vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition2vs5
  #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs5
  
  sim_model3a_group_condition4vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition4:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition4vs5
  #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  #curve_group_condition4vs5
  
} else if (audit_coding == 'continuous') {
  
  fixed <- c(-1.7,
             4.6, 2.3, 1.2, 1.3,
             0,
             0, 0.5, 0, 0.5)
  rand <- list(1.6)
  res <- 3.3
  
  model3a <- simr::makeGlmer(y ~ condition*audit + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_alcohol)
  model3a
  
  sim_model3a_group_condition2vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition2:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition2vs5
  #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs5
  
  sim_model3a_group_condition4vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition4:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition4vs5
  #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  #curve_group_condition4vs5
}


# Original model 3 based on full data set
contrasts(power_df_full$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_full$version) <- contr.treatment(2, base = 2)
contrasts(power_df_full$group) <- contr.treatment(2, base = 1)

if (audit_coding == 'binary') {

  fixed <- c(-1.9,
             3.8, 2.4, 1.5, 2.7,
             0,
             0,
             0.7, -0.8, -0.8, -1.5,
             0, 20, 0, 20,
             1,
             0, 30, 0, 30)
  rand <- list(1.4)
  res <- 3.3
  
  model3 <- simr::makeGlmer(y ~ condition*version*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
  model3
  
  sim_model3_group_condition2vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5
  # #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  # #curve_group_condition2vs5
  
  sim_model3_group_condition4vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition4:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5
  # #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  # #curve_group_condition4vs5
  # 
  sim_model3_group_condition2vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition2:version1:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5_version
  #curve_group_condition2vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs5_version
  
  sim_model3_group_condition4vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition4:version1:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5_version
  #curve_group_condition4vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition4:version1:group2"), along = "id")
  #curve_group_condition4vs5_version

} else if (audit_coding == 'continuous') {
  
  fixed <- c(-2,
             4.3, 3.1, 1.7, 3.1,
             0.4,
             0,
             0.2, -0.8, -0.5, -1.8,
             -0.1, 0.5, 0, 0.5,
             0,
             0, 0.5, 0, 0.5)
  rand <- list(1.4)
  res <- 3.3
  
  model3 <- simr::makeGlmer(y ~ condition*version*audit + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
  model3
  
  sim_model3_group_condition2vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition2:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5
  # #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  # #curve_group_condition2vs5
  
  sim_model3_group_condition4vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition4:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5
  # #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  # #curve_group_condition4vs5
  # 
  sim_model3_group_condition2vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition2:version1:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5_version
  #curve_group_condition2vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs5_version
  
  sim_model3_group_condition4vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition4:version1:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5_version
  #curve_group_condition4vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition4:version1:group2"), along = "id")
  #curve_group_condition4vs5_version
  
}

###### Model 4 ######

contrasts(power_df_alcohol$condition) <- contr.treatment(5, base = 4)

if (audit_coding == 'binary') {

  fixed <- c(-0.3,
             3.2, 0.5, -0.5, -1.2,
             0,
             0, -20, 0, -15)
  rand <- list(1.7)
  res <- 3.3
  
  model4 <- simr::makeGlmer(y ~ condition*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_alcohol)
  model4
  
  sim_model4_group_condition2vs4_version <- powerSim(model4, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model4_group_condition2vs4_version
  #curve_group_condition2vs4 <- powerCurve(model4, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs4
  
}  else if (audit_coding == 'continuous') {
  
  fixed <- c(-0.4,
             3.3, 1, -0.1, -1.3,
             0,
             0, -0.2, 0, -0.05)
  rand <- list(1.7)
  res <- 3.3
  
  model4 <- simr::makeGlmer(y ~ condition*audit + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_alcohol)
  model4
  
  sim_model4_group_condition2vs4_version <- powerSim(model4, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model4_group_condition2vs4_version
  #curve_group_condition2vs4 <- powerCurve(model4, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs4
  
}

###### Model 5 ######

contrasts(power_df_full$condition) <- contr.treatment(5, base = 4)

if (audit_coding == 'binary') {

  fixed <- c(0.8,
             1.1, -0.3, -1.1, -2.7,
             0,
             -1,
             2, 0.7, 0.7, 1.5,
             0, -20, 0, -5,
             1,
             0, -30, 0, -5)
  rand <- list(1.4)
  res <- 3.3
  
  model5 <- simr::makeGlmer(y ~ condition*version*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
  model5
  
  sim_model5_group_condition2vs4_version <- powerSim(model5, nsim=simnum, test = fixed("condition2:version1:group2"), fitOpts=list(control=glmerctrlist))
  sim_model5_group_condition2vs4_version
  #curve_group_condition2vs4_version <- powerCurve(model5, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs4_version
  
} else if (audit_coding == 'continuous') {
  
  fixed <- c(1,
             1.2, -0.03, -1.4, -3.1,
             0,
             -1,
             2, 1, 1.3, 1.8,
             0, -0.2, 0, -0.05,
             0.2,
             0, -0.2, 0, -0.05)
  rand <- list(1.4)
  res <- 3.3
  
  model5 <- simr::makeGlmer(y ~ condition*version*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
  model5
  
  sim_model5_group_condition2vs4_version <- powerSim(model5, nsim=simnum, test = fixed("condition2:version1:group2"), fitOpts=list(control=glmerctrlist))
  sim_model5_group_condition2vs4_version
  #curve_group_condition2vs4_version <- powerCurve(model5, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs4_version
  
}