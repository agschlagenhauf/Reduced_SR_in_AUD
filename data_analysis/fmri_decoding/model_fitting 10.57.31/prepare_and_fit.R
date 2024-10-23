##### Preparation #####

# import packages
rm(list=ls())
libs<-c("stringr", "dplyr")
#install.packages(libs)
sapply(libs, require, character.only=TRUE)

datapath<-"/Users/milenamusial/Library/CloudStorage/OneDrive-Charité-UniversitätsmedizinBerlin/PhD/04_B01/WP3/WP3_DATA/PILOT_3/behavioral_data"
filepath<-"Reduced_SR_in_AUD/data_analysis/fmri_decoding/model_fitting"

##### Read input #####

load(file.path(datapath, "pilot_data_complete.RData"))
input <- trial_df %>%
  filter(phase %in% c("learning", "relearning")) %>%
  mutate(condition = case_match(condition,
                                "reward" ~ 1,
                                "transition" ~ 2,
                                "policy" ~ 3,
                                "goal-state" ~ 4,
                                "control" ~ 5),
         trial = case_when(phase == "learning" ~ trial,
                                 phase == "relearning" ~ trial + 24),
         state = case_match(state, 
                            c(1, "1LeftTo2Left", "1LeftTo2Right", "1RightTo3Left", "1RightTo3Right") ~ "1",
                            c(2, "2Left", "2Right") ~ "2",
                            c(3, "3Left", "3Right") ~ "3",
                            .default = state),
         choice = case_match(choice,
                             "left" ~ "1",
                             "right" ~ "2",
                             .default = "0"),
         correct = ifelse(is.na(correct), 1, correct)) %>%
  mutate(state = as.numeric(state),
         choice = as.numeric(choice)) %>%
  select(ID, condition, trial, state, choice, correct, reward) 

write.csv(input, file.path(datapath, "data_to_fit.csv"), row.names=F)

