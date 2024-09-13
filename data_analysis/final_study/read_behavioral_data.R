##### PREPARE DATA FRAMES FOR BEHAVIORAL ANALYSES ##
##### Milena Musial ################################
##### 08 - 2024 ####################################

rm(list = ls(all = TRUE))

##### load packages

packages <- c("dplyr", "ggplot2", "rjson", "ndjson", "jsonlite", "tidyr", "lme4")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)

##### define paths

data_path <- "WP3_DATA/FINAL_STUDY"

##### read IDs that should be included (approved on Prolific, will be used to filter RedCap dfs)

# alcohol version
prolific_alc_lowrisk_1 <- read.csv(file.path(data_path, "inclusion_data/Prolific_SRepresent_8_alc_lowrisk.csv"))
prolific_alc_lowrisk_1 <- prolific_alc_lowrisk_1 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "alcohol",
         group = "low-risk")

prolific_alc_lowrisk_2 <- read.csv(file.path(data_path, "inclusion_data/Prolific_SRepresent_12_alc_lowrisk.csv"))
prolific_alc_lowrisk_2 <- prolific_alc_lowrisk_2 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "alcohol",
         group = "low-risk")

prolific_alc_lowrisk_3 <- read.csv(file.path(data_path, "inclusion_data/Prolific_BarNavigator_alc_lowrisk.csv"))
prolific_alc_lowrisk_3 <- prolific_alc_lowrisk_3 %>%
   filter(Status == "APPROVED") %>%
   select(Participant.id, Status) %>%
   mutate(version = "alcohol",
         group = "low-risk")

prolific_alc_harmful_1 <- read.csv(file.path(data_path, "inclusion_data/Prolific_SRepresent_9_alc_highrisk.csv"))
prolific_alc_harmful_1 <- prolific_alc_harmful_1 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "alcohol",
         group = "harmful")

prolific_alc_harmful_2 <- read.csv(file.path(data_path, "inclusion_data/Prolific_SRepresent_13_alc_highrisk.csv"))
prolific_alc_harmful_2 <- prolific_alc_harmful_2 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "alcohol",
         group = "harmful")

prolific_alc_lowrisk <- rbind(prolific_alc_lowrisk_1, prolific_alc_lowrisk_2, prolific_alc_lowrisk_3)
prolific_alc_harmful <- rbind(prolific_alc_harmful_1, prolific_alc_harmful_2)

# control version
prolific_con_lowrisk_1 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt1_control_lowrisk.csv"))
prolific_con_lowrisk_1 <- prolific_con_lowrisk_1 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "low-risk")

prolific_con_lowrisk_2 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt2_control_highrisk.csv"))
prolific_con_lowrisk_2 <- prolific_con_lowrisk_2 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "low-risk")

prolific_con_harmful_1 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt3_control_lowrisk.csv"))
prolific_con_harmful_1 <- prolific_con_harmful_1 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "harmful")

prolific_con_harmful_2 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt4_control_highrisk.csv"))
prolific_con_harmful_2 <- prolific_con_harmful_2 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "harmful")

prolific_con_lowrisk <- rbind(prolific_con_lowrisk_1, prolific_con_lowrisk_2)
prolific_con_harmful <- rbind(prolific_con_harmful_1, prolific_con_harmful_2)

##### read RedCap data

# alcohol version

# read pre data
redcap_alc_lowrisk <- read.csv(file.path(data_path, "inclusion_data/RedCap_alc_lowrisk.csv"))
redcap_alc_lowrisk$prolific_pid[redcap_alc_lowrisk$rnd_id=="8915"] <- "66a79f059cc23eaa09b04cf9" # insert prolific ID for participant for whom it wasn't automatically piped
redcap_alc_lowrisk <- redcap_alc_lowrisk %>%
   filter(prolific_pid %in% prolific_alc_lowrisk$Participant.id,
         complete.cases(rnd_id)) %>%
   select(participant_id, prolific_pid, rnd_id, zufalls_id, b01_wp3_audit_sum) %>%
   rename(redcap_ID = participant_id,
         prolific_ID = prolific_pid,
         participant_ID = rnd_id,
         running_ID = zufalls_id,
         audit_pre = b01_wp3_audit_sum) %>%
   mutate(version = "alcohol",
         group = "low-risk")

