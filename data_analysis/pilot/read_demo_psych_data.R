##### READ IN DATA FROM CSV ###
##### Milena Musial ###########
##### 06 - 2024 ###############

rm(list = ls(all = TRUE))

##### Load packages
packages <- c("dplyr", "ggplot2", "tidyr", "gmodels")
#install.packages(packages)
lapply(packages, library, character.only = TRUE)

##### define paths
demo_data_path <- "WP3_DATA/PILOT/demo_data"
psychometric_data_path <- "WP3_DATA/PILOT/psychometric_data"
behav_data_path <- "WP3_DATA/PILOT/behavioral_data"

##### read files
demo_df <- read.csv(file.path(demo_data_path, "TRR265B01WP3aPilot1C-Demo_DATA_2024-06-06_1019.csv"))
aud_df <- read.csv(file.path(psychometric_data_path, "TRR265B01WP3aPilot1Q-AUDCriteriaDetox_DATA_2024-06-06_1020.csv"))
load(file.path(behav_data_path, "pilot_data_complete.RData"))

#### summarize demographic data

# format demo df
demo_df <- demo_df %>%
  rename(ID = rnd_id,
         age = screen_age,
         sex = screen_gender) %>%
  mutate(ID = as.factor(ID),
         age = as.numeric(age),
         sex = as.factor(sex)) %>%
  select(ID,
         age,
         sex) %>%
  filter(ID %in% unique(trial_df$ID))

# format aud df
aud_df <- aud_df %>%
  rename(ID = rnd_id) %>%
  mutate(ID = as.factor(ID),
         aud_sum = as.factor(aud_sum)) %>%
  select(! c(participant_id,
             controlgroup)) %>%
  filter(ID %in% unique(trial_df$ID))

# merge dfs 
demo_psych_df <- merge.data.frame(demo_df, aud_df, by = "ID")

# descriptive stats
age_df <- demo_psych_df %>%
  summarise(mean_age = mean(age, na.rm = TRUE),
            se_age = sd(age, na.rm = TRUE)/sqrt(n()),
            min = min(age),
            max = max(age),
            ci_l = ci(age, na.rm=TRUE)[2],
            ci_u = ci(age, na.rm=TRUE)[3],
  ) 

# descriptive stats
ggplot(demo_psych_df, aes(x=aud_sum)) +
  geom_bar(fill = "lightblue") +
  theme_minimal()
  
