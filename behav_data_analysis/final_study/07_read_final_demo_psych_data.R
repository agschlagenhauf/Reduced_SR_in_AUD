##### READ IN DATA FROM CSV ###
##### Milena Musial ###########
##### 06 - 2024 ###############

rm(list = ls(all = TRUE))

##### load packages

packages <- c("dplyr", "ggplot2", "tidyr", "gmodels")
#install.packages(packages)
sapply(packages, require, character.only = TRUE)

##### define paths

data_path <- "WP3_DATA/FINAL_STUDY"

##### read IDs with complete data

load(file.path(data_path, "RDFs/IDs_complete.RData"))

##### read raw data files

demo_alc_lowrisk_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_DE_alc_lowrisk.csv"))
demo_alc_harmful_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_DE_alc_highrisk.csv"))
demo_con_lowrisk_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_DE_control_lowrisk.csv"))
demo_con_harmful_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_DE_control_highrisk.csv"))

demo_alc_lowrisk_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_EN_alc_lowrisk.csv"))
demo_alc_harmful_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_EN_alc_highrisk.csv"))
demo_con_lowrisk_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_EN_control_lowrisk.csv"))
demo_con_harmful_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_DEMO_EN_control_highrisk.csv"))

psych_alc_lowrisk_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_DE_alc_lowrisk.csv"))
psych_alc_harmful_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_DE_alc_highrisk.csv"))
psych_con_lowrisk_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_DE_control_lowrisk.csv"))
psych_con_harmful_DE <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_DE_control_highrisk.csv"))

psych_alc_lowrisk_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_EN_alc_lowrisk.csv"))
psych_alc_harmful_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_EN_alc_highrisk.csv"))
psych_con_lowrisk_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_EN_control_lowrisk.csv"))
psych_con_harmful_EN <- read.csv(file.path(data_path, "demo_psych_data/RedCap_PSYCHO_EN_control_highrisk.csv"))

##### filter raw files to include ids with complete data only

# filter and format DE demo dfs

demo_alc_lowrisk_DE$prolific_pid[demo_alc_lowrisk_DE$rnd_id=="8915"] <- "66a79f059cc23eaa09b04cf9" # insert prolific ID for participant for whom it wasn't automatically piped

demo_alc_lowrisk_DE <- demo_alc_lowrisk_DE %>%
  filter(rnd_id != 9196) %>% # first try of same participant, no questionnaires with this rnd_id
  filter(prolific_pid %in% prolific_alc_lowrisk$Participant.id[prolific_alc_lowrisk$sample=="GER"],
         complete.cases(rnd_id)) %>%
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

demo_alc_harmful_DE <- demo_alc_harmful_DE %>%
  mutate(prolific_pid = case_match(rnd_id,
                                   8396 ~ "TRRalc001",
                                   7724 ~ "TRRalc002",
                                   9164 ~ "TRRalc003",
                                   .default = prolific_pid)) %>%
  filter(prolific_pid %in% prolific_alc_harmful$Participant.id,
         complete.cases(rnd_id)) %>%
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

demo_con_lowrisk_DE <- demo_con_lowrisk_DE %>%
  filter(prolific_pid %in% prolific_con_lowrisk$Participant.id,
         complete.cases(rnd_id)) %>%
  filter(! rnd_id %in% c(6987)) %>% # 66befbac1626bbe09ebae758 filled in questionnaires twice due to technical issues with 1 AUDIT score point difference, first dataset excluded
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

demo_con_harmful_DE <- demo_con_harmful_DE %>%
  mutate(prolific_pid = case_match(rnd_id,
                                   7957 ~ "TRRcon001",
                                   7982 ~ "TRRcon002",
                                   6371 ~ "TRRcon003",
                                   3674 ~ "TRRcon004",
                                   .default = prolific_pid)) %>%
  filter(prolific_pid %in% prolific_con_harmful$Participant.id,
         complete.cases(rnd_id)) %>%
  filter(! rnd_id %in% c(2204, 9258)) %>% # 5fda95fd9df7fa2b164bed61 filled in questionnaires 3 times due to techical issues, with 0-1 AUDIT score points difference, first to datasets excluded
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