redcap_alc_harmful <- read.csv(file.path(data_path, "inclusion_data/RedCap_alc_highrisk.csv"))
redcap_alc_harmful <- redcap_alc_harmful %>%
   filter(prolific_pid %in% prolific_alc_harmful$Participant.id,
         complete.cases(rnd_id)) %>%
   select(participant_id, prolific_pid, rnd_id, zufalls_id, b01_wp3_audit_sum) %>%
   rename(redcap_ID = participant_id,
         prolific_ID = prolific_pid,
         participant_ID = rnd_id,
         running_ID = zufalls_id,
         audit_pre = b01_wp3_audit_sum) %>%
   mutate(version = "alcohol",
         group = "harmful")

# merge AUDIT post data
redcap_post_alc_lowrisk <- read.csv(file.path(data_path, "inclusion_data/RedCap_AUDITpost_alc_lowrisk.csv"))
redcap_post_alc_lowrisk <- redcap_post_alc_lowrisk %>%
   filter(rnd_id %in% redcap_alc_lowrisk$participant_ID,
          participant_id %in% redcap_alc_lowrisk$redcap_ID,
          complete.cases(rnd_id)) %>%
   mutate(audit_post = b01_wp3_audit01 + b01_wp3_audit02 + b01_wp3_audit03 +
                           b01_wp3_audit04 + b01_wp3_audit05 + b01_wp3_audit06 +
                           b01_wp3_audit07 + b01_wp3_audit08 + b01_wp3_audit09 +
                           b01_wp3_audit10,
         participant_ID = rnd_id,
         redcap_ID = participant_id) %>%
   select(redcap_ID, participant_ID, audit_post)
redcap_alc_lowrisk <- merge(redcap_alc_lowrisk, redcap_post_alc_lowrisk, by=c("participant_ID", "redcap_ID"))

redcap_post_alc_harmful <- read.csv(file.path(data_path, "inclusion_data/RedCap_AUDITpost_alc_highrisk.csv"))
redcap_post_alc_harmful <- redcap_post_alc_harmful %>%
   filter(rnd_id %in% redcap_alc_harmful$participant_ID,
          participant_id %in% redcap_alc_harmful$redcap_ID,
          complete.cases(rnd_id)) %>%
   mutate(audit_post = b01_wp3_audit01 + b01_wp3_audit02 + b01_wp3_audit03 +
                           b01_wp3_audit04 + b01_wp3_audit05 + b01_wp3_audit06 +
                           b01_wp3_audit07 + b01_wp3_audit08 + b01_wp3_audit09 +
                           b01_wp3_audit10,
         participant_ID = rnd_id,
         redcap_ID = participant_id) %>%
   select(redcap_ID, participant_ID, audit_post)
redcap_alc_harmful <- merge(redcap_alc_harmful, redcap_post_alc_harmful, by=c("participant_ID", "redcap_ID"))

redcap_alc <- rbind(redcap_alc_lowrisk, redcap_alc_harmful)

# check that group label matches audit score
if (max(redcap_alc$audit_pre[redcap_alc$group=="low-risk"])<8) {
   print("Labels match!")
} else {
   print("ATTENTION Labels don't match!")
}
if (min(redcap_alc$audit_pre[redcap_alc$group=="harmful"])>7) {
   print("Labels match!")
} else {
   print("ATTENTION Labels don't match!")
}

# control version

