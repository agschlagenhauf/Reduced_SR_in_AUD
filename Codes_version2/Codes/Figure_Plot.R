# Code for plotting and saving the figures
## ------- Preparations ---------
# set working directory
# Please enter the directory where this file is located
ab_path = ""
setwd(ab_path)

# Load fonts
extrafont::loadfonts(device="win")

# Load packages
library(dplyr)
library(tidyverse)
library(ggplot2)
library(lemon)
library(ggpattern)

source("Functions_for_figs.R")

## ------ Figure 1B -------
gamma <- 0.97
fig1B <- fig1B_plot(gamma)
# save
ggsave(file="Figure/Figure1/Figure1B.jpg", plot=fig1B)

## Figure 2: Traditional Punctate RL ----------
# load data
fig2_path <- "Figure/Figure2"
gamma <- 0.97

# Figure 2A: RPEs under Non-Resistant policy -----------
gamma  <- 0.97
data <- read.csv("Punctate/NonR_g97_s0_10states.csv") %>%
  filter(Episode==1 | Episode==5 | Episode==10 | Episode==20 | Episode==30) %>%
  select(Episode, State, RPE, V1)

for (epi_num in c(1, 10, 30)) {
  d <- data %>% filter(Episode==epi_num)
  new_row <- c(epi_num, 0, gamma*d$V1[1], d$V1[1])
  d <- rbind(new_row, d)
  
  p_g <- ggplot(d, aes(x=State, y=RPE)) +
    theme_classic() +
    theme(aspect.ratio=38/70) +
    theme(axis.title.x=element_blank(), axis.title.y=element_blank()) +
    theme(axis.text.x=element_blank(), axis.text.y=element_blank()) +
    geom_hline(yintercept=0, color="gray", linetype="dashed") +
    geom_point(size=3, stroke=1.5) +
    geom_line(size=2) +
    scale_x_continuous(breaks=seq(0,10,1)) +
    scale_y_continuous(breaks=seq(-0.25,1,0.25)) +
    coord_cartesian(ylim=c(-0.25, 1.0)) +
    xlab("") +
    ylab("")
  
  p <- ggplot(d, aes(x=State, y=RPE)) +
    theme_classic() +
    theme(aspect.ratio=5/6) +
    theme(axis.title.x = element_text(size=20, family="Arial", face="bold"),
          axis.title.y = element_text(size=20, family="Arial", face="bold")) + 
    theme(axis.text.x = element_text(size=18, face="bold"),
          axis.text.y = element_text(size=18, face="bold")) +
    geom_hline(yintercept=0, color="gray", linetype="dashed") +
    geom_point(size=3, stroke=1.5) +
    geom_line(size=1) +
    scale_x_continuous(breaks=seq(0,10,1)) +
    scale_y_continuous(breaks=seq(0,1,0.25))+
    coord_cartesian(xlim=c(0,10), ylim=c(0,1)) +
    xlab("State") +
    ylab("Reward Prediction Error")
  
  fn <- sprintf("Figure/Figure2/fig2A_%sepi.jpg", epi_num)
  fn_g <- sprintf("Figure/Figure2/fig2A_%sepi_forgrab.jpg", epi_num)
  ggsave(filename=fn, plot=p, width=6.8, height=4.57)
  ggsave(filename=fn_g, plot=p_g, width=6.8, height=4.57)
  
}


# Figure 2Ba: Example RPE of single episode under Resistant policy ----------
data <- read.csv("Punctate/g97_s75_10states_r1.csv")
p <- fig2Ba_plot(data, gamma)
plot(p)
ggsave("fig2Ba.jpg", plot=p, path=fig2_path)

# Figure 2Bb: Mean RPE of the first episode --------
epi_num <- 1
fig_num <- 2
legend <- 0
p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
ggsave("fig2Bb.jpg", plot=p[[1]], path=fig2_path)

# Figure 2C: Mean RPE of 25th episode ---------
epi_num <- 25
fig_num <- 2
legend <- 0
p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
ggsave("fig2C.jpg", plot=p[[1]], path=fig2_path)