# filter and format EN demo dfs

demo_alc_lowrisk_EN <- demo_alc_lowrisk_EN %>%
  filter(prolific_pid %in% prolific_alc_lowrisk$Participant.id[prolific_alc_lowrisk$sample=="UK"],
         complete.cases(rnd_id)) %>%
  filter(! rnd_id %in% c(6551, 4257, 1346)) %>% # 672c8eee8120e669315a528e filled in entry questionnaires 3 times identically (exclude 6551, 4257), 5bae3351a91ee200011a4220 did entry questionnaires twice with 1 AUDIT point difference (exclude 1346)
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

demo_alc_harmful_EN <- demo_alc_harmful_EN %>%
  filter(prolific_pid %in% prolific_alc_harmful$Participant.id,
         complete.cases(rnd_id)) %>%
  filter(! rnd_id %in% c(9015)) %>%
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

demo_con_lowrisk_EN <- demo_con_lowrisk_EN %>%
  filter(prolific_pid %in% prolific_con_lowrisk$Participant.id,
         complete.cases(rnd_id)) %>%
  filter(! rnd_id %in% c(2853, 6173)) %>%
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

demo_con_harmful_EN <- demo_con_harmful_EN %>%
  filter(prolific_pid %in% prolific_con_harmful$Participant.id,
         complete.cases(rnd_id)) %>%
  filter(! rnd_id %in% c(9306)) %>% # 5c5089ea9e74e6000163356c filled in entry questionnaires twice due to technical errors with 1 AUDIT point difference
  rename(audit01_pre = b01_wp3_audit01,
         audit02_pre = b01_wp3_audit02,
         audit03_pre = b01_wp3_audit03,
         audit04_pre = b01_wp3_audit04,
         audit05_pre = b01_wp3_audit05,
         audit06_pre = b01_wp3_audit06,
         audit07_pre = b01_wp3_audit07,
         audit08_pre = b01_wp3_audit08,
         audit09_pre = b01_wp3_audit09,
         audit10_pre = b01_wp3_audit10,
         audit_sum_pre = b01_wp3_audit_sum)

# bind DE and EN demo dfs
demo_alc_lowrisk <- rbind(demo_alc_lowrisk_DE, demo_alc_lowrisk_EN)
demo_alc_harmful <- rbind(demo_alc_harmful_DE, demo_alc_harmful_EN)
demo_con_lowrisk <- rbind(demo_con_lowrisk_DE, demo_con_lowrisk_EN)
demo_con_harmful <- rbind(demo_con_harmful_DE, demo_con_harmful_EN)

# filter DE psychometric scores based on demo df ids

psych_alc_lowrisk_DE <- psych_alc_lowrisk_DE %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_alc_lowrisk_DE$rnd_id,
         participant_id %in% demo_alc_lowrisk_DE$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

psych_alc_harmful_DE <- psych_alc_harmful_DE %>%
  mutate(rnd_id = ifelse(rnd_id==6893, 8045, rnd_id)) %>% # wrong rnd_id recorded
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_alc_harmful_DE$rnd_id,
         participant_id %in% demo_alc_harmful_DE$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

psych_con_lowrisk_DE <- psych_con_lowrisk_DE %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_con_lowrisk_DE$rnd_id,
         participant_id %in% demo_con_lowrisk_DE$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

psych_con_harmful_DE <- psych_con_harmful_DE %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_con_harmful_DE$rnd_id,
         participant_id %in% demo_con_harmful_DE$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

# filter EN psychometric scores based on demo df ids

psych_alc_lowrisk_EN <- psych_alc_lowrisk_EN %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_alc_lowrisk_EN$rnd_id,
         participant_id %in% demo_alc_lowrisk_EN$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

