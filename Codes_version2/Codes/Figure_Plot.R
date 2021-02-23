# Code for plotting and saving the figures

## ------- Preparations ---------
# set working directory
# ↓ Please enter the directory where this file is located
ab_path = ""
setwd(ab_path)

# Load fonts
extrafont::loadfonts(device="win")

# Load packages
library(ggplot2)
library(tidyverse)
library(dplyr)
library(lemon)

source("Functions_for_figs.R")

## ------ Figure 1B -------
gamma <- 0.97
fig1B <- fig1B_plot(gamma)
# save
ggsave(file="Figure1B.jpg", plot=fig1B, path="./Figure/Figure1")

## ------ Figure 2 -------
# load data
setwd("./Reduced_SR")
data <- read.csv("alphaSR0_g97_s75_10states.csv")
fig2_path <- "../Figure/Figure2"

# ------- Figure 2Aa -------
fig2Aa <- fig2Aa_plot(data)
# save
ggsave(file="Figure2Aa.jpg", plot=fig2Aa, path=fig2_path)

# ------- Figure 2Ab -------
epi_num <- 1
fig_num <- 2

for (legend in c(0, 1)) {
  figs <- hState_vRPE_plot(data, epi_num, fig_num, legend)
  figure2Ab <- figs[[1]]
  fig_legend <- figs[[2]]
  
  if (legend == 0) {
    # save figure 2Ab
    ggsave(file="Figure2Ab.jpg", plot=figure2Ab, path=fig2_path)
  }
  
  else {
    # save legend
    ggsave(file="hState_vRPE_legend.jpg", plot=fig_legend, path=fig2_path)
  }
}


# ------ Figure 2B --------
epi_num <- 100
fig2B <- w_plot(data, epi_num)
# save
ggsave(file="Figure2B.jpg", plot=fig2B, path=fig2_path)

# ------ Figure 2C -------
epi_num <- 25
fig_num <- 2
legend <- 0
fig2C <- hState_vRPE_plot(data, epi_num, fig_num, legend)
# save
ggsave(file="Figure2C.jpg", plot=fig2C[[1]], path=fig2_path)

# ------- Figure 2D --------
epi_num <- 200
fig_num <- 2

for (legend in c(0,1)){
  fig2D <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
  
  if (legend == 0) {
    # save figure 2D
    ggsave(file="Figure2D.jpg", plot=fig2D[[1]], path=fig2_path)
  }
  
  else {
    # save legend
    ggsave(file="hEpisode_vRPE_legend.jpg", plot=fig2D[[2]], path=fig2_path)
  }
}  

## ------- Figure 3 -------
fig3_path <- "../Figure/Figure3"
fig_num <- 3
legend <- 0

