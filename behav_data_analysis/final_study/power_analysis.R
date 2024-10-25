###### Set up ######

rm(list = ls(all = TRUE))

# Load packages
packages <- c("ggplot2", "dplyr", "tidyr", "lme4", "simr", "future", "gmodels", "sjPlot")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)
code_path <- "C:/Users/musialm/OneDrive - Charité - Universitätsmedizin Berlin/PhD/04_B01/WP3/Reduced_SR_in_AUD/data_analysis/final_study/"

effects <- 'selected_effects' # "selected_effects"
total_n <- 560
dropout_rate <- 0.25

plan(multisession, workers = 6) 
simnum = 100
glmerctrlist <- glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa")

###### create full DF ######

n <- total_n*(1-dropout_rate)

trial <- factor(1:5)
condition <- factor(1:5)
subj <- factor(1:n)
version <- factor(1:2)
group <- (factor(1:2))

trial_full <- rep(trial, n*5)
condition_full <- rep(rep(condition, each=5), n)
subj_full <- rep(subj, each=25)
version_full <- rep(rep(version, each=((n*5*5/2)/2), 2))
group_full <- rep(group, each=n*5*5/2)

audit_sum_low <- sample(c(0:7), n/2, replace = TRUE)
audit_sum_high <- sample(c(8:20), n/2, replace = TRUE)
audit_sum <- c(audit_sum_low, audit_sum_high)
audit_full <- rep(audit_sum, each=25)

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
                            audit=audit_full,
                            y = 1)

###### Simulate data based on model 3 ######

# define contrasts

contrasts(power_df_full$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_full$version) <- contr.treatment(2, base = 2)
contrasts(power_df_full$group) <- contr.treatment(2, base = 1)

# define effects based on pilot data in low-risk sample

# power analysis 1
# fixed <- c(-1.9,
#            3.2, 1.8, 0.9, 1.8,
#            0,
#            -0.5,
#            0.2, -0.2, -0.2, -0.2,
#            0.2, 0.8, 0, 0.8,
#            0,
#            0, -0.9, 0, 1.5)
# rand <- list(1.4)
# res <- 3.3

# power analysis 2
# fixed <- c(-1.9,
#            3.2, 1.8, 0.9, 1.8,
#            0,
#            -0.5,
#            0.2, -0.2, -0.2, -0.2,
#            0.2, 0.7, 0, 0.7,
#            0,
#            0, -0.8, 0, 1.4)
# rand <- list(1.4)
# res <- 3.3

# power analysis 3
# fixed <- c(-1.9,
#            3.2, 1.8, 0.9, 1.8,
#            0,
#            -0.5,
#            0.2, -0.2, -0.2, -0.2,
#            0.2, 0.8, 0, 0.8,
#            0,
#            0, -0.6, 0, 0.8)
# rand <- list(1.4)
# res <- 3.3

# power analysis 4
fixed <- c(-1.9,
           3.2, 1.8, 0.9, 1.8,
           0,
           -0.5,
           0.2, -0.2, -0.2, -0.2,
           0.2, 0.8, 0, 0.8,
           0,
           0, -0.7, 0, 1.2)
rand <- list(1.4)
res <- 3.3

# generate model

model3 <- simr::makeGlmer(correct_path ~ condition*version*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
model3
tab_model(model3, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))

# simulate data

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
contrasts(power_df_lowrisk_control$version) <- contr.treatment(2, base = 2)
contrasts(power_df_lowrisk_control$group) <- contr.treatment(2, base = 1)


# fit model

model1 <- glmer(correct_path ~ condition + (1 | id), family = binomial, data=power_df_lowrisk_control, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
tab_model(model1, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))

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
contrasts(power_df_lowrisk_control$version) <- contr.treatment(2, base = 2)
contrasts(power_df_lowrisk_control$group) <- contr.treatment(2, base = 1)


# fit model

model2 <- glmer(correct_path ~ condition + (1 | id), family = binomial, data=power_df_lowrisk_control, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
tab_model(model2, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))


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

# define contrasts

contrasts(power_df_full$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_full$version) <- contr.treatment(2, base = 2)
contrasts(power_df_full$group) <- contr.treatment(2, base = 1)

