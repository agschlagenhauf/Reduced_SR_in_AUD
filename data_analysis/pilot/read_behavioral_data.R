##### READ IN DATA FROM JSON ##
##### Milena Musial ###########
##### 06 - 2024 ###############

rm(list = ls(all = TRUE))

##### Load packages
packages <- c("dplyr", "ggplot2", "rjson", "ndjson", "jsonlite", "tidyr", "lme4")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)

##### define paths
data_path <- "WP3_DATA/PILOT/behavioral_data"

##### read in json data and convert to df
data_raw <- readLines(file.path(data_path, "jatos_results_data_20240603210018.txt"))
data_list <- lapply(data_raw,fromJSON)
data_list_of_df <- lapply(data_list, data.frame, stringsAsFactors = FALSE)
#data_list_of_df <- lapply(data_list_of_df, data.frame, stringsAsFactors = FALSE)
data_df <- bind_rows(data_list_of_df)
data_df <- data_df %>% 
  unnest(c(aggregate_results.trialResults, 
           tutorial_results.trialResults),
         names_sep = "_",
         keep_empty = TRUE)

# # exclude custom components per participant (data collection errors)
# data_df <- data_df %>%
#   filter(!(participant_ID == "5468" & component %in% c("reward-learning", "reward-relearning", "reward-test"))) %>% # not completed anyways, just to be safe
#   filter(!(participant_ID == "2347" & component %in% c("control-learning", "control-relearning", "control-test"))) %>% # control condition stopped after relearning
#   filter(!(participant_ID == "7373" & component %in% c("goal-state-learning", "goal-state-relearning", "goal-state-test"))) %>% # same participant as 8037, only transition /red_brown env) completed under this ID, goal-state (light_blue env) startedB4 variation
#   filter(!(participant_ID == "8037" & component %in% c("goal-state-learning", "goal-state-relearning", "goal-state-test",
#                                                        "transition-learning", "transition-relearning", "transition-test",
#                                                        "control-learning", "control-relearning", "control-test"))) %>% # same participant as 7373, full experiment, take reward (blue_floral env) from here (2 envs seen, transition already performed), C4 variation
#   filter(!(participant_ID == "3237")) # tehcnical issues reported

# OR exclude entire participants (data collection errors)
data_df <- data_df %>%
  filter(!(participant_ID == "5468")) %>% # not completed anyways, just to be safe
  filter(!(participant_ID == "2347")) %>% # control condition stopped after relearning
  filter(!(participant_ID == "7373")) %>% # same participant as 8037, only transition /red_brown env) completed under this ID, goal-state (light_blue env) started, B4 variation
  filter(!(participant_ID == "8037")) %>% # same participant as 7373, full experiment, take reward (blue_floral env) from here (2 envs seen, transition already performed), C4 variation
  filter(!(participant_ID == "3237")) # technical issues reported
         