for (gamma in c(0.95, 0.97, 0.99)) {
  for (stay_prob in c(0.50, 0.75, 0.90)) {
    csvname <- sprintf("alphaSR0_g%s_s%s_10states.csv", 100*gamma, 100*stay_prob)
    
    data <- read.csv(csvname)
    
    # Figure 3A
    epi_num <- 25
    fig3A <- hState_vRPE_plot(data, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("Figure3A_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=fig3A[[1]], path=fig3_path)
    
    # Figure 3B
    epi_num <- 50
    fig3B <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("Figure3B_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=fig3B[[1]], path=fig3_path)
    
  }
}

## ------- Figure 4 -------
data <- read.csv("alpha10_alphaSR0_g97_s75_10states.csv")
fig4_path <- "../Figure/Figure4"
# ------ Figure 4A ------
epi_num <- 200
fig4A <- w_plot(data, epi_num)
ggsave("Figure4A.jpg", plot=fig4A, path=fig4_path)

# ------ Figure 4B -------
epi_num <- 25
fig_num <- 4
legend <- 0
fig4B <- hState_vRPE_plot(data, epi_num, fig_num, legend)
ggsave("Figure4B.jpg", plot=fig4B[[1]], path=fig4_path)

# ------ Figure 4C -------
epi_num <- 200
fig_num <- 4
fig4C <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
ggsave("Figure4C.jpg", plot=fig4C[[1]], path=fig4_path)

## ------- Figure 5 --------
data <- read.csv("alphaSR5_g97_s75_10states.csv")
sr_data <- read.csv("SR_alphaSR5_g97_s75_10states.csv")
fig5_path <- "../Figure/Figure5"
# ------- Figure 5A -------
epi1 <- 50
epi2 <- 100
epi3 <- 200
for (legend in c(0,1)) {
  fig5A <- fig5A_plot(sr_data, epi1, epi2, epi3, legend)
  
  if (legend == 0) {
    ggsave("Figure5A.jpg", plot=fig5A[[1]], path=fig5_path)
  }
  
  else {
    ggsave("Figure5A_legend.jpg", plot=fig5A[[2]], path=fig5_path)
  }
}

# ------- Figure 5B ------
epi_num <- 200
fig_num <- 4
legend <- 0

fig5B <- hState_vRPE_plot(data, epi_num, fig_num, legend)
# save
ggsave("Figure5B.jpg", plot=fig5B[[1]], path=fig5_path)

# ------- Figure 5C ------
fig5C <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
# save
ggsave("Figure5C.jpg", plot=fig5C[[1]], path=fig5_path)

## ------- Figure 6 --------
setwd("../Punctate")
fig6_path <- "../Figure/Figure6"
fig_num <- 6
legend <- 0

for (gamma in c(0.95, 0.97, 0.99)) {
  for (stay_prob in c(0.50, 0.75, 0.90)) {
    csvname <- sprintf("g%s_s%s_10states.csv", 100*gamma, 100*stay_prob)
    
    data <- read.csv(csvname)
    
    # Figure 6A
    epi_num <- 25
    fig6A <- hState_vRPE_plot(data, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("Figure6A_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=fig6A[[1]], path=fig6_path)
    
    # Figure 6B
    epi_num <- 50
    fig6B <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
    
    # filename
    filename <- sprintf("Figure6B_g%s_s%s.jpg", 100*gamma, 100*stay_prob)
    # save
    ggsave(filename=filename, plot=fig6B[[1]], path=fig6_path)
    
  }
}

## -------- Figure 7 --------
setwd("../Full_SR")
fig7_path <- "../Figure/Figure7"
data <- read.csv("100sim_200epi_g97_s75_10states.csv")

# ------ Figure 7A ------
epi_num <- 25
fig_num <- 6
legend <- 0
fig7A <- hState_vRPE_plot(data, epi_num, fig_num, legend)
# save
ggsave("Figure7A.jpg", plot=fig7A[[1]], path=fig7_path)

# ------ Figure 7B ------
epi_num <- 200
fig7B <- hEpisode_vRPE_plot(data, epi_num, fig_num, legend)
# save
ggsave("Figure7B.jpg", plot=fig7B[[1]], path=fig7_path)

# ------- Figure 7C -------
for (epi_num in c(1, 25)) {
  fig <- hState_vCoef_plot(data, epi_num)
  
  if (epi_num == 1) {
    ggsave("Figure7Ca.jpg", plot=fig, path=fig7_path)
  }
  
  else {
    ggsave("Figure7Cb.jpg", plot=fig, path=fig7_path)
  }
}

## ------- Figure 7D -------
epi_num <- 50

for (legend in c(0, 1)) {
  fig7D <- fig7D_plot(data, epi_num, legend)
  
  if (legend == 0) {
    ggsave("Figure7D.jpg", plot=fig7D[[1]], path=fig7_path)
  }
  
  else {
    ggsave("Fig7D_legend.jpg", plot=fig7D[[2]], path=fig7_path)
  }
}

## ------- Figure 9 -------
setwd("../SR_flow")
fig9_path <- "../Figure/Figure9"
sim_num <- 1
epi1 <- 40
epi2 <- 60
legend <- 0

for (QorS in c(0,1)) {
  for (kappa in c(0.0, 0.2, 0.4)) {
    if (QorS == 0){
      csvname <- sprintf("Q_Qvalues_alphasr0_g97_s75_kappa%s_10states.csv", 100*kappa)
    }
    else {
      csvname <- sprintf("SARSA_Qvalues_alphasr0_g97_s75_kappa%s_10states.csv", 100*kappa)
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

# save legend
legend <- 1
for_l1 <- hEpisode_vQ_plot(data, sim_num, legend)
for_l2 <- hState_vQ_plot(data, epi1, epi2, legend)
ggsave("hEpisode_vQ_legend.jpg", plot=for_l1[[2]], path=fig9_path)
ggsave("hState_vQ_legend.jpg", plot=for_l2[[2]], path=fig9_path)


## -------- Figure 10 ---------
setwd("../Punctate_flow")
fig10_path <- "../Figure/Figure10"
legend <- 0

for (QorS in c(0,1)) {
  for (kappa in c(0.0, 0.2, 0.4)) {
    if (QorS == 0){
      csvname <- sprintf("Q_Qvalues_g97_s75_kappa%s_10states.csv", 100*kappa)
    }
    else {
      csvname <- sprintf("SARSA_Qvalues_g97_s75_kappa%s_10states.csv", 100*kappa)
    }
    
    # read data
    data <- read.csv(csvname)
    
    # Plot
    fig_a <- hEpisode_vQ_plot(data, sim_num, legend)
    fig_b <- hState_vQ_plot(data, epi1, epi2, legend)
    
    # save
    if (QorS == 0){# Q-learning
      fn_a <- sprintf("Figure10Aa_kappa%s.jpg", kappa*100)
      fn_b <- sprintf("Figure10Ab_kappa%s.jpg", kappa*100)
      ggsave(fn_a, plot=fig_a[[1]], path=fig10_path)
      ggsave(fn_b, plot=fig_b[[1]], path=fig10_path)
    }
    
    else {# SARSA
      fn_a <- sprintf("Figure10Ba_kappa%s.jpg", kappa*100)
      fn_b <- sprintf("Figure10Bb_kappa%s.jpg", kappa*100)
      ggsave(fn_a, plot=fig_a[[1]], path=fig10_path)
      ggsave(fn_b, plot=fig_b[[1]], path=fig10_path)
    }
  }
}


## ------- Q difference in one figure: Fig.9 --------
setwd("../SR_flow")
fig9_path <- "../Figure/Figure9"
sim_num <- 1
epi1 <- 40
epi2 <- 60
legend <- 0

for (QorS in c(0,1)) {
  if (QorS == 0) {# Q-learning
    kappa0 <- read.csv("Q_Qvalues_alphasr0_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("Q_Qvalues_alphasr0_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("Q_Qvalues_alphasr0_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure9Ac.jpg", plot=figure[[1]], path=fig9_path)
  }
  
  else {# SARSA
    kappa0 <- read.csv("SARSA_Qvalues_alphasr0_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("SARSA_Qvalues_alphasr0_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("SARSA_Qvalues_alphasr0_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure9Bc.jpg", plot=figure[[1]], path=fig9_path)
  }
}

# save legend
legend <- 1
figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
ggsave("hState_vQdif_legend.jpg", plot=figure[[2]], path=fig9_path)

## ------- Q difference in one figure: Fig.10 --------
setwd("../Punctate_flow")
fig10_path <- "../Figure/Figure10"
legend <- 0

for (QorS in c(0,1)) {
  if (QorS == 0) {# Q-learning
    kappa0 <- read.csv("Q_Qvalues_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("Q_Qvalues_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("Q_Qvalues_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure10Ac.jpg", plot=figure[[1]], path=fig10_path)
  }
  
  else {# SARSA
    kappa0 <- read.csv("SARSA_Qvalues_g97_s75_kappa0_10states.csv")
    kappa20 <- read.csv("SARSA_Qvalues_g97_s75_kappa20_10states.csv")
    kappa40 <- read.csv("SARSA_Qvalues_g97_s75_kappa40_10states.csv")
    figure <- hState_vQdif_plot2(kappa0, kappa20, kappa40, epi1, epi2, legend)
    
    # save
    ggsave("Figure10Bc.jpg", plot=figure[[1]], path=fig10_path)
  }
}