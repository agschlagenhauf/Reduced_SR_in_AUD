##### READ IN DATA FROM CSV ###
##### Milena Musial ###########
##### 06 - 2024 ###############

rm(list = ls(all = TRUE))

##### Load packages
packages <- c("dplyr", "ggplot2", "tidyr", "gmodels")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)

##### define paths
data_path <- "WP3_DATA/FINAL_STUDY"

##### read IDs with complete data
load(file.path(data_path, "RDFs/IDs_complete.RData"))

##### read raw data files
auditpre_alc_lowrisk <- read.csv(file.path(data_path, "demo_psych_data/RedCap_AUDIT_alc_lowrisk.csv"))
auditpre_alc_harmful <- read.csv(file.path(data_path, "demo_psych_data/RedCap_AUDIT_alc_highrisk.csv"))
auditpre_con_lowrisk <- read.csv(file.path(data_path, "demo_psych_data/RedCap_AUDIT_control_lowrisk.csv"))
auditpre_con_harmful <- read.csv(file.path(data_path, "demo_psych_data/RedCap_AUDIT_control_highrisk.csv"))

demo_alc_lowrisk <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_alc_lowrisk.csv"))
demo_alc_harmful <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_alc_highrisk.csv"))
demo_con_lowrisk <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_control_lowrisk.csv"))
demo_con_harmful <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_control_highrisk.csv"))

psych_alc_lowrisk <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_alc_lowrisk.csv"))
psych_alc_harmful <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_alc_highrisk.csv"))
psych_con_lowrisk <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_control_lowrisk.csv"))
psych_con_harmful <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_control_highrisk.csv"))

##### filter raw files to include ids with complete data only

# filter audit pre scores
auditpre_alc_lowrisk$prolific_pid[auditpre_alc_lowrisk$rnd_id=="8915"] <- "66a79f059cc23eaa09b04cf9" # insert prolific ID for participant for whom it wasn't automatically piped
auditpre_alc_lowrisk <- auditpre_alc_lowrisk %>%
  filter(rnd_id != 9196) %>% # first try of same participant, no questionnaires with this rnd_id
  filter(prolific_pid %in% prolific_alc_lowrisk$Participant.id,
         complete.cases(rnd_id))

auditpre_alc_harmful <- auditpre_alc_harmful %>%
  mutate(prolific_pid = case_match(rnd_id,
                                   8396 ~ "TRRalc001",
                                   7724 ~ "TRRalc002",
                                   9164 ~ "TRRalc003",
                                   .default = prolific_pid)) %>%
  filter(prolific_pid %in% prolific_alc_harmful$Participant.id,
         complete.cases(rnd_id))

auditpre_con_lowrisk <- auditpre_con_lowrisk %>%
  filter(prolific_pid %in% prolific_con_lowrisk$Participant.id,
         complete.cases(rnd_id))

auditpre_con_harmful <- auditpre_con_harmful %>%
  mutate(prolific_pid = case_match(rnd_id,
                                   7957 ~ "TRRcon001",
                                   7982 ~ "TRRcon002",
                                   6371 ~ "TRRcon003",
                                   3674 ~ "TRRcon004",
                                   .default = prolific_pid)) %>%
  filter(prolific_pid %in% prolific_con_harmful$Participant.id,
         complete.cases(rnd_id))

# filter demo scores 
demo_alc_lowrisk$prolific_pid[demo_alc_lowrisk$rnd_id=="8915"] <- "66a79f059cc23eaa09b04cf9" # insert prolific ID for participant for whom it wasn't automatically piped
demo_alc_lowrisk <- demo_alc_lowrisk %>%
  filter(rnd_id != 9196) %>% # first try of same participant, no questionnaires with this rnd_id
  filter(prolific_pid %in% prolific_alc_lowrisk$Participant.id,
         complete.cases(rnd_id))

demo_alc_harmful <- demo_alc_harmful %>%
  mutate(prolific_pid = case_match(rnd_id,
                                   8396 ~ "TRRalc001",
                                   7724 ~ "TRRalc002",
                                   9164 ~ "TRRalc003",
                                   .default = prolific_pid)) %>%
  filter(prolific_pid %in% prolific_alc_harmful$Participant.id,
         complete.cases(rnd_id))

demo_con_lowrisk <- demo_con_lowrisk %>%
  filter(prolific_pid %in% prolific_con_lowrisk$Participant.id,
         complete.cases(rnd_id))

demo_con_harmful <- demo_con_harmful %>%
  mutate(prolific_pid = case_match(rnd_id,
                                   7957 ~ "TRRcon001",
                                   7982 ~ "TRRcon002",
                                   6371 ~ "TRRcon003",
                                   3674 ~ "TRRcon004",
                                   .default = prolific_pid)) %>%
  filter(prolific_pid %in% prolific_con_harmful$Participant.id,
         complete.cases(rnd_id))

# filter psychometric scores based on audit pre score ids
psych_alc_lowrisk <- psych_alc_lowrisk %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% auditpre_alc_lowrisk$rnd_id,
         participant_id %in% auditpre_alc_lowrisk$participant_id,
         complete.cases(rnd_id))

psych_alc_harmful <- psych_alc_harmful %>%
  mutate(rnd_id = ifelse(rnd_id==6893, 8045, rnd_id)) %>% # wrong rnd_id recorded
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% auditpre_alc_harmful$rnd_id,
         participant_id %in% auditpre_alc_harmful$participant_id,
         complete.cases(rnd_id))