# Figure 2Da: Over-episode change of cue RPE ---------
epi_num <- 200
fig_num <- 2
p <- hEpisode_vcue_plot(data, gamma, epi_num, fig_num)
ggsave("fig2Da.jpg", plot=p, path=fig2_path)

# Figure 2Db: Over-episode change of RPE at the goal and start state --------
epi_num <- 200
fig_num <- 2
legend <- 0
p <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
ggsave("fig2Db.jpg", plot=p[[1]], path=fig2_path)


## Figure 3: RPE of reduced SR -------
# load data
data <- read.csv("Reduced_SR/alphaSR0_g97_s75_10states.csv")
fig3_path <- "Figure/Figure3"
gamma <- 0.97

# Figure 3A: RPE under Non-Resistant policy -------
gamma <- 0.97
w <- 1.0 # weight
state_n <- 10
feat <- c() # feature vector
for (k in 1:state_n){
  feat <- append(feat, gamma^(state_n - k))
}
v <- w*feat # Approximated state values (equal to true state values when w=1)

current_state <- 1
rpe_vec <- c()
while (current_state <= 10) {
  if (current_state == 10) {
    r <- 1
    rpe <- r + 0 - v[current_state]
  }
  else {
    r <- 0
    rpe <- r + gamma*v[current_state+1] - v[current_state]
  }
  
  rpe_vec <- append(rpe_vec, rpe)
  current_state <- current_state + 1
}
rpe_vec <- append(rpe_vec, gamma*v[1], after=0) # add cue value
state <- seq(0,10,1)
d <- data.frame(state, rpe_vec)

# plot
p <- ggplot(d, aes(x=state, y=rpe_vec)) +
  theme_classic() +
  theme(aspect.ratio=5/6) +
  theme(axis.title.x = element_text(size=20, family="Arial", face="bold"),
        axis.title.y = element_text(size=20, family="Arial", face="bold")) + 
  theme(axis.text.x = element_text(size=18, face="bold"),
        axis.text.y = element_text(size=18, face="bold")) +
  geom_hline(yintercept=0, color="gray", linetype="dashed") +
  geom_point(size=2.5, stroke=1.5) +
  geom_line(size=1.3) +
  scale_x_continuous(breaks=seq(0,10,1)) +
  scale_y_continuous(breaks=seq(0,1,0.25))+
  coord_cartesian(xlim=c(0,10), ylim=c(0,1)) +
  xlab("State") +
  ylab("Reward Prediction Error")
  
plot(p)

# save
ggsave("fig3A.jpg", plot=p, path=fig3_path)

# Figure 3Ba: Example RPE of single(first) episode  -------
p <- fig3Ba_plot(data, gamma)
# save
ggsave(file="fig3Ba.jpg", plot=p, path=fig3_path)

# Figure 3Bb: Mean RPE of the first episode -------
epi_num <- 1
fig_num <- 3
p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend=1)
ggsave("hState_vRPE_legend.jpg", plot=p[[2]], path=fig3_path)
p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend=0)
ggsave("fig3Bb.jpg", plot=p[[1]], path=fig3_path)

# Figure 3C: Over-episode the change of coefficient w --------
epi_num <- 100
p <- w_plot(data, epi_num)
# save
ggsave(file="fig3C.jpg", plot=p, path=fig3_path)

# Figure 3D: Mean RPE of the 25th episode -------
epi_num <- 25
fig_num <- 3
legend <- 0
p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
# save
ggsave(file="fig3D.jpg", plot=p[[1]], path=fig3_path)

# Figure 3Ea: Over-episode change of cue RPE ---------
epi_num <- 200
p <- hEpisode_vcue_plot(data, gamma, epi_num, fig_num=3)
ggsave("fig3Ea.jpg", plot=p, path=fig3_path)

# Figure 3Eb: Over-episode change of RPE at start and goal -------
epi_num <- 200
fig_num <- 3

for (legend in c(0,1)){
  p <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
  
  if (legend == 0) {
    # save figure 3Db
    ggsave(file="fig3Eb.jpg", plot=p[[1]], path=fig3_path)
  }
  
  else {
    # save legend
    ggsave(file="hEpisode_vRPE_legend.jpg", plot=p[[2]], path=fig3_path)
  }
}  