# read pre data
redcap_con_lowrisk <- read.csv(file.path(data_path, "inclusion_data/RedCap_control_lowrisk.csv"))
redcap_con_lowrisk <- redcap_con_lowrisk %>%
   filter(prolific_pid %in% prolific_con_lowrisk$Participant.id,
         complete.cases(rnd_id)) %>%
   select(participant_id, prolific_pid, rnd_id, zufalls_id, b01_wp3_audit_sum) %>%
   rename(redcap_ID = participant_id,
          prolific_ID = prolific_pid,
          participant_ID = rnd_id,
          running_ID = zufalls_id,
          audit_pre = b01_wp3_audit_sum) %>%
   mutate(version = "control",
         group = "low-risk")

redcap_con_harmful <- read.csv(file.path(data_path, "inclusion_data/RedCap_control_highrisk.csv"))
redcap_con_harmful <- redcap_con_harmful %>%
   filter(prolific_pid %in% prolific_con_harmful$Participant.id,
         complete.cases(rnd_id)) %>%
   select(participant_id, prolific_pid, rnd_id, zufalls_id, b01_wp3_audit_sum) %>%
   rename(redcap_ID = participant_id,
          prolific_ID = prolific_pid,
          participant_ID = rnd_id,
          running_ID = zufalls_id,
          audit_pre = b01_wp3_audit_sum) %>%
   mutate(version = "control",
         group = "harmful")

# merge AUDIT post data
redcap_post_con_lowrisk <- read.csv(file.path(data_path, "inclusion_data/RedCap_AUDITpost_control_lowrisk.csv"))
redcap_post_con_lowrisk <- redcap_post_con_lowrisk %>%
   filter(rnd_id %in% redcap_con_lowrisk$participant_ID,
          participant_id %in% redcap_con_lowrisk$redcap_ID,
          complete.cases(rnd_id)) %>%
   mutate(audit_post = b01_wp3_audit01 + b01_wp3_audit02 + b01_wp3_audit03 +
                           b01_wp3_audit04 + b01_wp3_audit05 + b01_wp3_audit06 +
                           b01_wp3_audit07 + b01_wp3_audit08 + b01_wp3_audit09 +
                           b01_wp3_audit10,
         participant_ID = rnd_id,
         redcap_ID = participant_id) %>%
   select(redcap_ID, participant_ID, audit_post)
redcap_con_lowrisk <- merge(redcap_con_lowrisk, redcap_post_con_lowrisk, by=c("participant_ID", "redcap_ID"))

redcap_post_con_harmful <- read.csv(file.path(data_path, "inclusion_data/RedCap_AUDITpost_control_highrisk.csv"))
redcap_post_con_harmful <- redcap_post_con_harmful %>%
   filter(rnd_id %in% redcap_con_harmful$participant_ID,
          participant_id %in% redcap_con_harmful$redcap_ID,
          complete.cases(rnd_id)) %>%
   mutate(audit_post = b01_wp3_audit01 + b01_wp3_audit02 + b01_wp3_audit03 +
                           b01_wp3_audit04 + b01_wp3_audit05 + b01_wp3_audit06 +
                           b01_wp3_audit07 + b01_wp3_audit08 + b01_wp3_audit09 +
                           b01_wp3_audit10,
         participant_ID = rnd_id,
         redcap_ID = participant_id) %>%
   select(redcap_ID, participant_ID, audit_post)
redcap_con_harmful <- merge(redcap_con_harmful, redcap_post_con_harmful, by=c("participant_ID", "redcap_ID"))

redcap_con <- rbind(redcap_con_lowrisk, redcap_con_harmful)

# check that group label matches audit score
if (max(redcap_con$audit_pre[redcap_con$group=="low-risk"])<8) {
   print("Labels match!")
} else {
   print("ATTENTION Labels don't match!")
}
if (min(redcap_con$audit_pre[redcap_con$group=="harmful"])>7) {
   print("Labels match!")
} else {
   print("ATTENTION Labels don't match!")
}

##### read in behavioral data from .json and convert to df

# alcohol version

