##### GET PARTICIPANTS WITH COMPLETE DATA ##########
##### Milena Musial ################################
##### 09 - 2024 ####################################

rm(list = ls(all = TRUE))

##### load packages

packages <- c("dplyr", "tidyr", "lme4", "forcats")
# install.packages(packages)
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

prolific_alc_harmful <- prolific_alc_harmful %>%
  filter(Participant.id != "65b7c91aff83464ab6fc07a7")

# insert IDs for TRR participants that did not participate via Prolific
prolific_alc_harmful <- prolific_alc_harmful %>%
  add_row(Participant.id = "TRRalc001", Status = "APPROVED", version = "alcohol", group = "harmful") %>%
  add_row(Participant.id = "TRRalc002", Status = "APPROVED", version = "alcohol", group = "harmful") %>%
  add_row(Participant.id = "TRRalc003", Status = "APPROVED", version = "alcohol", group = "harmful")

# control version
prolific_con_lowrisk_1 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt1_control_lowrisk.csv"))
prolific_con_lowrisk_1 <- prolific_con_lowrisk_1 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "low-risk")

prolific_con_lowrisk_1a <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt1a_control_lowrisk.csv"))
prolific_con_lowrisk_1a <- prolific_con_lowrisk_1a %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "low-risk")

prolific_con_lowrisk_3 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt3_control_lowrisk.csv"))
prolific_con_lowrisk_3 <- prolific_con_lowrisk_3 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "low-risk")

prolific_con_harmful_2 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt2_control_highrisk.csv"))
prolific_con_harmful_2 <- prolific_con_harmful_2 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "harmful")

prolific_con_harmful_2a <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt2a_control_highrisk.csv"))
prolific_con_harmful_2a <- prolific_con_harmful_2a %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "harmful")

prolific_con_harmful_4 <- read.csv(file.path(data_path, "inclusion_data/Prolific_WeekendCashHunt4_control_highrisk.csv"))
prolific_con_harmful_4 <- prolific_con_harmful_4 %>%
  filter(Status == "APPROVED") %>%
  select(Participant.id, Status) %>%
  mutate(version = "control",
         group = "harmful")

prolific_con_lowrisk <- rbind(prolific_con_lowrisk_1, prolific_con_lowrisk_1a, prolific_con_lowrisk_3)
prolific_con_harmful <- rbind(prolific_con_harmful_2, prolific_con_harmful_2a, prolific_con_harmful_4)

# insert IDs for TRR participants that did not participate via Prolific
prolific_con_harmful <- prolific_con_harmful %>%
  add_row(Participant.id = "TRRcon001", Status = "APPROVED", version = "control", group = "harmful") %>%
  add_row(Participant.id = "TRRcon002", Status = "APPROVED", version = "control", group = "harmful") %>%
  add_row(Participant.id = "TRRcon003", Status = "APPROVED", version = "control", group = "harmful") %>%
  add_row(Participant.id = "TRRcon004", Status = "APPROVED", version = "control", group = "harmful")

# save output
save(prolific_alc_lowrisk, prolific_alc_harmful, prolific_con_lowrisk, prolific_con_harmful, file = file.path(data_path, "RDFs/IDs_complete.RData"))
