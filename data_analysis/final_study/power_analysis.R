###### Set up ######

rm(list = ls(all = TRUE))

# Load packages
packages <- c("ggplot2", "dplyr", "tidyr", "lme4", "simr", "future", "gmodels")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)
code_path <- "C:/Users/musialm/OneDrive - Charité - Universitätsmedizin Berlin/PhD/04_B01/WP3/Reduced_SR_in_AUD/data_analysis/final_study/"

sample <- 'balanced' # 'unbalanced'
audit_coding <- 'binary' # continuous
total_n <- 560
dropout_rate <- 0.25

plan(multisession, workers = 4) 
simnum = 100
glmerctrlist <- glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa")

###### create full DF ######

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

power_df_full <- data.frame(id=as.factor(subj_full), 
                            trial=as.factor(trial_full), 
                            condition=factor(condition_full, 
                                             labels = c("control",
                                                        "goal-state",
                                                        "policy",
                                                        "reward",
                                                        "transition")), 
                            version=factor(version_full, labels = c("alcohol",
                                                                    "control")), 
                            group=factor(group_full, labels = c("low-risk",
                                                                "harmful")), 
                            audit=audit_full)

###### Simulate data based on model 3 ######

# define contrasts

contrasts(power_df_full$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_full$version) <- contr.treatment(2, base = 2)
contrasts(power_df_full$group) <- contr.treatment(2, base = 1)
  
# define effects

fixed <- c(-1.2,
           3.5, 1.3, 0.6, 1.1,
           0,
           -0.1,
           0, 0.15, 0, 0,
           0.05, 0.05, 0, 0.08,
           0,
           0, -0.05, 0, 0.05)
rand <- list(1.4)
res <- 3.3

# generate model

model3 <- simr::makeGlmer(y ~ condition*version*audit + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
model3

# simulate data based on model and check if it fits expectations

y <- simulate(model3, nsim = 1, seed = NULL,
                     use.u = FALSE,
                     newdata=NULL, newparams=NULL, family=binomial,
                     allow.new.levels = FALSE, na.action = na.pass)

power_df_full$correct_path <- y$sim_1

aggr_power_df_full <- power_df_full %>%
  group_by(condition, group, version) %>%
  summarise(mean_correct = mean(correct_path, na.rm = TRUE),
            se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
            ci_l = ci(correct_path, na.rm=TRUE)[2],
            ci_u = ci(correct_path, na.rm=TRUE)[3],
            n = n()
  )

plot <- ggplot(aggr_power_df_full, aes(x=condition, y=mean_correct)) +
  geom_bar(stat="identity", fill="lightblue") +
  geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                position=position_dodge(.9)) +
  facet_wrap(~ version + group) +
  scale_y_continuous("% correct paths", limits = c(0, 1)) +
  theme_light(base_size = 16) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
plot

###### Create sub DFs ######

power_df_lowrisk_control <- power_df_full[(power_df_full$version == "control" & power_df_full$group == "low-risk"), ]
power_df_alcohol <- power_df_full[power_df_full$version == "alcohol", ]

###### Model 1 ######

# define contrasts

contrasts(power_df_lowrisk_control$condition) <- contr.treatment(5, base = 5)

# fit model

model1 <- glmer(correct_path ~ condition + (1 | id), family = binomial, data=power_df_lowrisk_control, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
model1

# plot data

aggr_power_df_lowrisk_control <- power_df_lowrisk_control %>%
  group_by(condition) %>%
  summarise(mean_correct = mean(correct_path, na.rm = TRUE),
            se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
            ci_l = ci(correct_path, na.rm=TRUE)[2],
            ci_u = ci(correct_path, na.rm=TRUE)[3],
            n = n()
  )

plot_model1 <- ggplot(aggr_power_df_lowrisk_control, aes(x=condition, y=mean_correct)) +
                    geom_bar(stat="identity", fill="lightblue") +
                    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                                  position=position_dodge(.9)) +
                    scale_y_continuous("% correct paths", limits = c(0, 1)) +
                    theme_light(base_size = 16) +
                    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
plot_model1

# power analysis per effect

sim_model1_condition2vs5 <- powerSim(model1, nsim=simnum, test = fixed("condition2", "z"), fitOpts=list(control=glmerctrlist))
sim_model1_condition2vs5

sim_model1_condition4vs5 <- powerSim(model1, nsim=simnum, test = fixed("condition4", "z"), fitOpts=list(control=glmerctrlist))
sim_model1_condition4vs5

###### Model 2 ######

# define contrasts

contrasts(power_df_lowrisk_control$condition) <- contr.treatment(5, base = 3)