# full alcohol df
data_raw_alcohol <- readLines(file.path(data_path, "behavioral_data/alcohol_jatos_results.txt"))
data_list_alcohol <- lapply(data_raw_alcohol,fromJSON)
data_list_of_df_alcohol <- lapply(data_list_alcohol, data.frame, stringsAsFactors = FALSE)
data_df_alcohol <- bind_rows(data_list_of_df_alcohol)
data_df_alcohol <- data_df_alcohol %>% 
  unnest(c(aggregate_results.trialResults, 
           tutorial_results.trialResults,
           rating_results.ratingResults),
         names_sep = "_",
         keep_empty = TRUE)

# filter included participants based on redcap df
data_df_alcohol <- data_df_alcohol %>%
  filter(participant_ID %in% redcap_alc$participant_ID,
         running_ID %in% redcap_alc$running_ID)

# read data from participants with old rating version
data_raw_alcohol_oldrating <- readLines(file.path(data_path, "behavioral_data/old_alcohol_version/alcohol_jatos_results_data_20240822172007.txt"))
data_list_alcohol_oldrating <- lapply(data_raw_alcohol_oldrating,fromJSON)
data_list_of_df_alcohol_oldrating <- lapply(data_list_alcohol_oldrating, data.frame, stringsAsFactors = FALSE)
data_df_alcohol_oldrating <- bind_rows(data_list_of_df_alcohol_oldrating)
data_df_alcohol_oldrating <- data_df_alcohol_oldrating %>% 
  unnest(c(aggregate_results.trialResults, 
           tutorial_results.trialResults,
           rating_results.ratingResults),
         names_sep = "_",
         keep_empty = TRUE)

# filter participants with old rating version based on redcap df
data_df_alcohol_oldrating <- data_df_alcohol_oldrating %>%
  filter(participant_ID %in% redcap_alc$participant_ID,
         running_ID %in% redcap_alc$running_ID)

# get IDs with old rating version
oldrating_IDs <- unique(data_df_alcohol_oldrating$participant_ID)

# write info about rating into full alcohol df
data_df_alcohol <- data_df_alcohol %>%
  mutate(rating_version = ifelse(participant_ID %in% oldrating_IDs, "old", "new"))

# merge with prolific_id, group, version info
data_df_alcohol <- inner_join(data_df_alcohol, redcap_alc, by=c("participant_ID", "running_ID"))

# control version

# full control df
data_raw_control <- readLines(file.path(data_path, "behavioral_data/control_jatos_results.txt"))
data_list_control <- lapply(data_raw_control,fromJSON)
data_list_of_df_control <- lapply(data_list_control, data.frame, stringsAsFactors = FALSE)
data_df_control <- bind_rows(data_list_of_df_control)
data_df_control <- data_df_control %>% 
  unnest(c(aggregate_results.trialResults, 
           tutorial_results.trialResults,
           rating_results.ratingResults),
         names_sep = "_",
         keep_empty = TRUE)
data_df_control <- data_df_control %>%
   mutate(drink = NA,
   rating_version = "new")

# filter included participants based on redcap df
data_df_control <- data_df_control %>%
  filter(participant_ID %in% redcap_con$participant_ID,
         running_ID %in% redcap_con$running_ID)

# merge with prolific_id, group, version info
data_df_control <- inner_join(redcap_con, data_df_control, by=c("participant_ID", "running_ID"))

##### Combine control and alcohol dfs
data_df <- rbind(data_df_control, data_df_alcohol)

# clean workspace
rm(list=setdiff(ls(), c("data_df", "data_path")))
         
##############################  trial-df   ############################## 