psych_alc_harmful_EN <- psych_alc_harmful_EN %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_alc_harmful_EN$rnd_id,
         participant_id %in% demo_alc_harmful_EN$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

psych_con_lowrisk_EN <- psych_con_lowrisk_EN %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_con_lowrisk_EN$rnd_id,
         participant_id %in% demo_con_lowrisk_EN$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

psych_con_harmful_EN <- psych_con_harmful_EN %>%
  mutate(participant_id = as.character(participant_id)) %>%
  filter(rnd_id %in% demo_con_harmful_EN$rnd_id,
         participant_id %in% demo_con_harmful_EN$participant_id,
         complete.cases(rnd_id)) %>%
  rename(audit01_post = b01_wp3_audit01,
         audit02_post = b01_wp3_audit02,
         audit03_post = b01_wp3_audit03,
         audit04_post = b01_wp3_audit04,
         audit05_post = b01_wp3_audit05,
         audit06_post = b01_wp3_audit06,
         audit07_post = b01_wp3_audit07,
         audit08_post = b01_wp3_audit08,
         audit09_post = b01_wp3_audit09,
         audit10_post = b01_wp3_audit10)

# bind DE and EN psychometric dfs
psych_alc_harmful <- rbind(psych_alc_harmful_DE, psych_alc_harmful_EN)
psych_alc_lowrisk <- rbind(psych_alc_lowrisk_DE, psych_alc_lowrisk_EN)
psych_con_harmful <- rbind(psych_con_harmful_DE, psych_con_harmful_EN)
psych_con_lowrisk <- rbind(psych_con_lowrisk_DE, psych_con_lowrisk_EN)

##### merge all dfs by group and version

# rename prolific id in prolific dfs
prolific_alc_harmful <- prolific_alc_harmful %>%
  rename(prolific_pid = Participant.id)
prolific_alc_lowrisk <- prolific_alc_lowrisk %>%
  rename(prolific_pid = Participant.id)
prolific_con_harmful <- prolific_con_harmful %>%
  rename(prolific_pid = Participant.id)
prolific_con_lowrisk <- prolific_con_lowrisk %>%
  rename(prolific_pid = Participant.id)

# merge prolific dfs with demo dfs and psych dfs
demo_psych_alc_harmful <- left_join(prolific_alc_harmful, demo_alc_harmful, by = "prolific_pid")
demo_psych_alc_harmful <- left_join(demo_psych_alc_harmful, psych_alc_harmful, by = c("participant_id", "rnd_id"))

demo_psych_alc_lowrisk <- left_join(prolific_alc_lowrisk, demo_alc_lowrisk, by = "prolific_pid")
demo_psych_alc_lowrisk <- left_join(demo_psych_alc_lowrisk, psych_alc_lowrisk, by = c("participant_id", "rnd_id"))

demo_psych_con_harmful <- left_join(prolific_con_harmful, demo_con_harmful, by = "prolific_pid")
demo_psych_con_harmful <- left_join(demo_psych_con_harmful, psych_con_harmful, by = c("participant_id", "rnd_id"))

demo_psych_con_lowrisk <- left_join(prolific_con_lowrisk, demo_con_lowrisk, by = "prolific_pid")
demo_psych_con_lowrisk <- left_join(demo_psych_con_lowrisk, psych_con_lowrisk, by = c("participant_id", "rnd_id"))

demo_psych_alc <- rbind(demo_psych_alc_harmful, demo_psych_alc_lowrisk)
demo_psych_con <- rbind(demo_psych_con_harmful, demo_psych_con_lowrisk)

rm(list=setdiff(ls(), c("demo_psych_alc", "demo_psych_con", "data_path")))

##### ALC formatting and score calculation