##### create purpose-specific dfs
# trial-df
trial_df <- data_df %>%
  select(participant_ID,
         component,
         variation,
         correct_first_state_action,
         aggregate_results.trial,
         aggregate_results.trialResults_state,
         aggregate_results.trialResults_valid_choice,
         aggregate_results.trialResults_choice,
         aggregate_results.trialResults_RT
         ) %>%
  rename(ID = participant_ID,
         trial = aggregate_results.trial,
         state = aggregate_results.trialResults_state,
         valid_choice = aggregate_results.trialResults_valid_choice,
         choice = aggregate_results.trialResults_choice,
         RT = aggregate_results.trialResults_RT) %>%
  filter(! component %in% c("intro1", 
                            "intro2", 
                            "intro3", 
                            "tutorial", 
                            "quiz", 
                            "quiz_wrong",
                            "outro",
                            "interlude-1",
                            "interlude-2",
                            "interlude-3")) %>%
  mutate_at(c('ID', 'component'), as.factor) %>%
  mutate(phase = if_else(component %in% c("control-learning", 
                                          "reward-learning", 
                                          "transition-learning", 
                                          "goal-state-learning"), "learning", 
                         if_else(component %in% c("control-relearning",
                                                  "reward-relearning",
                                                  "transition-relearning",
                                                  "goal-state-relearning"), "relearning", 
                                 if_else(component %in% c("control-test",
                                                          "reward-test",
                                                          "transition-test",
                                                          "goal-state-test"), "test", "other"))),
         condition = if_else(component %in% c("control-learning",
                                              "control-relearning",
                                              "control-test"), "control", 
                             if_else(component %in% c("reward-learning",
                                                      "reward-relearning",
                                                      "reward-test"), "reward",
                                     if_else(component %in% c("transition-learning",
                                                              "transition-relearning",
                                                              "transition-test"), "transition", 
                                             if_else(component %in% c("goal-state-learning",
                                                                      "goal-state-relearning",
                                                                      "goal-state-test"), "goal-state", "other"))))) %>%
  mutate(condition_index = case_when(((variation %in% c("A1", "A2", "A3", "A4") & condition == "reward") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "transition") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "goal-state") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "control")) ~ 1,
                                     ((variation %in% c("A1", "A2", "A3", "A4") & condition == "transition") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "goal-state") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "control") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "reward")) ~ 2,
                                     ((variation %in% c("A1", "A2", "A3", "A4") & condition == "goal-state") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "control") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "reward") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "transition")) ~ 3,
                                     ((variation %in% c("A1", "A2", "A3", "A4") & condition == "control") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "reward") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "transition") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "goal-state")) ~ 4)) %>%
  mutate(environment = case_when(((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 1) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 4) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 3) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 2)) ~ "light_blue",
                                 ((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 2) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 1) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 4) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 3)) ~ "blue_floral",
                                 ((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 3) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 2) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 1) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 4)) ~ "orange_tile",
                                 ((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 4) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 3) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 2) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 1)) ~ "red_brown")) %>%
  arrange(ID,
          component,
          trial)

# insert correct test-stage action
for (n in unique(trial_df$ID)) {
  for (condition in c("control", "reward", "transition", "goal-state")) {
    trial_df$correct_first_state_action[trial_df$ID == n & trial_df$component == paste(condition, "-test", sep="")] = 
      trial_df$correct_first_state_action[trial_df$ID == n & trial_df$component == paste(condition, "-relearning", sep="")][1]
  }
}

# calculate correct for every 2-choice state
trial_df <- trial_df %>%
  mutate(correct_second_state_action = if_else(phase == "learning", "left", # always left during learning (leads to either 20 or 30 €)
                                               if_else(phase == "relearning", "right", NA)), # state 2 only occurs in transition revaluation relearning, right always correct, leads to either 20 or 30 €
         correct_third_state_action = if_else(phase == "learning", "right", # always right during learning (leads to either 20 or 30 €)
                                              if_else(phase == "relearning", "left", NA))) %>% # state 3 only occurs in transition revaluation relearning, left always correct, leads to either 20 or 30 €
  mutate(correct_state_1 = if_else((state == 1 & correct_first_state_action == choice), 1,
                                   if_else((state == 1 & correct_first_state_action != choice), 0, NA)),
         correct_state_2 = if_else((state == 2 & correct_second_state_action == choice), 1,
                                   if_else((state == 2 & correct_second_state_action != choice), 0, NA)),
         correct_state_3 = if_else((state == 3 & correct_third_state_action == choice), 1,
                                   if_else((state == 3 & correct_third_state_action != choice), 0, NA))) %>%
  mutate(correct = coalesce(correct_state_1, correct_state_2, correct_state_3)) %>%
  mutate(switch = if_else(component %in% c("control-relearning", "control-test"), abs(correct-1), 
                          if_else(phase %in% c("relearning", "test"), correct, NA)))

# exclude trials with invalid choice
trial_df <- trial_df %>% 
  mutate(running_index = c(1:nrow(trial_df)))

invalid_trial_df <- trial_df %>%
  filter(valid_choice == FALSE)