## Figure 4: Comparison of cue RPE ---------------
fig4_path <- "Figure/Figure4"
gamma <- 0.97
cue_ex <- function(data, gamma, epi_num) { 
  d <- data %>%
    filter(Episode==epi_num & time_step==1) %>%
    mutate(cue_rpe=gamma*V1) %>%
    select(Simulation, cue_rpe)
}

cue_rpe <- c()
rl_type <- c()
p_vec <- c()

# Non-Resistant
cue_rpe <- append(cue_rpe, c(0.97**10, 0.97**10))
rl_type <- append(rl_type, c("Rigid reduced SR", "Simple RL"))
p_vec <- append(p_vec, c(0, 0))

# Resistant
for (p_stay in c(0.50, 0.75, 0.90)) {
  fn1 <- sprintf("reduced_SR/alphaSR0_g97_s%s_10states.csv", 100*p_stay)
  fn2 <- sprintf("Punctate/g97_s%s_10states_r1.csv", 100*p_stay)
  
  redu <- read.csv(file=fn1) %>% cue_ex(gamma, epi_num=25)
  punc <- read.csv(file=fn2) %>% cue_ex(gamma, epi_num=25)
  
  cue_rpe <- append(cue_rpe, c(redu$cue_rpe, punc$cue_rpe))
  rl_type <- append(rl_type, c(rep("Rigid reduced SR", 100), rep("Simple RL", 100)))
  p_vec <- append(p_vec, rep(p_stay, 200))
}

# with Punishment
puni <- read.csv("Punctate/NonR_punish_g97_s0_11states_r1.0_p2.0.csv") %>%
  cue_ex(gamma, epi_num=25)
cue_rpe <- append(cue_rpe, puni$cue_rpe)
rl_type <- append(rl_type, "Simple RL")
p_vec <- append(p_vec, 0)

# Theoritical value with rigid reduced SR
cue_rpe <- append(cue_rpe, 0.97**10)
rl_type <- append(rl_type, "Theoretical value with rigid reduced SR")
p_vec <- append(p_vec, 0)

cond <- c(rep(3, 2), rep(12, 200), rep(21, 200), rep(30, 200), rep(45, 2))
d <- data.frame(cond=cond,cue_rpe=cue_rpe, rl_type=rl_type, p_stay=p_vec)
d$rl_type <- factor(d$rl_type, levels=c("Simple RL", "Rigid reduced SR", "Theoretical value with rigid reduced SR"))

# plot
p <- ggplot(d, aes(x=cond, y=cue_rpe, group=interaction(cond, rl_type))) +
  geom_hline(yintercept=0, color="gray", linetype="dashed") +
  geom_hline(yintercept=0.97**10, color="gray", linetype="dashed") +
  geom_boxplot(aes(color=rl_type), width=9, size=0.65) +
  theme_classic() +
  theme(legend.title=element_blank()) +
  theme(axis.text.x = element_text(angle=30, hjust=1)) +
  theme(aspect.ratio=5/6) +
  theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
        axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
  theme(axis.text.x = element_text(size=14, face="bold"),
        axis.text.y = element_text(size=14, face="bold")) +
  theme(legend.position="None") +
  scale_x_continuous(breaks=c(3,12,21,30,45), labels=c("Non-Resistant", "P(No-Go) = 0.50", "P(No-Go) = 0.75", 
                                                   "P(No-Go) = 0.90", "Non-Resistant \n with punishment")) +
  scale_y_continuous(breaks=seq(-0.25, 0.75, 0.25)) +
  scale_colour_manual(values=c("black", "red", "magenta")) +
  xlab("") +
  ylab("Predicted value of the cue")

plot(p)

# save
ggsave("fig4A.jpg", plot=p, path=fig4_path)
# save legend
p <- p + 
  theme(legend.position=c(0.5,0.5), legend.text=element_text(size=10))
p_legend <- g_legend(p)
ggsave("cueRPE_legend.jpg", plot=p_legend, path=fig4_path)