# initial formatting
demo_psych_alc <- demo_psych_alc %>%
  rename(redcap_ID = participant_id,
         prolific_ID = prolific_pid,
         participant_ID = rnd_id,
         running_ID = zufalls_id,
         age = screen_age,
         sex = screen_gender,
         lang_is_native = screen_lang1,
         lang_is_fluent = screen_lang3,
         drinks_alcohol = screen_drinking,
         alc_therapy = screen_alcohol_th,
         aud_group = audgroup,
         drinks_per_day = b01_wp3_qf1_sum,
         drinks_per_weekday = b01_wp3_qf2_sum,
         drinks_per_weekendday = b01_wp3_qf3_sum,
         drinks_last_day = b01_wp3_qf4_sum,
         casa_hindsight = bx_cas_fac1,
         casa_deliberate = bx_cas_fac2,
         casa_intention = bx_cas_fac3,
         casa_perception = bx_cas_fac4,
         casa_control = bx_cas_fac5,
         casa_gf_unaware = bx_cas_gf1,
         casa_gf_nonvolitional = bx_cas_gf2,
         nicotine_lifetime = screen_nicotin,
         nicotine_maxperyear = screen_nicotin2,
         nicotine_past3months = screen_nicotin3,
         cannabis_lifetime = screen_cannabis,
         cannabis_maxperyear = screen_cannabis2,
         cannabis_past3months = screen_cannabis3,
         cannabis_first = screen_cannabis4,
         cannabis_diagnosis = screen_cannabis5,
         drugs_lifetime = screen_otherdrugs,
         drugs_maxperyear = screen_otherdrugs2,
         drugs_past3months = screen_otherdrugs3,
         drugs_diagnosis = screen_otherdrugs4) %>%
  mutate_at(
    vars(one_of("ethnicity", "country_birth", "country_residence",
                "nationality", "native_language", "student", "employment")),
    ~na_if(., "DATA_EXPIRED")) %>%
  mutate(redcap_ID = as.factor(redcap_ID),
         prolific_ID = as.factor(prolific_ID),
         participant_ID = as.factor(participant_ID),
         running_ID = as.factor(running_ID),
         age = as.numeric(age),
         sex = factor(sex, labels = c("female", "male", "other")),
         ethnicity = as.factor(ethnicity),
         country_birth = as.factor(country_birth),
         country_residence = as.factor(country_residence),
         nationality = as.factor(nationality),
         native_language = as.factor(native_language),
         student = as.factor(student),
         employment = as.factor(employment)) 

# calculate audit post and AUDIT mean score
demo_psych_alc <- demo_psych_alc %>%
  rowwise() %>%
  mutate(audit_sum_post = sum(audit01_post, audit02_post, audit03_post, 
                            audit04_post, audit05_post, audit06_post,
                            audit07_post, audit08_post, audit09_post,
                            audit10_post, na.rm = F),
         audit_sum_mean = mean(c(audit_sum_pre, audit_sum_post))) %>%
  ungroup()

# calculate UPPS-P scores (recode only for UK sample)
demo_psych_alc[demo_psych_alc$sample=="UK",] <- demo_psych_alc[demo_psych_alc$sample=="UK",] %>%
  mutate_at(
    vars(one_of("b01_wp3_uppsp_nu1", "b01_wp3_uppsp_nu2", "b01_wp3_uppsp_nu3", "b01_wp3_uppsp_nu4",
                "b01_wp3_uppsp_nu5", "b01_wp3_uppsp_nu6", "b01_wp3_uppsp_nu7", "b01_wp3_uppsp_nu8",
                "b01_wp3_uppsp_nu9", "b01_wp3_uppsp_nu10", "b01_wp3_uppsp_nu12",
                "b01_wp3_uppsp_ps2", "b01_wp3_uppsp_ps10",
                "b01_wp3_uppsp_ss1", "b01_wp3_uppsp_ss2", "b01_wp3_uppsp_ss3", "b01_wp3_uppsp_ss4",
                "b01_wp3_uppsp_ss5", "b01_wp3_uppsp_ss6", "b01_wp3_uppsp_ss7", "b01_wp3_uppsp_ss8",
                "b01_wp3_uppsp_ss9", "b01_wp3_uppsp_ss10", "b01_wp3_uppsp_ss11", "b01_wp3_uppsp_ss12",
                "b01_wp3_uppsp_pu1", "b01_wp3_uppsp_pu2", "b01_wp3_uppsp_pu3", "b01_wp3_uppsp_pu4",
                "b01_wp3_uppsp_pu5", "b01_wp3_uppsp_pu6", "b01_wp3_uppsp_pu7", "b01_wp3_uppsp_pu8",
                "b01_wp3_uppsp_pu9", "b01_wp3_uppsp_pu10", "b01_wp3_uppsp_pu11", "b01_wp3_uppsp_pu12",
                "b01_wp3_uppsp_pu13", "b01_wp3_uppsp_pu14")),
    funs(case_when(
      . == 1 ~ 4,
      . == 2 ~ 3,
      . == 3 ~ 2,
      . == 4 ~ 1
    )))

