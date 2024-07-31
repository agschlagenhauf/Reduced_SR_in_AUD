##### READ IN DATA FROM CSV ###
##### Milena Musial ###########
##### 06 - 2024 ###############

rm(list = ls(all = TRUE))

##### Load packages
packages <- c("dplyr", "ggplot2", "tidyr", "gmodels")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)

##### define paths
demo_data_path <- "WP3_DATA/PILOT_3/demo_data"
psychometric_data_path <- "WP3_DATA/PILOT_3/psychometric_data"
behav_data_path <- "WP3_DATA/PILOT_3/behavioral_data"

##### read files
demo_df_alc <- read.csv(file.path(demo_data_path, "alcohol_TRR265B01WP3aOnlineS-Demo_DATA_2024-07-09_1548.csv"))
demo_df_con <- read.csv(file.path(demo_data_path, "control_TRR265B01WP3aOnlineS-Demo_DATA_2024-07-07_1408.csv"))
demo_df <- rbind(demo_df_alc, demo_df_con)

aud_df_alc <- read.csv(file.path(psychometric_data_path, "alcohol_TRR265B01WP3aOnlineS-AUDCriteriaDetox_DATA_2024-07-09_1544.csv"))
aud_df_con <- read.csv(file.path(psychometric_data_path, "control_TRR265B01WP3aOnlineS-AUDCriteriaDetox_DATA_2024-07-07_1439.csv"))
aud_df <- rbind(aud_df_alc, aud_df_con)

audit_df_alc <- read.csv(file.path(psychometric_data_path, "alcohol_TRR265B01WP3aOnlineS-AUDIT_DATA_2024-07-09_1547.csv"))
audit_df_con <- read.csv(file.path(psychometric_data_path, "control_TRR265B01WP3aOnlineS-AUDIT_DATA_2024-07-07_1439.csv"))
audit_df <- rbind(audit_df_alc, audit_df_con)

load(file.path(behav_data_path, "pilot_data_complete.RData"))

#### summarize demographic data

# format demo df
demo_df <- demo_df %>%
  rename(ID = rnd_id,
         redcap_ID = participant_id,
         age = screen_age,
         sex = screen_gender) %>%
  mutate(ID = as.factor(ID),
         age = as.numeric(age),
         sex = factor(sex, labels = c("female", "male"))) %>%
  select(ID,
         redcap_ID,
         prolific_pid,
         age,
         sex) %>%
  filter(ID %in% unique(trial_df$ID)) %>%
  filter(complete.cases(.))

# format aud df
aud_df <- aud_df %>%
  rename(ID = rnd_id,
         redcap_ID = participant_id,) %>%
  mutate(ID = as.factor(ID),
         aud_sum = as.factor(aud_sum)) %>%
  select(! c(controlgroup)) %>%
  filter(ID %in% unique(trial_df$ID)) %>%
  filter(complete.cases(.))

# format audit df
audit_df <- audit_df %>%
  rename(ID = rnd_id,
         redcap_ID = participant_id,) %>%
  mutate(ID = as.factor(ID)) %>%
  filter(ID %in% unique(trial_df$ID)) %>%
  filter(complete.cases(.)) %>%
  rowwise() %>%
  mutate(audit_sum = sum(b01_wp3_audit01,
                         b01_wp3_audit02,
                         b01_wp3_audit03,
                         b01_wp3_audit04,
                         b01_wp3_audit05,
                         b01_wp3_audit06,
                         b01_wp3_audit07,
                         b01_wp3_audit08,
                         b01_wp3_audit09,
                         b01_wp3_audit10)) %>%
  mutate(audit_group = case_when((audit_sum < 8) ~ "low-risk",
                                 (audit_sum > 7) ~ "harmful")) %>%
  mutate(audit_group = as.factor(audit_group))

# filter demo_df to only include participants who completed questionnaires
demo_df <- demo_df %>%
  filter(redcap_ID %in% aud_df$redcap_ID)

# merge dfs 
demo_psych_df <- merge.data.frame(demo_df, aud_df, by = c("ID", "redcap_ID"))
demo_psych_df <- merge.data.frame(demo_psych_df, audit_df, by = c("ID", "redcap_ID"))

##############################  save   ##############################  
save(demo_psych_df, file = file.path(demo_data_path, "demo_psych_data.RData"))