## Figure 5: Reduced SR is updated -----------
data <- read.csv("Reduced_SR/alphaSR5_g97_s75_10states.csv")
sr_data <- read.csv("Reduced_SR/SR_alphaSR5_g97_s75_10states.csv")
fig5_path <- "Figure/Figure5"
gamma <- 0.97

# Figure 5A: Scalar feature of each state -----------
epi1 <- 50
epi2 <- 100
epi3 <- 200
for (legend in c(0,1)) {
  fig5A <- fig5A_plot(sr_data, epi1, epi2, epi3, legend)
  
  if (legend == 0) {
    ggsave("fig5A.jpg", plot=fig5A[[1]], path=fig5_path)
  }
  
  else {
    ggsave("fig5A_legend.jpg", plot=fig5A[[2]], path=fig5_path)
  }
}

# Figure 5B: Mean RPEs at 200th episode ---------
epi_num <- 200
fig_num <- 5
legend <- 0

fig5B <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
# save
ggsave("fig5B.jpg", plot=fig5B[[1]], path=fig5_path)

# Figure 5Ca: Over-episode change of cue RPE --------
epi_num <- 200
p <- hEpisode_vcue_plot(data, gamma, epi_num, fig_num=5)
ggsave("fig5Ca.jpg", plot=p, path=fig5_path)

# Figure 5Cb: Over-episode change of RPEs at start and goal --------
p <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
# save
ggsave("fig5Cb.jpg", plot=p[[1]], path=fig5_path)

## Figure 6: Genuine (full) SR ---------
fig6_path <- "Figure/Figure6"
data <- read.csv("Full_SR/100sim_200epi_g97_s75_10states.csv")
gamma <- 0.97

# Figure 6A: Mean RPE at 25th episode --------
epi_num <- 25
fig_num <- 6
legend <- 0
fig6A <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
# save
ggsave("fig6A.jpg", plot=fig6A[[1]], path=fig6_path)

# Figure 6Ba: Over-episode change of cue RPE ---------
epi_num <- 200
p <- hEpisode_vcue_plot(data, gamma, epi_num, fig_num=6)
ggsave("fig6Ba.jpg", plot=p, path=fig6_path)

# Figure 6Bb: OVer-episode change of RPEs at start and goal --------
epi_num <- 200
legend <- 0
fig6B <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
# save
ggsave("fig6Bb.jpg", plot=fig6B[[1]], path=fig6_path)

# Figure 6C: Coefficients at the first and 25th episode ---------
for (epi_num in c(1, 25)) {
  fig <- hState_vCoef_plot(data, epi_num)
  
  if (epi_num == 1) {
    ggsave("fig6Ca.jpg", plot=fig, path=fig6_path)
  }
  
  else {
    ggsave("fig6Cb.jpg", plot=fig, path=fig6_path)
  }
}

# Figure 6D: Over-episode change of coefficients w ----------
epi_num <- 50

for (legend in c(0, 1)) {
  fig6D <- fig6D_plot(data, epi_num, legend)
  
  if (legend == 0) {
    ggsave("fig6D.jpg", plot=fig6D[[1]], path=fig6_path)
  }
  
  else {
    ggsave("Fig6D_legend.jpg", plot=fig6D[[2]], path=fig6_path)
  }
}

## Figure 8: Influence of reduced SR on Q-learning and SARSA -------
# Figure 8a: over-episode changes of Q values ---------
# Figure 8b: Q values at each state ---------
fig8_path <- "Figure/Figure8"
sim_num <- 1
epi1 <- 40
epi2 <- 60
legend <- 0