demo_psych_alc <- demo_psych_alc %>%
  rowwise() %>%
  mutate(
    uppsp_negative_urgency = mean(c_across(starts_with("b01_wp3_uppsp_nu")), na.rm = F),
    uppsp_premeditation = mean(c_across(starts_with("b01_wp3_uppsp_pm")), na.rm = F),
    uppsp_perseverance = mean(c_across(starts_with("b01_wp3_uppsp_ps")), na.rm = F),
    uppsp_sensation_seeking = mean(c_across(starts_with("b01_wp3_uppsp_ss")), na.rm = F),
    uppsp_positive_urgency = mean(c_across(starts_with("b01_wp3_uppsp_ps")), na.rm = F),
    uppsp_total = mean(c_across(starts_with("b01_wp3_uppsp")), na.rm = F)
  ) %>%
  ungroup()

#calculate OCI-R scores
demo_psych_alc <- demo_psych_alc %>%
  rowwise() %>%
  mutate(
    oci_hoarding = sum(c_across(starts_with("b01_wp3_oci_hoard")), na.rm = F),
    oci_checking = sum(c_across(starts_with("b01_wp3_oci_check")), na.rm = F),
    oci_ordering = sum(c_across(starts_with("b01_wp3_oci_order")), na.rm = F),
    oci_neutralising = sum(c_across(starts_with("b01_wp3_oci_neutral")), na.rm = F),
    oci_washing = sum(c_across(starts_with("b01_wp3_oci_wash")), na.rm = F),
    oci_obsessing = sum(c_across(starts_with("b01_wp3_oci_obsess")), na.rm = F),
    oci_total = sum(c_across(starts_with("b01_wp3_oci")), na.rm = F)
  ) %>%
  ungroup()

# calculate DMQ-R-SF scales
demo_psych_alc <- demo_psych_alc %>%
  rowwise() %>%
  mutate(
    dmq_social = sum(dmq_r_s01, dmq_r_s06, dmq_r_s08, na.rm = F),
    dmq_enhancement = sum(dmq_r_s04, dmq_r_s05, dmq_r_s10, na.rm = F),
    dmq_coping = sum(dmq_r_s02, dmq_r_s03, dmq_r_s09, na.rm = F),
    dmq_conformity = sum(dmq_r_s07, dmq_r_s11, dmq_r_s12, na.rm = F),
    dmq_total = sum(dmq_social, dmq_enhancement, dmq_coping, dmq_conformity, na.rm = F),
  ) %>%
  ungroup()