if (effects == 'all_effects') {
  
  # fit model
  
  model3 <- glmer(correct_path ~ condition*version*group + (1 | id), family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  tab_model(model3, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))
  
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
  
  sim_model3_group_condition4vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition4:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5
  
  sim_model3_group_condition4vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition4:version1:group2"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5_version
  
} else if (effects == 'selected_effects') {
  
  # define custom contrasts
  
  mm3_version <- model.matrix(y ~ 1 + version, data=power_df_full)
  version_alc <- mm3_version[,2] # version alc compared to version monetary
  
  mm3_group <- model.matrix(y ~ 1 + group, data=power_df_full)
  group_harmful <- mm3_group[,2] # group harmful compared to low-risk
  
  mm3_condition <- model.matrix(y ~ 1 + condition, data=power_df_full)
  condition_control <- mm3_condition[,2] # condition control compared to transition
  condition_goalstate <- mm3_condition[,3] # condition goalstate compared to transition
  condition_policy <- mm3_condition[,4] # condition policy compared to transition
  condition_reward <- mm3_condition[,5] # condition policy compared to transition
  
  # fit model without main effecs and 2-way interactions of version
  
  model3 <- glmer(correct_path ~ 
                    condition_control + condition_goalstate + condition_policy + condition_reward +
                    group_harmful +
                    condition_control:group_harmful + condition_goalstate:group_harmful +
                    condition_policy:group_harmful + condition_reward:group_harmful +
                    condition_control:group_harmful:version_alc + condition_goalstate:group_harmful:version_alc +
                    condition_policy:group_harmful:version_alc + condition_reward:group_harmful:version_alc + 
                    (1 | id), family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  tab_model(model3, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))
  
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
  
  sim_model3_group_condition4vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition_reward:group_harmful"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5
  
  sim_model3_group_condition4vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition_reward:group_harmful:version_alc"), fitOpts=list(control=glmerctrlist))
  sim_model3_group_condition4vs5_version
  
}

###### Model 4 ######

# define contrasts 

contrasts(power_df_alcohol$condition) <- contr.treatment(5, base = 4)
contrasts(power_df_alcohol$version) <- contr.treatment(2, base = 2)
contrasts(power_df_alcohol$group) <- contr.treatment(2, base = 1)

# fit model

model4 <- glmer(correct_path ~ condition*group + (1 | id), family = binomial, data=power_df_alcohol, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
tab_model(model4, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))

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

###### Model 5 ######

# define contrasts

contrasts(power_df_full$condition) <- contr.treatment(5, base = 4)
contrasts(power_df_full$version) <- contr.treatment(2, base = 2)
contrasts(power_df_full$group) <- contr.treatment(2, base = 1)

if (effects == 'all_effects') {
  
  # fit model
  
  model5 <- glmer(correct_path ~ condition*group*version + (1 | id), family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  tab_model(model5, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))
  
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
  
} else if (effects == 'selected_effects') {
  
  # define custom contrasts
  
  mm4_version <- model.matrix(y ~ 1 + version, data=power_df_full)
  version_alc <- mm4_version[,2] # version alc compared to version monetary
  
  mm4_group <- model.matrix(y ~ 1 + group, data=power_df_full)
  group_harmful <- mm4_group[,2] # group harmful compared to low-risk
  
  mm4_condition <- model.matrix(y ~ 1 + condition, data=power_df_full)
  condition_control <- mm4_condition[,2] # condition control compared to transition
  condition_goalstate <- mm4_condition[,3] # condition goalstate compared to transition
  condition_policy <- mm4_condition[,4] # condition policy compared to transition
  condition_transition <- mm4_condition[,5] # condition policy compared to transition
  
  # fit model
  
  model5 <- glmer(correct_path ~ 
                    condition_control + condition_goalstate + condition_policy + condition_transition +
                    group_harmful +
                    condition_control:group_harmful + condition_goalstate:group_harmful +
                    condition_policy:group_harmful + condition_transition:group_harmful +
                    condition_control:group_harmful:version_alc + condition_goalstate:group_harmful:version_alc +
                    condition_policy:group_harmful:version_alc + condition_transition:group_harmful:version_alc +
                    (1 | id), 
                  family = binomial, data=power_df_full, glmerControl(optCtrl=list(maxfun=1e5), optimizer = "bobyqa"))
  tab_model(model5, transform = NULL, show.est = T, show.stat = T, auto.label = FALSE, CSS = list(css.table = '+font-size: 14;'))
  
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
  
  sim_model5_group_condition2vs4_version <- powerSim(model5, nsim=simnum, test = fixed("condition_goalstate:group_harmful:version_alc"), fitOpts=list(control=glmerctrlist))
  sim_model5_group_condition2vs4_version
  
}

save(model1, model2, model3, model4, model5, 
     sim_model1_condition2vs5, sim_model1_condition4vs5,
     sim_model2_condition2vs3, sim_model2_condition4vs3, 
     sim_model3_group_condition4vs5, sim_model3_group_condition4vs5_version,
     sim_model4_group_condition2vs4, 
     sim_model5_group_condition2vs4_version,
     file = file.path(code_path, paste("power_analysis_4_selected_effects_", total_n, ".RData", sep="")))