for (QorS in c(0,1)) {
  for (kappa in c(0.0, 0.2, 0.4)) {
    if (QorS == 0){
      csvname <- sprintf("SR_flow/Q_Qvalues_alphasr0_g97_s75_kappa%s_10states.csv", 100*kappa)
    }
    else {
      csvname <- sprintf("SR_flow/SARSA_Qvalues_alphasr0_g97_s75_kappa%s_10states.csv", 100*kappa)
    }
    
    # read data
    data <- read.csv(csvname)
    
    # Plot
    fig_a <- hEpisode_vQ_plot(data, sim_num, legend)
    fig_b <- hState_vQ_plot(data, epi1, epi2, legend)
    
    # save
    if (QorS == 0){# Q-learning
      fn_a <- sprintf("Figure8Aa_kappa%s.jpg", kappa*100)
      fn_b <- sprintf("Figure8Ab_kappa%s.jpg", kappa*100)
      ggsave(fn_a, plot=fig_a[[1]], path=fig8_path)
      ggsave(fn_b, plot=fig_b[[1]], path=fig8_path)
    }
    
    else {# SARSA
      fn_a <- sprintf("Figure8Ba_kappa%s.jpg", kappa*100)
      fn_b <- sprintf("Figure8Bb_kappa%s.jpg", kappa*100)
      ggsave(fn_a, plot=fig_a[[1]], path=fig8_path)
      ggsave(fn_b, plot=fig_b[[1]], path=fig8_path)
    }
  }
}

# save legend
legend <- 1
for_l1 <- hEpisode_vQ_plot(data, sim_num, legend)
for_l2 <- hState_vQ_plot(data, epi1, epi2, legend)
ggsave("hEpisode_vQ_legend.jpg", plot=for_l1[[2]], path=fig8_path)
ggsave("hState_vQ_legend.jpg", plot=for_l2[[2]], path=fig8_path)

# Figure 8c: Difference of Q(Go) and Q(No-Go) at each state --------
sim_num <- 1
epi1 <- 40
epi2 <- 60
legend <- 0