# select and order
demo_psych_alc <- demo_psych_alc %>%
  select(prolific_ID,
         participant_ID,
         running_ID,
         redcap_ID,
         group,
         version,
         sample,
         age,
         sex,
         country_birth,
         country_residence,
         nationality,
         native_language,
         lang_is_native,
         lang_is_fluent,
         ethnicity,
         student,
         employment,
         drinks_alcohol,
         alc_therapy,
         audit_sum_pre,
         audit_sum_post,
         audit_sum_mean,
         aud_sum,
         aud_group,
         drinks_per_day,
         drinks_per_weekday,
         drinks_per_weekendday,
         drinks_last_day,
         nicotine_lifetime,
         nicotine_maxperyear,
         nicotine_past3months,
         cannabis_lifetime,
         cannabis_maxperyear,
         cannabis_past3months,
         cannabis_first,
         cannabis_diagnosis,
         drugs_lifetime,
         drugs_maxperyear,
         drugs_past3months,
         drugs_diagnosis,
         casa_hindsight,
         casa_deliberate,
         casa_intention,
         casa_perception,
         casa_control,
         casa_gf_unaware,
         casa_gf_nonvolitional,
         uppsp_negative_urgency,
         uppsp_premeditation,
         uppsp_perseverance,
         uppsp_sensation_seeking,
         uppsp_positive_urgency,
         uppsp_total,
         oci_hoarding,
         oci_checking,
         oci_ordering,
         oci_neutralising,
         oci_washing,
         oci_obsessing,
         oci_total,
         dmq_social,
         dmq_enhancement,
         dmq_coping,
         dmq_conformity,
         dmq_total)

##### CON formatting and score calculation

# initial formatting
demo_psych_con <- demo_psych_con %>%
  rename(redcap_ID = participant_id,
         prolific_ID = prolific_pid,
         participant_ID = rnd_id,
         running_ID = zufalls_id,
         age = screen_age,
         sex = screen_gender,
         lang_is_native = screen_lang1,
         lang_is_fluent = screen_lang3,
         drinks_alcohol = screen_drinking,
         alc_therapy = screen_alcohol_th,
         aud_group = audgroup,
         drinks_per_day = b01_wp3_qf1_sum,
         drinks_per_weekday = b01_wp3_qf2_sum,
         drinks_per_weekendday = b01_wp3_qf3_sum,
         drinks_last_day = b01_wp3_qf4_sum,
         casa_hindsight = bx_cas_fac1,
         casa_deliberate = bx_cas_fac2,
         casa_intention = bx_cas_fac3,
         casa_perception = bx_cas_fac4,
         casa_control = bx_cas_fac5,
         casa_gf_unaware = bx_cas_gf1,
         casa_gf_nonvolitional = bx_cas_gf2,
         nicotine_lifetime = screen_nicotin,
         nicotine_maxperyear = screen_nicotin2,
         nicotine_past3months = screen_nicotin3,
         cannabis_lifetime = screen_cannabis,
         cannabis_maxperyear = screen_cannabis2,
         cannabis_past3months = screen_cannabis3,
         cannabis_first = screen_cannabis4,
         cannabis_diagnosis = screen_cannabis5,
         drugs_lifetime = screen_otherdrugs,
         drugs_maxperyear = screen_otherdrugs2,
         drugs_past3months = screen_otherdrugs3,
         drugs_diagnosis = screen_otherdrugs4) %>%
  mutate_at(
    vars(one_of("ethnicity", "country_birth", "country_residence",
                "nationality", "native_language", "student", "employment")),
    ~na_if(., "DATA_EXPIRED")) %>%
  mutate(redcap_ID = as.factor(redcap_ID),
         prolific_ID = as.factor(prolific_ID),
         participant_ID = as.factor(participant_ID),
         running_ID = as.factor(running_ID),
         age = as.numeric(age),
         sex = factor(sex, labels = c("female", "male", "other")),
         ethnicity = as.factor(ethnicity),
         country_birth = as.factor(country_birth),
         country_residence = as.factor(country_residence),
         nationality = as.factor(nationality),
         native_language = as.factor(native_language),
         student = as.factor(student),
         employment = as.factor(employment)) 

# calculate audit post score
demo_psych_con <- demo_psych_con %>%
  rowwise() %>%
  mutate(audit_sum_post = sum(audit01_post, audit02_post, audit03_post, 
                              audit04_post, audit05_post, audit06_post,
                              audit07_post, audit08_post, audit09_post,
                              audit10_post, na.rm = F),
         audit_sum_mean = mean(c(audit_sum_pre, audit_sum_post))) %>%
  ungroup()