psych_con_lowrisk <- psych_con_lowrisk %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% auditpre_con_lowrisk$rnd_id,
         participant_id %in% auditpre_con_lowrisk$participant_id,
         complete.cases(rnd_id))

psych_con_harmful <- psych_con_harmful %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% auditpre_con_harmful$rnd_id,
         participant_id %in% auditpre_con_harmful$participant_id,
         complete.cases(rnd_id))

##### merge all dfs by group and version
demo_psych_df_alc_lowrisk <- left_join(demo_alc_lowrisk, auditpre_alc_lowrisk)
demo_psych_df_alc_lowrisk <- left_join(demo_psych_df_alc_lowrisk, psych_alc_lowrisk)
demo_psych_df_alc_lowrisk <- demo_psych_df_alc_lowrisk %>%
  mutate(version = "alcohol",
         group = "low-risk")

demo_psych_df_alc_harmful <- left_join(demo_alc_harmful, auditpre_alc_harmful)
demo_psych_df_alc_harmful <- left_join(demo_psych_df_alc_harmful, psych_alc_harmful)
demo_psych_df_alc_harmful <- demo_psych_df_alc_harmful %>%
  mutate(version = "alcohol",
         group = "harmful")

demo_psych_df_con_lowrisk <- left_join(demo_con_lowrisk, auditpre_con_lowrisk)
demo_psych_df_con_lowrisk <- left_join(demo_psych_df_con_lowrisk, psych_con_lowrisk)
demo_psych_df_con_lowrisk <- demo_psych_df_con_lowrisk %>%
  mutate(version = "control",
         group = "low-risk")

demo_psych_df_con_harmful <- left_join(demo_con_harmful, auditpre_con_harmful)
demo_psych_df_con_harmful <- left_join(demo_psych_df_con_harmful, psych_con_harmful)
demo_psych_df_con_harmful <- demo_psych_df_con_harmful %>%
  mutate(version = "control",
         group = "harmful")

demo_psych_df_alc <- rbind(demo_psych_df_alc_harmful, demo_psych_df_alc_lowrisk)
demo_psych_df_con <- rbind(demo_psych_df_con_harmful, demo_psych_df_con_lowrisk)

rm(list=setdiff(ls(), c("demo_psych_df_alc", "demo_psych_df_con", "data_path")))

##### renaming and restructuring

demo_psych_df_alc <- demo_psych_df_alc %>%
  rename(redcap_ID = participant_id,
         prolific_ID = prolific_pid,
         participant_ID = rnd_id,
         running_ID = zufalls_id,
         age = screen_age,
         sex = screen_gender,
         audit_pre = b01_wp3_audit_sum) %>%
  mutate(redcap_ID = as.factor(redcap_ID),
         prolific_ID = as.factor(prolific_ID),
         participant_ID = as.factor(participant_ID),
         running_ID = as.factor(running_ID),
         age = as.numeric(age),
         sex = factor(sex, labels = c("female", "male", "other")),
         audit_post = b01_wp3_audit01 + b01_wp3_audit02 + b01_wp3_audit03 +
           b01_wp3_audit04 + b01_wp3_audit05 + b01_wp3_audit06 +
           b01_wp3_audit07 + b01_wp3_audit08 + b01_wp3_audit09 +
           b01_wp3_audit10) %>%
  select(prolific_ID,
         participant_ID,
         running_ID,
         redcap_ID,
         group,
         version,
         age,
         sex,
         audit_pre,
         audit_post)

demo_psych_df_con <- demo_psych_df_con %>%
  rename(redcap_ID = participant_id,
         prolific_ID = prolific_pid,
         participant_ID = rnd_id,
         running_ID = zufalls_id,
         age = screen_age,
         sex = screen_gender,
         audit_pre = b01_wp3_audit_sum) %>%
  mutate(redcap_ID = as.factor(redcap_ID),
         prolific_ID = as.factor(prolific_ID),
         participant_ID = as.factor(participant_ID),
         running_ID = as.factor(running_ID),
         age = as.numeric(age),
         sex = factor(sex, labels = c("female", "male")),
         audit_post = b01_wp3_audit01 + b01_wp3_audit02 + b01_wp3_audit03 +
           b01_wp3_audit04 + b01_wp3_audit05 + b01_wp3_audit06 +
           b01_wp3_audit07 + b01_wp3_audit08 + b01_wp3_audit09 +
           b01_wp3_audit10) %>%
  select(prolific_ID,
         participant_ID,
         running_ID,
         redcap_ID,
         group,
         version,
         age,
         sex,
         audit_pre,
         audit_post)

# check that group label matches audit score
if (max(demo_psych_df_alc$audit_pre[demo_psych_df_alc$group=="low-risk"])<8) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}
if (min(demo_psych_df_alc$audit_pre[demo_psych_df_alc$group=="harmful"])>7) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}

if (max(demo_psych_df_con$audit_pre[demo_psych_df_con$group=="low-risk"])<8) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}
if (min(demo_psych_df_con$audit_pre[demo_psych_df_con$group=="harmful"])>7) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}

##############################  save   ##############################  
save(demo_psych_df_alc, demo_psych_df_con, file = file.path(data_path, "RDFs/demo_psych_data.RData"))