for (i in invalid_trial_df$running_index) {
  if (trial_df$state[trial_df$running_index == i] %in% c(2,3) & (trial_df$trial[trial_df$running_index == i] == trial_df$trial[trial_df$running_index == i-1])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
  }
  if (trial_df$state[trial_df$running_index == i] %in% c(4,5,6) & (trial_df$trial[trial_df$running_index == i] == trial_df$trial[trial_df$running_index == i-2])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-2] = FALSE
  }
  if (trial_df$state[trial_df$running_index == i] %in% c(7,8,9) & (trial_df$trial[trial_df$running_index == i] == trial_df$trial[trial_df$running_index == i-3])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-2] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-3] = FALSE
  }
  if (trial_df$state[trial_df$running_index == i] == 10 & (trial_df$trial[trial_df$running_index == i] == trial_df$trial[trial_df$running_index == i-4])) {
    trial_df$valid_choice[trial_df$running_index == i-1] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-2] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-3] = FALSE
    trial_df$valid_choice[trial_df$running_index == i-4] = FALSE
  }
}

# compute accumulated trial per participant
trial_df <- trial_df %>%
  filter(valid_choice == TRUE) %>%
  select(! running_index) %>%
  arrange(ID, condition_index) %>%
  group_by(ID) %>%
  mutate(accumulated_states_visited = row_number())
  
# config-df with info on randomization
component_df <- data_df %>%
  select(participant_ID,
         running_ID,
         back_code,
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
  rename(ID = participant_ID) %>%
  distinct() %>%
  arrange(ID,
          component) %>%
  mutate_at(c('ID', 'component'), as.factor) %>%
  mutate(phase = if_else(component %in% c("control-learning", 
                                          "reward-learning", 
                                          "transition-learning", 
                                          "goal-state-learning"), "learning", 
                         if_else(component %in% c("control-relearning",
                                                  "reward-relearning",
                                                  "transition-relearning",
                                                  "goal-state-relearning"), "relearning", 
                                 if_else(component %in% c("control-test",
                                                          "reward-test",
                                                          "transition-test",
                                                          "goal-state-test"), "test", "other"))),
         condition = if_else(component %in% c("control-learning",
                                              "control-relearning",
                                              "control-test"), "control", 
                             if_else(component %in% c("reward-learning",
                                                      "reward-relearning",
                                                      "reward-test"), "reward",
                                     if_else(component %in% c("transition-learning",
                                                              "transition-relearning",
                                                              "transition-test"), "transition", 
                                             if_else(component %in% c("goal-state-learning",
                                                                      "goal-state-relearning",
                                                                      "goal-state-test"), "goal-state", "other"))))) %>%
  mutate(condition_index = case_when(((variation %in% c("A1", "A2", "A3", "A4") & condition == "reward") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "transition") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "goal-state") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "control")) ~ 1,
                                     ((variation %in% c("A1", "A2", "A3", "A4") & condition == "transition") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "goal-state") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "control") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "reward")) ~ 2,
                                     ((variation %in% c("A1", "A2", "A3", "A4") & condition == "goal-state") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "control") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "reward") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "transition")) ~ 3,
                                     ((variation %in% c("A1", "A2", "A3", "A4") & condition == "control") |
                                        (variation %in% c("B1", "B2", "B3", "B4") & condition == "reward") |
                                        (variation %in% c("C1", "C2", "C3", "C4") & condition == "transition") |
                                        (variation %in% c("D1", "D2", "D3", "D4") & condition == "goal-state")) ~ 4)) %>%
  mutate(environment = case_when(((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 1) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 4) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 3) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 2)) ~ "light_blue",
                                 ((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 2) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 1) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 4) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 3)) ~ "blue_floral",
                                 ((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 3) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 2) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 1) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 4)) ~ "orange_tile",
                                 ((variation %in% c("A1", "B1", "C1", "D1") & condition_index == 4) |
                                    (variation %in% c("A2", "B2", "C2", "D2") & condition_index == 3) |
                                    (variation %in% c("A3", "B3", "C3", "D3") & condition_index == 2) |
                                    (variation %in% c("A4", "B4", "C4", "D4") & condition_index == 1)) ~ "red_brown"))

##### save
save(trial_df, component_df, file = file.path(data_path, "pilot_data_complete.RData"))