# calculate UPPS-P scores (recode only for UK sample)
demo_psych_con[demo_psych_con$sample=="UK",] <- demo_psych_con[demo_psych_con$sample=="UK",] %>%
  mutate_at(
    vars(one_of("b01_wp3_uppsp_nu1", "b01_wp3_uppsp_nu2", "b01_wp3_uppsp_nu3", "b01_wp3_uppsp_nu4",
                "b01_wp3_uppsp_nu5", "b01_wp3_uppsp_nu6", "b01_wp3_uppsp_nu7", "b01_wp3_uppsp_nu8",
                "b01_wp3_uppsp_nu9", "b01_wp3_uppsp_nu10", "b01_wp3_uppsp_nu12",
                "b01_wp3_uppsp_ps2", "b01_wp3_uppsp_ps10",
                "b01_wp3_uppsp_ss1", "b01_wp3_uppsp_ss2", "b01_wp3_uppsp_ss3", "b01_wp3_uppsp_ss4",
                "b01_wp3_uppsp_ss5", "b01_wp3_uppsp_ss6", "b01_wp3_uppsp_ss7", "b01_wp3_uppsp_ss8",
                "b01_wp3_uppsp_ss9", "b01_wp3_uppsp_ss10", "b01_wp3_uppsp_ss11", "b01_wp3_uppsp_ss12",
                "b01_wp3_uppsp_pu1", "b01_wp3_uppsp_pu2", "b01_wp3_uppsp_pu3", "b01_wp3_uppsp_pu4",
                "b01_wp3_uppsp_pu5", "b01_wp3_uppsp_pu6", "b01_wp3_uppsp_pu7", "b01_wp3_uppsp_pu8",
                "b01_wp3_uppsp_pu9", "b01_wp3_uppsp_pu10", "b01_wp3_uppsp_pu11", "b01_wp3_uppsp_pu12",
                "b01_wp3_uppsp_pu13", "b01_wp3_uppsp_pu14")),
    funs(case_when(
      . == 1 ~ 4,
      . == 2 ~ 3,
      . == 3 ~ 2,
      . == 4 ~ 1
    ))) 

demo_psych_con <- demo_psych_con %>%
  rowwise() %>%
  mutate(
    uppsp_negative_urgency = mean(c_across(starts_with("b01_wp3_uppsp_nu")), na.rm = F),
    uppsp_premeditation = mean(c_across(starts_with("b01_wp3_uppsp_pm")), na.rm = F),
    uppsp_perseverance = mean(c_across(starts_with("b01_wp3_uppsp_ps")), na.rm = F),
    uppsp_sensation_seeking = mean(c_across(starts_with("b01_wp3_uppsp_ss")), na.rm = F),
    uppsp_positive_urgency = mean(c_across(starts_with("b01_wp3_uppsp_ps")), na.rm = F),
    uppsp_total = mean(c_across(starts_with("b01_wp3_uppsp")), na.rm = F)
  ) %>%
  ungroup()


# calculate OCI-R scores
demo_psych_con <- demo_psych_con %>%
  rowwise() %>%
  mutate(
    oci_hoarding = sum(c_across(starts_with("b01_wp3_oci_hoard")), na.rm = F),
    oci_checking = sum(c_across(starts_with("b01_wp3_oci_check")), na.rm = F),
    oci_ordering = sum(c_across(starts_with("b01_wp3_oci_order")), na.rm = F),
    oci_neutralising = sum(c_across(starts_with("b01_wp3_oci_neutral")), na.rm = F),
    oci_washing = sum(c_across(starts_with("b01_wp3_oci_wash")), na.rm = F),
    oci_obsessing = sum(c_across(starts_with("b01_wp3_oci_obsess")), na.rm = F),
    oci_total = sum(c_across(starts_with("b01_wp3_oci")), na.rm = F)
  ) %>%
  ungroup()

