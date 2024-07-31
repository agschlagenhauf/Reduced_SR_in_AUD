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
subj <- factor(1:200)
version <- factor(1:2)
group <- (factor(1:2))


trial_full <- rep(trial, 1000)
condition_full <- rep(rep(condition, each=5), 200)
subj_full <- rep(subj, each=25)
version_full <- rep(rep(version, each=1250), 2)
group_full <- rep(group, each=2500)
audit_sum_full <- rep(c(1:7), each=)

audit_sum_low <- sample(c(0:7), 100, replace = TRUE)
audit_sum_high <- sample(c(8:20), 100, replace = TRUE)
audit_sum <- c(audit_sum_low, audit_sum_high)

power_df <- data.frame(id=as.factor(subj_full), trial=as.factor(trial_full), condition=as.factor(condition_full), version=as.factor(version_full), group=as.factor(group_full), audit_sum=audit_sum)

contrasts(power_df$condition) <- contr.treatment(5, base = 5)
contrasts(power_df$version) <- contr.treatment(2, base = 2)
contrasts(power_df$group) <- contr.treatment(2, base = 1)

###### create categorical model ######

# intercept
# condition2
# condition3
# condition4
# condition5
# version1
# group2
# condition2*version1
# condition3*version1
# condition4*version1
# condition5*version1
# condition2*group2
# condition3*group2
# condition4*group2
# condition5*group2
# version2*group2
# condition2*version1*group2
# condition3*version1*group2
# condition4*version1*group2
# condition5*version1*group2

fixed <- c(-2,
           4, 2.5, 2, 2.5,
           1,
           -16,
           0.5, -1, -1, -1,
           33, 8, -3, 8,
           -0.5,
           0.3, 10, -5, 10)
rand <- list(1)
res <- 3

model <- simr::makeGlmer(y ~ condition*version*group + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df)
model

###### power analysis ######

sim_condition <- powerSim(model, nsim=100, test = fcompare(y ~ group*version))
sim_condition

sim_group <- powerSim(model, nsim=100, test = fcompare(y ~ condition*version + group))
sim_group

sim_version <- powerSim(model, nsim=100, test = fcompare(y ~ condition*group + version))
sim_version

###### create continuous model ######

# intercept
# condition2
# condition3
# condition4
# condition5
# version1
# audit_sum
# condition2*version1
# condition3*version1
# condition4*version1
# condition5*version1
# condition2*audit_sum
# condition3*audit_sum
# condition4*audit_sum
# condition5*audit_sum
# version2*audit_sum
# condition2*version1*audit_sum
# condition3*version1*audit_sum
# condition4*version1*audit_sum
# condition5*version1*audit_sum

fixed <- c(-2,
           4, 2.5, 2, 2.5,
           1,
           -16,
           0.5, -1, -1, -1,
           33, 8, -3, 8,
           -0.5,
           0.3, 10, -5, 10)
rand <- list(1)
res <- 3

model <- simr::makeGlmer(y ~ condition*version*audit_sum + (1 | id), family="binomial", fixef=fixed, VarCorr=rand, data=power_df)
model

###### power analysis ######

sim_condition <- powerSim(model, nsim=10, test = fcompare(y ~ audit_sum*version))
sim_condition

sim_audit_sum <- powerSim(model, nsim=10, test = fcompare(y ~ condition*version + audit_sum))
sim_audit_sum

sim_version <- powerSim(model, nsim=10, test = fcompare(y ~ condition*audit_sum + version))
sim_version