# basic restructuring
trial_df <- data_df %>%
  select(prolific_ID,
         group,
         audit_pre,
         audit_post,
         version,
         component,
         variation,
         correct_first_state_action,
         aggregate_results.trial,
         aggregate_results.trialResults_state,
         aggregate_results.trialResults_valid_choice,
         aggregate_results.trialResults_choice,
         aggregate_results.trialResults_RT,
         rating_version,
         rating_results.rating,
         rating_results.ratingResults_state,
         rating_results.ratingResults_value,
         rating_results.ratingResults_RT
         ) %>%
  rename(ID = prolific_ID,
         trial = aggregate_results.trial,
         state = aggregate_results.trialResults_state,
         valid_choice = aggregate_results.trialResults_valid_choice,
         choice = aggregate_results.trialResults_choice,
         RT = aggregate_results.trialResults_RT,
         rating_no = rating_results.rating,
         rating_state = rating_results.ratingResults_state,
         rating_value = rating_results.ratingResults_value,
         rating_RT = rating_results.ratingResults_RT
         ) %>%
  filter(! component %in% c("intro1", 
                            "intro2", 
                            "intro3",
                            "intro4",
                            "floor-plan",
                            "drink-selection",
                            "tutorial", 
                            "quiz", 
                            "quiz_wrong",
                            "outro",
                            "interlude-1",
                            "interlude-2",
                            "interlude-3",
                            "interlude-4")) %>%
  mutate_at(c('ID', 'component'), as.factor)

# create phase and condition variables
trial_df <- trial_df %>%
   mutate(phase = if_else(component %in% c("control-learning", 
                                          "reward-learning", 
                                          "transition-learning", 
                                          "goal-state-learning",
                                          "policy-learning"), "learning", 
                         if_else(component %in% c("control-relearning",
                                                  "reward-relearning",
                                                  "transition-relearning",
                                                  "goal-state-relearning",
                                                  "policy-relearning"), "relearning", 
                                 if_else(component %in% c("control-test",
                                                          "reward-test",
                                                          "transition-test",
                                                          "goal-state-test",
                                                          "policy-test"), "test", 
                                         if_else(component %in% c("control-rating",
                                                                  "reward-rating",
                                                                  "transition-rating",
                                                                  "goal-state-rating",
                                                                  "policy-rating"), "rating", 
                                                 "other")))),
         condition = if_else(component %in% c("control-learning",
                                              "control-relearning",
                                              "control-test",
                                              "control-rating"), "control", 
                             if_else(component %in% c("reward-learning",
                                                      "reward-relearning",
                                                      "reward-test",
                                                      "reward-rating"), "reward",
                                    if_else(component %in% c("transition-learning",
                                                              "transition-relearning",
                                                              "transition-test",
                                                              "transition-rating"), "transition", 
                                             if_else(component %in% c("goal-state-learning",
                                                                      "goal-state-relearning",
                                                                      "goal-state-test",
                                                                      "goal-state-rating"), "goal-state",
                                                     if_else(component %in% c("policy-learning",
                                                                              "policy-relearning",
                                                                              "policy-test",
                                                                              "policy-rating"), "policy", 
                                                             "other"))))))

# create component index variable
trial_df <- trial_df %>%
   mutate(condition_index = case_when(((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "reward") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "transition") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "policy") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "goal-state") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "control")) ~ 1,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "transition") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "policy") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "goal-state") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "control") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "reward")) ~ 2,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "policy") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "goal-state") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "control") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "reward") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "transition")) ~ 3,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "goal-state") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "control") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "reward") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "transition") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "policy")) ~ 4,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "control") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "reward") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "transition") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "policy") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "goal-state")) ~ 5)
         )

# create environment variable
trial_df <- trial_df %>%
  mutate(environment = case_when(((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 2)) ~ "white_modern",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 3)) ~ "blue_floral",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 4)) ~ "messy_green",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 5)) ~ "orange_tile",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 1)) ~ "red_brown",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 2)) ~ "alternative",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 3)) ~ "brauhaus",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 4)) ~ "fancy_green",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 5)) ~ "hip_purple",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 1)) ~ "sports_bar"))

# ordering
trial_df <- trial_df %>%
  arrange(ID, 
          condition, 
          phase)