for (QorS in c(0,1)) {
  if (QorS == 0) {# Q-learning
    kappa0 <- read.csv("SR_flow/Q_Qvalues_alphasr0_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("SR_flow/Q_Qvalues_alphasr0_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("SR_flow/Q_Qvalues_alphasr0_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure8Ac.jpg", plot=figure[[1]], path=fig8_path)
  }
  
  else {# SARSA
    kappa0 <- read.csv("SR_flow/SARSA_Qvalues_alphasr0_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("SR_flow/SARSA_Qvalues_alphasr0_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("SR_flow/SARSA_Qvalues_alphasr0_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure8Bc.jpg", plot=figure[[1]], path=fig8_path)
  }
}

# save legend
legend <- 1
figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
ggsave("hState_vQdif_legend.jpg", plot=figure[[2]], path=fig8_path)

## Figure 9: Influence of punctate state value learning system on Q-learning and SARSA ------
# Figure 9a: over-episode changes of Q values ---------
# Figure 9b: Q values at each state ---------
fig9_path <- "Figure/Figure9"
legend <- 0

for (QorS in c(0,1)) {
  for (kappa in c(0.0, 0.2, 0.4)) {
    if (QorS == 0){
      csvname <- sprintf("Punctate_flow/Q_Qvalues_g97_s75_kappa%s_10states.csv", 100*kappa)
    }
    else {
      csvname <- sprintf("Punctate_flow/SARSA_Qvalues_g97_s75_kappa%s_10states.csv", 100*kappa)
    }
    
    # read data
    data <- read.csv(csvname)
    
    # Plot
    fig_a <- hEpisode_vQ_plot(data, sim_num, legend)
    fig_b <- hState_vQ_plot(data, epi1, epi2, legend)
    
    # save
    if (QorS == 0){# Q-learning
      fn_a <- sprintf("Figure9Aa_kappa%s.jpg", kappa*100)
      fn_b <- sprintf("Figure9Ab_kappa%s.jpg", kappa*100)
      ggsave(fn_a, plot=fig_a[[1]], path=fig9_path)
      ggsave(fn_b, plot=fig_b[[1]], path=fig9_path)
    }
    
    else {# SARSA
      fn_a <- sprintf("Figure9Ba_kappa%s.jpg", kappa*100)
      fn_b <- sprintf("Figure9Bb_kappa%s.jpg", kappa*100)
      ggsave(fn_a, plot=fig_a[[1]], path=fig9_path)
      ggsave(fn_b, plot=fig_b[[1]], path=fig9_path)
    }
  }
}

# Figure 9c: Difference of Q(Go) and Q(No-Go) at each state --------
legend <- 0

for (QorS in c(0,1)) {
  if (QorS == 0) {# Q-learning
    kappa0 <- read.csv("Punctate_flow/Q_Qvalues_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("Punctate_flow/Q_Qvalues_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("Punctate_flow/Q_Qvalues_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure9Ac.jpg", plot=figure[[1]], path=fig9_path)
  }
  
  else {# SARSA
    kappa0 <- read.csv("Punctate_flow/SARSA_Qvalues_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("Punctate_flow/SARSA_Qvalues_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("Punctate_flow/SARSA_Qvalues_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure9Bc.jpg", plot=figure[[1]], path=fig9_path)
  }
}

### Supplemental Figures
## Figure S1: Mean RPEs at 25th episode with various parameters ------
## Figure S2: Over-episode change of cue RPE with various parameters ------
## Figure S3: Over-episode change of RPEs at start and goal with various parameters -------
# Reduced SR -------
figS_path <- "Figure/Supportive_Figures"
legend <- 0

for (gamma in c(0.95, 0.97, 0.99)) {
  for (stay_prob in c(0.50, 0.75, 0.90)) {
    csvname <- sprintf("Reduced_SR/alphaSR0_g%s_s%s_10states.csv", 100*gamma, 100*stay_prob)
    
    data <- read.csv(csvname)
    
    # Figure S1B
    epi_num <- 25
    fig_num <- "S1"
    p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("figS1B_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=p[[1]], path=figS_path)
    
    # Figure S2B
    epi_num <- 50
    p <- hEpisode_vcue_plot(data, gamma, epi_num, fig_num="S2")
    
    # filename
    filename <- sprintf("figS2B_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=p, path=figS_path)
    
    # Figure S3B
    epi_num <- 50
    fig_num <- "S3"
    p <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("figS3B_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=p[[1]], path=figS_path)
    
  }
}

# Punctate RL -------
figS_path <- "Figure/Supportive_Figures"
legend <- 0

for (gamma in c(0.95, 0.97, 0.99)) {
  for (stay_prob in c(0.50, 0.75, 0.90)) {
    csvname <- sprintf("Punctate/g%s_s%s_10states_r1.csv", 100*gamma, 100*stay_prob)
    
    data <- read.csv(csvname)
    
    # Figure S1A
    epi_num <- 25
    fig_num <- "S1"
    p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("figS1A_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=p[[1]], path=figS_path)
    
    # Figure S2A
    epi_num <- 50
    p <- hEpisode_vcue_plot(data, gamma, epi_num, fig_num="S2")
    
    # filename
    filename <- sprintf("figS2A_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=p, path=figS_path)
    
    # Figure S3A
    epi_num <- 50
    fig_num <- "S3"
    p <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("figS3A_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=p[[1]], path=figS_path)
    
  }
}

## Figure S4: Results of reduced SR with learning rate alpha=0.1 ----------
data <- read.csv("Reduced_SR/alpha10_alphaSR0_g97_s75_10states.csv")
figS_path <- "Figure/Supportive_Figures"
gamma <- 0.97

# S4A: Over-episode change of w -------
epi_num <- 200
p <- w_plot(data, epi_num)
ggsave("figS4A.jpg", plot=p, path=figS_path)

# S4B: Mean RPEs of 25th episode --------
epi_num <- 25
fig_num <- "S4"
legend <- 0
p <- hState_vRPE_plot(data, gamma, epi_num, fig_num, legend)
ggsave("figS4B.jpg", plot=p[[1]], path=figS_path)

# S4Ca: Over-episode change of cue RPE -------
epi_num <- 200
p <- hEpisode_vcue_plot(data, gamma, epi_num, fig_num="S4")
ggsave("figS4Ca.jpg", plot=p, path=figS_path)

# S4Cb: Over-episode change of RPEs at start and goal --------
epi_num <- 200
fig_num <- "S4"
p <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
ggsave("figS4Cb.jpg", plot=p[[1]], path=figS_path)
