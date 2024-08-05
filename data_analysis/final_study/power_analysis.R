###### Set up ######

rm(list = ls(all = TRUE))

# Load packages
packages <- c("ggplot2", "dplyr", "tidyr", "lme4", "sjPlot", "simr")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)

# define paths
data_path <- "C:/Users/musialm/OneDrive - Charité - Universitätsmedizin Berlin/PhD/04_B01/WP3/WP3_DATA/PILOT_3/behavioral_data"
demo_path <- "C:/Users/musialm/OneDrive - Charité - Universitätsmedizin Berlin/PhD/04_B01/WP3/WP3_DATA/PILOT_3/demo_data"

# read dfs
load(file.path(data_path, "pilot_data_complete.RData"))
load(file.path(demo_path, "demo_psych_data.RData"))

# add demo info trial df
trial_df <- merge(trial_df, demo_psych_df[,c("ID", "age", "sex", "audit_sum", "audit_group")], by = "ID", all.x=TRUE)

###### create DF ######

trial <- factor(1:5)
condition <- factor(1:5)
subj <- factor(1:300)
version <- factor(1:2)
group <- (factor(1:2))

trial_full <- rep(trial, 1500)
condition_full <- rep(rep(condition, each=5), 300)
subj_full <- rep(subj, each=25)
version_full <- rep(rep(version, each=1875), 2)
group_full <- rep(group, each=3750)

audit_sum_low <- sample(c(0:7), 150, replace = TRUE)
audit_sum_high <- sample(c(8:20), 150, replace = TRUE)
audit_sum <- c(audit_sum_low, audit_sum_high)

power_df_full <- data.frame(id=as.factor(subj_full), trial=as.factor(trial_full), condition=as.factor(condition_full), version=as.factor(version_full), group=as.factor(group_full), audit_sum=audit_sum)
power_df_lowrisk_control <- power_df_full[version == 1, group == 1, ]
power_df_alcohol <- power_df_full[version == 2, ]

simnum = 10

###### Model 1 ######

contrasts(power_df_lowrisk_control$condition) <- contr.treatment(5, base = 5)

fixed <- c(-1.9,
           3.7, 2.4, 1.5, 2.6)
rand <- list(1.1)
res <- 3.3

model1 <- simr::makeGlmer(y ~ condition + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_lowrisk_control)
model1

sim_condition2vs5 <- powerSim(model1, nsim=simnum, test = fixed("condition2", "z"))
sim_condition2vs5
sim_condition4vs5 <- powerSim(model1, nsim=simnum, test = fixed("condition4", "z"))
sim_condition4vs5

###### Model 2 ######

contrasts(power_df_lowrisk_control$condition) <- contr.treatment(5, base = 3)

fixed <- c(-0.4,
           2.3, 0.9, 1.1, -1.5)
rand <- list(1.1)
res <- 3.3

model2 <- simr::makeGlmer(y ~ condition + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_lowrisk_control)
model2

sim_condition2vs3 <- powerSim(model2, nsim=simnum, test = fixed("condition2", "z"))
sim_condition2vs3
sim_condition4vs3 <- powerSim(model2, nsim=simnum, test = fixed("condition4", "z"))
sim_condition4vs3

###### Model 3 ######

contrasts(power_df_full$condition) <- contr.treatment(5, base = 5)
contrasts(power_df_full$version) <- contr.treatment(2, base = 2)
contrasts(power_df_full$group) <- contr.treatment(2, base = 1)

fixed <- c(-1.9,
           3.8, 2.4, 1.5, 2.7,
           0,
           -5,
           0.7, -0.8, -0.8, -1.5,
           0, 30, 0, 30,
           1,
           0, 40, 0, 40)
rand <- list(1.4)
res <- 3.3

model3 <- simr::makeGlmer(y ~ condition*version*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
model3

sim_group_condition2vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition2:group2"))
sim_group_condition2vs5
curve_group_condition2vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition2:group2"), along = "id")
curve_group_condition2vs5

sim_group_condition4vs5 <- powerSim(model3, nsim=simnum, test = fixed("condition4:group2"))
sim_group_condition4vs5
curve_group_condition4vs5 <- powerCurve(model3, nsim=simnum, test = fixed("condition4:group2"), along = "id")
curve_group_condition4vs5

sim_group_condition2vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition2:version1:group2"))
sim_group_condition2vs5_version
curve_group_condition2vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
curve_group_condition2vs5_version

sim_group_condition4vs5_version <- powerSim(model3, nsim=simnum, test = fixed("condition4:version1:group2"))
sim_group_condition4vs5_version
curve_group_condition4vs5_version <- powerCurve(model3, nsim=simnum, test = fixed("condition4:version1:group2"), along = "id")
curve_group_condition4vs5_version

###### Model 4 ######

contrasts(power_df_alcohol$condition) <- contr.treatment(5, base = 4)

fixed <- c(-0.3,
           3.2, 0.5, -0.5, -1.2,
           1,
           0, -30, -5, -5)
rand <- list(1.7)
res <- 3.3

model4 <- simr::makeGlmer(y ~ condition*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_alcohol)
model4

sim_group_condition2vs4_version <- powerSim(model4, nsim=simnum, test = fixed("condition2:group2"))
sim_group_condition2vs4_version
curve_group_condition2vs4 <- powerCurve(model4, nsim=simnum, test = fixed("condition2:group2"), along = "id")
curve_group_condition2vs4


###### Model 5 ######

contrasts(power_df_full$condition) <- contr.treatment(5, base = 4)

fixed <- c(0.8,
           1.1, -0.3, -1.1, -2.7,
           0,
           0,
           2, 0.7, 0.7, 1.5,
           0, -30, -5, -5,
           1,
           0, -40, 0, -40)
rand <- list(1.4)
res <- 3.3

model5 <- simr::makeGlmer(y ~ condition*version*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df_full)
model5

sim_group_condition2vs4_version <- powerSim(model5, nsim=simnum, test = fixed("condition2:version1:group2"))
sim_group_condition2vs4_version
curve_group_condition2vs4_version <- powerCurve(model5, nsim=simnum, test = fixed("condition2:version1:group2"), along = "id")
curve_group_condition2vs4_version