# insert correct test-stage action
for (n in unique(trial_df$ID)) {
  for (condition in c("control", "reward", "transition", "goal-state", "policy")) {
    trial_df$correct_first_state_action[trial_df$ID == n & trial_df$component == (paste(condition, "-test", sep=""))] = 
      trial_df$correct_first_state_action[trial_df$ID == n & trial_df$component == paste(condition, "-relearning", sep="")][1]
    trial_df$correct_first_state_action[trial_df$ID == n & trial_df$component == (paste(condition, "-rating", sep=""))] = 
      trial_df$correct_first_state_action[trial_df$ID == n & trial_df$component == paste(condition, "-relearning", sep="")][1]
  }
}

# calculate correct for every 2-choice state
trial_df <- trial_df %>%
  mutate(correct_second_state_action = case_when((phase == "learning" & correct_first_state_action == "right" & condition %in% c("reward", "goal-state", "control")) ~ "left",
                                                 (phase == "learning" & correct_first_state_action == "right" & condition %in% c("transition", "policy")) ~ "right",
                                                 (phase == "learning" & correct_first_state_action == "left" & condition %in% c("reward", "goal-state", "control")) ~ "left",
                                                 (phase == "learning" & correct_first_state_action == "left" & condition %in% c("transition", "policy")) ~ "left",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "left" & condition %in% c("reward", "goal-state", "control")) ~ "left",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "left" & condition %in% c("transition", "policy")) ~ "left",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "right" & condition %in% c("reward", "goal-state", "control")) ~ "left",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "right" & condition %in% c("transition", "policy")) ~ "left"),
         correct_third_state_action = case_when((phase == "learning" & correct_first_state_action == "right" & condition %in% c("reward", "goal-state", "control")) ~ "right",
                                                 (phase == "learning" & correct_first_state_action == "right" & condition %in% c("transition", "policy")) ~ "right",
                                                 (phase == "learning" & correct_first_state_action == "left" & condition %in% c("reward", "goal-state", "control")) ~ "right",
                                                 (phase == "learning" & correct_first_state_action == "left" & condition %in% c("transition", "policy")) ~ "left",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "left" & condition %in% c("reward", "goal-state", "control")) ~ "right",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "left" & condition %in% c("transition", "policy")) ~ "right",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "right" & condition %in% c("reward", "goal-state", "control")) ~ "right",
                                                 (phase %in% c("test", "rating") & correct_first_state_action == "right" & condition %in% c("transition", "policy")) ~ "right")
         ) %>%
  mutate(correct_state_1 = if_else((state == 1 & correct_first_state_action == choice), 1,
                                   if_else((state == 1 & correct_first_state_action != choice), 0, NA)),
         correct_state_2 = if_else((state == 2 & correct_second_state_action == choice), 1,
                                   if_else((state == 2 & correct_second_state_action != choice), 0, NA)),
         correct_state_3 = if_else((state == 3 & correct_third_state_action == choice), 1,
                                   if_else((state == 3 & correct_third_state_action != choice), 0, NA))) %>%
  mutate(correct = coalesce(correct_state_1, correct_state_2, correct_state_3)) %>%
  # calculate switch for state 1 in test phase
  mutate(switch = if_else((state == 1 & component %in% c("control-test")), abs(correct-1), 
                          if_else((state == 1 & phase %in% c("test")), correct, NA)))

# exclude trials with invalid choice
trial_df <- trial_df %>% 
  mutate(running_index = c(1:nrow(trial_df)))

invalid_trial_df <- trial_df %>%
  filter(valid_choice == FALSE)

