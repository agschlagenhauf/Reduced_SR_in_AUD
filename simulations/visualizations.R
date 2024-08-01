## PROCESS 6 VISUALIZE SIMULATION RESULTS ##
## Milena Musial 05-2024 ###################

# Load packages
packages <- c("dplyr", "ggplot2", "readr")
lapply(packages, library, character.only = TRUE)


# read in csv files
full_sr <- read_csv("Reduced_SR_in_AUD/simulations/results/full_sr.csv")
reduced_sr <- read_csv("Reduced_SR_in_AUD/simulations/results/reduced_sr.csv")
model_free <- read_csv("Reduced_SR_in_AUD/simulations/results/model_free.csv")
model_based <- read_csv("Reduced_SR_in_AUD/simulations/results/model_based.csv")

full_sr_control <- full_sr[full_sr$condition=="control",]
full_sr_reward <- full_sr[full_sr$condition=="reward",]
full_sr_transition <- full_sr[full_sr$condition=="transition",]
full_sr_goal <- full_sr[full_sr$condition=="goal",]

full_sr_reward_learning <- full_sr_reward[full_sr_reward$phase == "learning" | full_sr_reward$phase == "learning_test",]


full_sr_reward_sim6 <- full_sr_reward[full_sr_reward$simulation_number==6,]
full_sr_reward_sim6$transition <- 1:nrow(full_sr_reward_sim6)
full_sr_reward_sim6_learning <- full_sr_reward_sim6[full_sr_reward_sim6$phase=="learning",]
full_sr_reward_sim6_relearning <- full_sr_reward_sim6[full_sr_reward_sim6$phase=="relearning",]

ggplot2::ggplot(data=full_sr_reward_sim6_learning, ggplot2::aes(x=transition)) +
  ggplot2::geom_line(ggplot2::aes(y = VS1A1), color = "darkred") +
  ggplot2::geom_line(ggplot2::aes(y = VS1A2), color = "pink") +
  ggplot2::geom_line(ggplot2::aes(y = VS2A1), color = "blue") +
  ggplot2::geom_line(ggplot2::aes(y = VS2A2), color = "green") +
  ggplot2::geom_line(ggplot2::aes(y = VS3A1), color = "orange") +
  ggplot2::geom_line(ggplot2::aes(y = VS3A2), color = "yellow") 