# fit model

model2 <- glmer(correct_path ~ condition + (1 | id), family = binomial, data=power_df_lowrisk_control, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
model2

# plot data

aggr_power_df_lowrisk_control <- power_df_lowrisk_control %>%
  group_by(condition) %>%
  summarise(mean_correct = mean(correct_path, na.rm = TRUE),
            se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
            ci_l = ci(correct_path, na.rm=TRUE)[2],
            ci_u = ci(correct_path, na.rm=TRUE)[3],
            n = n()
  )

plot_model2 <- ggplot(aggr_power_df_lowrisk_control, aes(x=condition, y=mean_correct)) +
  geom_bar(stat="identity", fill="lightblue") +
  geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                position=position_dodge(.9)) +
  scale_y_continuous("% correct paths", limits = c(0, 1)) +
  theme_light(base_size = 16) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
plot_model2

# power analysis per effect

sim_model2_condition2vs3 <- powerSim(model2, nsim=simnum, test = fixed("condition2", "z"), fitOpts=list(control=glmerctrlist))
sim_model2_condition2vs3

sim_model2_condition4vs3 <- powerSim(model2, nsim=simnum, test = fixed("condition4", "z"), fitOpts=list(control=glmerctrlist))
sim_model2_condition4vs3

###### Model 3 ######

### Model 3a based on alcohol context data only ###

# define contrasts

contrasts(power_df_alcohol$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_alcohol$version) <- contr.treatment(2, base = 2)
contrasts(power_df_alcohol$group) <- contr.treatment(2, base = 1)