for (i in invalid_trial_df$running_index) {
  if (trial_df$state[trial_df$running_index == i] %in% c(2,3,"2Left","2Right","3Left","3Right") & (trial_df$trial[trial_df$running_index == i] %in% trial_df$trial[trial_df$running_index == i-1])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
  }
  if (trial_df$state[trial_df$running_index == i] %in% c(4,5,6) & (trial_df$trial[trial_df$running_index == i] %in% trial_df$trial[trial_df$running_index == i-2])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-2] = FALSE
  }
  if (trial_df$state[trial_df$running_index == i] %in% c(7,8,9) & (trial_df$trial[trial_df$running_index == i] %in% trial_df$trial[trial_df$running_index == i-3])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-2] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-3] = FALSE
  }
  if (trial_df$state[trial_df$running_index == i] == 10 & (trial_df$trial[trial_df$running_index == i] %in% trial_df$trial[trial_df$running_index == i-4])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-2] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-3] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-4] = FALSE
  }
}

# extract rows relevant for rating df (prepared below)
rating_df <- trial_df %>%
  filter(phase == "rating")

# exclude invalid trials and rating trials, compute accumulated trial per participant
trial_df <- trial_df %>%
  filter(valid_choice == TRUE) %>%
  select(! running_index, rating_no, rating_state, rating_RT, rating_value) %>%
  arrange(ID, condition_index) %>%
  group_by(ID) %>%
  mutate(accumulated_states_visited = row_number())

# calculate if correct path taken from state 1
trial_df <- trial_df %>%
  mutate(correct_path = case_when((state == 1 & correct == 1 & lead(correct) == 1) ~ 1,
                                  (state == 1 & correct == 0) ~ 0,
                                  (state == 1 & lead(correct) == 0) ~ 0))

# add drink selection per participant
drink_df <- data_df %>%
  select(prolific_ID, version, component, drink) %>%
  mutate(ID = prolific_ID) %>%
  filter(component == "drink-selection") %>%
  group_by(ID) %>%
  slice_tail(n = 1) %>%
  select(ID, drink)

trial_df <- merge(trial_df, drink_df, by = "ID", all.x = T)

# order columns
trial_df <- trial_df %>%
   select(ID, group, audit_pre, audit_post, version, variation, drink, component, phase, condition, condition_index, environment,
   correct_first_state_action, correct_second_state_action, correct_third_state_action,
   trial, accumulated_states_visited, state, choice, valid_choice, RT, correct_state_1, correct_state_2, correct_state_3, 
   correct, correct_path, switch)

##############################  rating df ##############################  
        
rating_df <- rating_df %>%
  select(ID,
         group,
         version,
         condition,
         phase,
         component,
         variation,
         condition_index,
         environment,
         correct_first_state_action,
         correct_second_state_action,
         correct_third_state_action,
         rating_version,
         rating_no,
         rating_state,
         rating_value,
         rating_RT) %>%
  mutate(rating_value = as.numeric(rating_value),
         state = case_when((rating_state %in% c("1LeftRating", "1RightRating")) ~ 1,
                           (rating_state %in% c("2LeftRating", "2RightRating")) ~ 2,
                           (rating_state %in% c("3LeftRating", "3RightRating")) ~ 3)) %>%
  arrange(ID, component, state) %>%
  # compute difference between better and worse action per state
  # value in each row indicates how much better (positive) or worse (negative) the corresponding optimal option was rated compared to the suboptimal option
  mutate(rating_diff_state1 = case_when((rating_state == "1LeftRating" & correct_first_state_action == "left") ~ (rating_value - lead(rating_value)),
                                        (rating_state == "1RightRating" & correct_first_state_action == "right") ~ (rating_value - lag(rating_value))))