# calculate DMQ-R-SF scales
demo_psych_con <- demo_psych_con %>%
  rowwise() %>%
  mutate(
    dmq_social = sum(dmq_r_s01, dmq_r_s06, dmq_r_s08, na.rm = F),
    dmq_enhancement = sum(dmq_r_s04, dmq_r_s05, dmq_r_s10, na.rm = F),
    dmq_coping = sum(dmq_r_s02, dmq_r_s03, dmq_r_s09, na.rm = F),
    dmq_conformity = sum(dmq_r_s07, dmq_r_s11, dmq_r_s12, na.rm = F),
    dmq_total = sum(dmq_social, dmq_enhancement, dmq_coping, dmq_conformity, na.rm = F),
  ) %>%
  ungroup()

# select and order
demo_psych_con <- demo_psych_con %>%
  select(prolific_ID,
         participant_ID,
         running_ID,
         redcap_ID,
         group,
         version,
         sample,
         age,
         sex,
         country_birth,
         country_residence,
         nationality,
         native_language,
         lang_is_native,
         lang_is_fluent,
         ethnicity,
         student,
         employment,
         drinks_alcohol,
         alc_therapy,
         audit_sum_pre,
         audit_sum_post,
         audit_sum_mean,
         aud_sum,
         aud_group,
         drinks_per_day,
         drinks_per_weekday,
         drinks_per_weekendday,
         drinks_last_day,
         nicotine_lifetime,
         nicotine_maxperyear,
         nicotine_past3months,
         cannabis_lifetime,
         cannabis_maxperyear,
         cannabis_past3months,
         cannabis_first,
         cannabis_diagnosis,
         drugs_lifetime,
         drugs_maxperyear,
         drugs_past3months,
         drugs_diagnosis,
         casa_hindsight,
         casa_deliberate,
         casa_intention,
         casa_perception,
         casa_control,
         casa_gf_unaware,
         casa_gf_nonvolitional,
         uppsp_negative_urgency,
         uppsp_premeditation,
         uppsp_perseverance,
         uppsp_sensation_seeking,
         uppsp_positive_urgency,
         uppsp_total,
         oci_hoarding,
         oci_checking,
         oci_ordering,
         oci_neutralising,
         oci_washing,
         oci_obsessing,
         oci_total,
         dmq_social,
         dmq_enhancement,
         dmq_coping,
         dmq_conformity,
         dmq_total)


##### check that group label matches audit score

if (max(demo_psych_alc$audit_sum_pre[demo_psych_alc$group=="low-risk"])<8) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}
if (min(demo_psych_alc$audit_sum_pre[demo_psych_alc$group=="harmful"])>7) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}

if (max(demo_psych_con$audit_sum_pre[demo_psych_con$group=="low-risk"])<8) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}
if (min(demo_psych_con$audit_sum_pre[demo_psych_con$group=="harmful"])>7) {
  print("Labels match!")
} else {
  print("ATTENTION Labels don't match!")
}

##### bind con and alc dfs
demo_psych <- rbind(demo_psych_alc, demo_psych_con)

##### releveling factors TODO

demo_psych <- demo_psych %>%
  mutate(nicotine_maxperyear = fct_recode(as.factor(nicotine_maxperyear), 
                                         "less than 1x per month" = "0",
                                         "1-3 x per month" = "1",
                                         "1-4 x per week" = "2",
                                         "5-7 x per week" = "3"),
         nicotine_past3months = fct_recode(as.factor(nicotine_past3months),
                                           "never" = "0",
                                           "less than 1x per month" = "1",
                                           "1-3 x per month" = "2",
                                           "1-4 x per week" = "3",
                                           "5-7 x per week" = "4"))

##############################  save   ##############################  
save(demo_psych, file = file.path(data_path, "RDFs/demo_psych_data_w_oldrating.RData"))