if (audit_coding == 'binary') {

  # fit model
  
  model3a <- glmer(correct_path ~ condition*group + (1 | id), family = binomial, data=power_df_alcohol, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model3a
  
  # plot data
  
  aggr_power_df_alcohol <- power_df_alcohol %>%
    group_by(condition, group) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model3a <- ggplot(aggr_power_df_alcohol, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model3a
  
  # power analysis per effect
  
  sim_model3a_group_condition2vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition2vs5
  #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs5
  
  sim_model3a_group_condition4vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition4:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition4vs5
  #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  #curve_group_condition4vs5
  
} else if (audit_coding == 'continuous') {
  
  # fit model
  
  model3a <- glmer(correct_path ~ condition*audit + (1 | id), family = binomial, data=power_df_alcohol, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model3a
  
  # plot data
  
  aggr_power_df_alcohol <- power_df_alcohol %>%
    group_by(condition, group) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model3a <- ggplot(aggr_power_df_alcohol, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model3a
  
  # power analysis per effect
  
  sim_model3a_group_condition2vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition2:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition2vs5
  #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs5
  
  sim_model3a_group_condition4vs5 <- powerSim(model3a, nsim=simnum, test = fixed("condition4:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3a_group_condition4vs5
  #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  #curve_group_condition4vs5
}


### Original model 3 based on full data set ###

# define contrasts

contrasts(power_df_full$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_full$version) <- contr.treatment(2, base = 2)
contrasts(power_df_full$group) <- contr.treatment(2, base = 1)

if (audit_coding == 'binary') {

  # fit model
  
  model3 <- glmer(correct_path ~ condition*group*version + (1 | id), family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model3
  
  # plot data
  
  aggr_power_df_full <- power_df_full %>%
    group_by(condition, group, version) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model3 <- ggplot(aggr_power_df_full, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ version + group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model3
  
  # power analysis per effect
  
  sim_model3_group_condition2vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5
  # #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  # #curve_group_condition2vs5
  
  sim_model3_group_condition4vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition4:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5
  # #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  # #curve_group_condition4vs5
  # 
  sim_model3_group_condition2vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition2:group2:version1"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5_version
  #curve_group_condition2vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs5_version
  
  sim_model3_group_condition4vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition4:group2:version1"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5_version
  #curve_group_condition4vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition4:version1:group2"), along = "id")
  #curve_group_condition4vs5_version

} else if (audit_coding == 'continuous') {
  
  # fit model
  
  model3 <- glmer(correct_path ~ condition*audit*version + (1 | id), family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model3
  
  # plot data
  
  aggr_power_df_full <- power_df_full %>%
    group_by(condition, group, version) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model3 <- ggplot(aggr_power_df_full, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ version + group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model3
  
  # power analysis per effect
  
  sim_model3_group_condition2vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition2:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5
  # #curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  # #curve_group_condition2vs5
  
  sim_model3_group_condition4vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition4:audit"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5
  # #curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
  # #curve_group_condition4vs5
  # 
  sim_model3_group_condition2vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition2:audit:version1"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition2vs5_version
  #curve_group_condition2vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs5_version
  
  sim_model3_group_condition4vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition4:audit:version1"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5_version
  #curve_group_condition4vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition4:version1:group2"), along = "id")
  #curve_group_condition4vs5_version
  
}

###### Model 4 ######

# define contrasts 

contrasts(power_df_alcohol$condition) <- contr.treatment(5, base = 4)

if (audit_coding == 'binary') {
  
  # fit model
  
  model4 <- glmer(correct_path ~ condition*group + (1 | id), family = binomial, data=power_df_alcohol, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model4
  
  # plot data
  
  aggr_power_df_alcohol <- power_df_alcohol %>%
    group_by(condition, group) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model4 <- ggplot(aggr_power_df_alcohol, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model4
  
  # power analysis per effect
  
  sim_model4_group_condition2vs4 <- powerSim(model4, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model4_group_condition2vs4
  #curve_group_condition2vs4 <- powerCurve(model4, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs4
  
}  else if (audit_coding == 'continuous') {
  
  # fit model
  
  model4 <- glmer(correct_path ~ condition*audit + (1 | id), family = binomial, data=power_df_alcohol, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model4
  
  # plot data
  
  aggr_power_df_alcohol <- power_df_alcohol %>%
    group_by(condition, group) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model4 <- ggplot(aggr_power_df_alcohol, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model4
  
  # power analysis per effect
  
  sim_model4_group_condition2vs4 <- powerSim(model4, nsim=simnum, test = fixed("condition2:group2"), fitOpts=list(control=glmerctrlist))
  sim_model4_group_condition2vs4
  #curve_group_condition2vs4 <- powerCurve(model4, nsim=simnum, test = fixed("condition2:group2"), along = "id")
  #curve_group_condition2vs4
  
}

###### Model 5 ######

# define contrasts

contrasts(power_df_full$condition) <- contr.treatment(5, base = 4)

if (audit_coding == 'binary') {

  # fit model
  
  model5 <- glmer(correct_path ~ condition*group*version + (1 | id), family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model5
  
  # plot data
  
  aggr_power_df_full <- power_df_full %>%
    group_by(condition, group, version) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model5 <- ggplot(aggr_power_df_full, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ version + group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model5
  
  # power analyses per effect
  
  sim_model5_group_condition2vs4_version <- powerSim(model5, nsim=simnum, test = fixed("condition2:group2:version1"), fitOpts=list(control=glmerctrlist))
  sim_model5_group_condition2vs4_version
  #curve_group_condition2vs4_version <- powerCurve(model5, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs4_version
  
} else if (audit_coding == 'continuous') {
  
  # fit model
  
  model5 <- glmer(correct_path ~ condition*audit*version + (1 | id), family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  model5
  
  # plot data
  
  aggr_power_df_full <- power_df_full %>%
    group_by(condition, group, version) %>%
    summarise(mean_correct = mean(correct_path, na.rm = TRUE),
              se_correct = sd(correct_path, na.rm = TRUE)/sqrt(n()),
              ci_l = ci(correct_path, na.rm=TRUE)[2],
              ci_u = ci(correct_path, na.rm=TRUE)[3],
              n = n()
    )
  
  plot_model5 <- ggplot(aggr_power_df_full, aes(x=condition, y=mean_correct)) +
    geom_bar(stat="identity", fill="lightblue") +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.2,
                  position=position_dodge(.9)) +
    facet_wrap(~ version + group) +
    scale_y_continuous("% correct paths", limits = c(0, 1)) +
    theme_light(base_size = 16) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  plot_model5
  
  # power analyses per effect
  
  sim_model5_group_condition2vs4_version <- powerSim(model5, nsim=simnum, test = fixed("condition2:audit:version1"), fitOpts=list(control=glmerctrlist))
  sim_model5_group_condition2vs4_version
  #curve_group_condition2vs4_version <- powerCurve(model5, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
  #curve_group_condition2vs4_version
  
}

save(model1, model2, model3, model4, model5, sim_model1_condition2vs5, sim_model1_condition4vs5,
     sim_model2_condition2vs3, sim_model2_condition4vs3, sim_model3_group_condition2vs5, sim_model3_group_condition4vs5,
     sim_model3_group_condition2vs5_version, sim_model3_group_condition4vs5_version,
     sim_model3a_group_condition2vs5, sim_model3a_group_condition4vs5,
     sim_model4_group_condition2vs4, sim_model5_group_condition2vs4_version,
     file = file.path(code_path, paste("power_analysis_", sample, "_", audit_coding, "_", total_n, "_3.RData", sep="")))