##############################  config-df with info on randomization   ##############################  
component_df <- data_df %>%
  select(prolific_ID,
         back_code,
         group,
         version,
         variation,
         component,
         component_duration,
         state_room_map.1,
         state_room_map.2,
         state_room_map.3,
         state_room_map.4,
         state_room_map.5,
         state_room_map.6,
         state_room_map.7,
         state_room_map.8,
         state_room_map.9,
         state_room_map.10) %>%
  rename(ID = prolific_ID) %>%
  distinct() %>%
  arrange(ID,
          component) %>%
  mutate_at(c('ID', 'component'), as.factor) %>%
  mutate(phase = if_else(component %in% c("control-learning", 
                                          "reward-learning", 
                                          "transition-learning", 
                                          "goal-state-learning",
                                          "policy-learning"), "learning", 
                         if_else(component %in% c("control-relearning",
                                                  "reward-relearning",
                                                  "transition-relearning",
                                                  "goal-state-relearning",
                                                  "policy-relearning"), "relearning", 
                                 if_else(component %in% c("control-test",
                                                          "reward-test",
                                                          "transition-test",
                                                          "goal-state-test",
                                                          "policy-test"), "test", 
                                         if_else(component %in% c("control-rating",
                                                                  "reward-rating",
                                                                  "transition-rating",
                                                                  "goal-state-rating",
                                                                  "policy-rating"), "rating", 
                                                 "other")))),
         condition = if_else(component %in% c("control-learning",
                                              "control-relearning",
                                              "control-test",
                                              "control-rating"), "control", 
                             if_else(component %in% c("reward-learning",
                                                      "reward-relearning",
                                                      "reward-test",
                                                      "reward-rating"), "reward",
                                     if_else(component %in% c("transition-learning",
                                                              "transition-relearning",
                                                              "transition-test",
                                                              "transition-rating"), "transition", 
                                             if_else(component %in% c("goal-state-learning",
                                                                      "goal-state-relearning",
                                                                      "goal-state-test",
                                                                      "goal-state-rating"), "goal-state",
                                                     if_else(component %in% c("policy-learning",
                                                                              "policy-relearning",
                                                                              "policy-test",
                                                                              "policy-rating"), "policy", 
                                                             "other")))))) %>%
  mutate(condition_index = case_when(((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "reward") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "transition") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "policy") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "goal-state") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "control")) ~ 1,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "transition") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "policy") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "goal-state") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "control") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "reward")) ~ 2,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "policy") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "goal-state") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "control") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "reward") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "transition")) ~ 3,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "goal-state") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "control") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "reward") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "transition") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "policy")) ~ 4,
                                     ((variation %in% c("A1", "A2", "A3", "A4", "A5") & condition == "control") |
                                        (variation %in% c("B1", "B2", "B3", "B4", "B5") & condition == "reward") |
                                        (variation %in% c("C1", "C2", "C3", "C4", "C5") & condition == "transition") |
                                        (variation %in% c("D1", "D2", "D3", "D4", "D5") & condition == "policy") |
                                        (variation %in% c("E1", "E2", "E3", "E4", "E5") & condition == "goal-state")) ~ 5)
  ) %>%
  mutate(environment = case_when(((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 2)) ~ "white_modern",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 3)) ~ "blue_floral",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 4)) ~ "messy_green",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 1) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 5)) ~ "orange_tile",
                                 ((version == "control" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 5) |
                                    (version == "control" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 4) |
                                    (version == "control" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 3) |
                                    (version == "control" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 2) |
                                    (version == "control" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 1)) ~ "red_brown",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 2)) ~ "alternative",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 3)) ~ "brauhaus",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 4)) ~ "fancy_green",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 1) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 5)) ~ "hip_purple",
                                 ((version == "alcohol" & variation %in% c("A1", "B1", "C1", "D1", "E1") & condition_index == 5) |
                                    (version == "alcohol" & variation %in% c("A2", "B2", "C2", "D2", "E2") & condition_index == 4) |
                                    (version == "alcohol" & variation %in% c("A3", "B3", "C3", "D3", "E3") & condition_index == 3) |
                                    (version == "alcohol" & variation %in% c("A4", "B4", "C4", "D4", "E4") & condition_index == 2) |
                                    (version == "alcohol" & variation %in% c("A5", "B5", "C5", "D5", "E5") & condition_index == 1)) ~ "sports_bar"))

component_df <- merge(component_df, drink_df, by = "ID", all.x = T)

##############################  save   ##############################  
save(trial_df, rating_df, component_df, file = file.path(data_path, "final_data_complete.RData"))
