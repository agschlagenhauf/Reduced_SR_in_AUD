# Functions for data shaping and plotting

## ------ Function for plotting figure 1B -------
fig1B_plot <- function(gamma){
  
  # Initial SR
  state_n <- 10
  sr <- c()
  for (k in 1:state_n){
    sr <- append(sr, gamma^(state_n - k))
  }
  
  State <- seq(1,10,1)
  F1B_dat <- data.frame(State, sr)
  
  fig1B <- ggplot(F1B_dat, aes(x=State, y=sr)) + 
    theme_classic() +
    geom_hline(yintercept = 1.0, color="gray", linetype="dashed") +
    geom_point() +
    geom_line() +
    coord_cartesian(xlim=c(1,10), ylim=c(0.0,1.03)) +
    scale_x_continuous(breaks=seq(1,10,1)) + 
    scale_y_continuous(expand = c(0, 0)) + 
    theme(aspect.ratio=5/6) +
    theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
          axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
    theme(axis.text.x = element_text(size=14, face="bold"),
          axis.text.y = element_text(size=14, face="bold")) +
    theme(legend.position="None") +
    ylab("Scalar Feature")
  
  plot(fig1B)
  
  return(fig1B)
}

## ------ Function for plotting figure 2Aa -------
# Because Figure 2Aa shows the result of a specific single episode, 
# the code for plotting the result may have to be altered depending 
# on the random number used for simulation

fig2Aa_plot <- function(data) {
  
  # extract the first episode of the first simulation
  one_sim <- data %>%
    filter(Simulation == 1 & Episode == 1) %>% 
    group_by(State, Action) %>%
    summarise(mean=mean(RPE), sum=sum(RPE), .groups="drop")
  
  go_dat <- filter(one_sim, Action=="Go")
  stay_dat <- filter(one_sim, Action=="No-Go")
  
  RPE <- c(go_dat$mean, stay_dat$mean, stay_dat$sum)
  State <- c(go_dat$State, stay_dat$State, stay_dat$State)
  Action <- c(rep("Go", 9), "Goal", rep("No Go (Mean)", 6), rep("No Go (Mean) 2", 2), 
              rep("No Go (Sum)", 6), rep("No Go (Sum) 2", 2))
  
  # create a dataframe for Fig 2Aa
  F2Aa_dat <- data.frame(State, Action, RPE)
  
  # prepare a small dataset needed for drawing a line
  jfl <- subset(F2Aa_dat, (State==9 & Action=="Go") | State==10, c(RPE))
  
  # Plot Figure 2Aa
  fig2Aa <- ggplot(F2Aa_dat, aes(x=State, y=RPE, colour=Action)) +
    geom_point(aes(shape=Action, colour=Action), size=3, stroke=1.5) +
    geom_hline(yintercept=0, linetype="dashed", colour="gray") +
    geom_line(aes(linetype=Action, colour=Action)) +
    scale_colour_manual(values=c("blue", "black", "red", "red", "magenta", "magenta")) +
    scale_shape_manual(values=c(4,4,4,4,1,1)) +
    scale_linetype_manual(values=c("solid", "solid", "dashed", "dashed", "dashed", "dashed")) +
    scale_x_continuous(breaks=seq(1,10,1)) + 
    scale_y_continuous(breaks=c(-0.25, 0.0, 0.25, 0.5), expand=c(0,0)) +
    # Draw a line between RPE at state 8 and state 9
    geom_segment(aes(x=9, y=jfl[1,1], xend=10, yend=jfl[2,1]), linetype="solid", colour="black") +
    coord_cartesian(xlim=c(1,10), ylim=c(-0.25, 0.5)) +
    theme_classic() +
    theme(aspect.ratio=5/6) +
    theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
          axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
    theme(axis.text.x = element_text(size=14, face="bold"),
          axis.text.y = element_text(size=14, face="bold")) +
    theme(legend.position="None") +
    ylab("Reward Prediction Error") 
  
  plot(fig2Aa)
  
  return(fig2Aa)
}

## ------ Function for plotting figure 2B & 4A -------
w_plot <- function(data, epi_num){
  
  wdat <- subset(data, State==10 & Episode <= epi_num, c(Simulation, Episode, Weight))
  
  # create dataframe for plotting Figure 2B
  F2B_dat <- wdat %>%
    group_by(Episode) %>%
    summarize(w_mean=mean(Weight), w_sd=sd(Weight), .groups = "drop") %>%
    add_row(Episode = 0, w_mean = 1, w_sd = 0, .before=1) # initial weight
  
  # Plot Figure2B
  fig2B <- ggplot(F2B_dat, aes(x=Episode, y=w_mean)) +
    geom_ribbon(aes(ymin=w_mean-w_sd, ymax=w_mean+w_sd),alpha=0.2) +
    geom_line(size=0.8) +
    theme_classic() +
    theme(aspect.ratio=5/6) +
    theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
          axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
    theme(axis.text.x = element_text(size=14, face="bold"),
          axis.text.y = element_text(size=14, face="bold")) +
    coord_cartesian(ylim=c(0.0, 1.0)) +
    scale_y_continuous(breaks=seq(0.0, 1.0, 0.25), expand=c(0,0)) +
    ylab("Coefficient w")
  
  plot(fig2B)
  
  return(fig2B)
}

## ------ Figures showing mean RPE of each state ------
# Function for data shaping
# horizontal axis = State, vertical axis = RPE (mean and sd)
hState_vRPE_plot <- function(data, epi_num, fig_num, legend) {
  
  # Calculate the mean and SD of RPE of a particular episode
  ex_dat <- filter(data, Episode==epi_num) %>%
    select(Simulation, State, Action, RPE) %>%
    group_by(Simulation, State, Action) %>%
    summarize(rpe_mean=mean(RPE), rpe_sum=sum(RPE), .groups = "drop") %>%
    group_by(State, Action) %>%
    summarize(mean_mean=mean(rpe_mean), mean_sd=sd(rpe_mean),
              sum_mean=mean(rpe_sum), sum_sd=sd(rpe_sum), .groups = "drop")
  
  # Create dataframe for plotting
  stay_dat <- ex_dat %>% filter(Action=="No-Go") %>% select(State, sum_mean, sum_sd)
  RPE_mean <- c(ex_dat$mean_mean, stay_dat$sum_mean)
  RPE_sd <- c(ex_dat$mean_sd, stay_dat$sum_sd)
  State <- c(ex_dat$State, stay_dat$State)
  Action <- c(rep(c("Go", "No Go (mean)"), 9), "Goal", rep("No Go (sum)", 9))
  
  fig_dat <- data.frame(State, Action, RPE_mean, RPE_sd)
  
  # prepare a small dataset needed for drawing a line
  jfl <- subset(fig_dat, (State==9 & Action=="Go") | State==10, c(RPE_mean))
  
  # Figures 2, 4, 7
  if (fig_num != 3 & fig_num != 6) {
    if (legend == 1) { # with legend
      figure <- ggplot(fig_dat, aes(x=State, y=RPE_mean, colour=Action)) +
        geom_hline(yintercept=0, linetype="dashed", colour="gray") +
        geom_point(aes(shape=Action, colour=Action), size=3, stroke=1.5) +
        geom_line(aes(linetype=Action)) +
        geom_errorbar(aes(ymax = RPE_mean+RPE_sd, ymin = RPE_mean-RPE_sd), width=0.2) +
        # Draw a line between RPE at state 8 and state 9
        geom_segment(aes(x=9, y=jfl[1,1], xend=10, yend=jfl[2,1]), 
                     linetype="solid", colour="black") +
        scale_colour_manual(values=c("blue", "black", "red", "magenta")) +
        scale_shape_manual(values=c(4,4,4,1)) +
        scale_linetype_manual(values=c("solid", "solid", "dashed", "dashed")) +
        scale_x_continuous(breaks=seq(1,10,1)) + 
        scale_y_continuous(breaks=c(-0.25, 0.0, 0.25, 0.5), expand=c(0,0)) +
        coord_cartesian(xlim=c(1,10), ylim=c(-0.25, 0.5)) +
        theme_classic() +
        theme(aspect.ratio=5/6) +
        theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
              axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
        theme(axis.text.x = element_text(size=14, face="bold"),
              axis.text.y = element_text(size=14, face="bold")) +
        theme(legend.position=c(0.3, 0.8)) +
        theme(legend.title=element_blank()) +
        theme(legend.text=element_text(size=10, face="bold")) + 
        ylab("Reward Prediction Error") 
      
      plot(figure)
      
      # extract legend
      fig_legend <- g_legend(figure)
    }
    
    else {
      figure <- ggplot(fig_dat, aes(x=State, y=RPE_mean, colour=Action)) +
        geom_hline(yintercept=0, linetype="dashed", colour="gray") +
        geom_point(aes(shape=Action, colour=Action), size=3, stroke=1.5) +
        geom_line(aes(linetype=Action)) +
        geom_errorbar(aes(ymax = RPE_mean+RPE_sd, ymin = RPE_mean-RPE_sd), width=0.2) +
        # Draw a line between RPE at state 8 and state 9
        geom_segment(aes(x=9, y=jfl[1,1], xend=10, yend=jfl[2,1]), 
                     linetype="solid", colour="black") +
        scale_colour_manual(values=c("blue", "black", "red", "magenta")) +
        scale_shape_manual(values=c(4,4,4,1)) +
        scale_linetype_manual(values=c("solid", "solid", "dashed", "dashed")) +
        scale_x_continuous(breaks=seq(1,10,1)) + 
        scale_y_continuous(breaks=c(-0.25, 0.0, 0.25, 0.5), expand=c(0,0)) +
        coord_cartesian(xlim=c(1,10), ylim=c(-0.25, 0.5)) +
        theme_classic() +
        theme(aspect.ratio=5/6) +
        theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
              axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
        theme(axis.text.x = element_text(size=14, face="bold"),
              axis.text.y = element_text(size=14, face="bold")) +
        theme(legend.position="None") + 
        ylab("Reward Prediction Error")
      
      plot(figure)
      fig_legend <- "None"
    }
  }
  
  # Figures 3, 6
  else {
    figure <- ggplot(fig_dat, aes(x=State, y=RPE_mean, colour=Action)) +
      geom_point(aes(shape=Action, colour=Action), size=3, stroke=1.5) +
      geom_hline(yintercept=0, linetype="dashed", colour="gray") +
      geom_line(aes(linetype=Action)) +
      geom_errorbar(aes(ymax = RPE_mean+RPE_sd, ymin = RPE_mean-RPE_sd), width=0.2) +
      # Draw a line between RPE at state 8 and state 9
      geom_segment(aes(x=9, y=jfl[1,1], xend=10, yend=jfl[2,1]), linetype="solid", colour="black") +
      scale_colour_manual(values=c("blue", "black", "red", "magenta")) +
      scale_shape_manual(values=c(4,4,4,1)) +
      scale_x_continuous(breaks=seq(1,10,1), labels=c("1", "", "", "", "", "", "", "", "", "10")) + 
      scale_y_continuous(breaks=seq(-0.8, 1.0, 0.2), 
                         labels=c("-0.8", "" , "", "", "0.0", "", "", "", "", "1.0"),
                         expand = c(0.0,0.0)) +
      coord_cartesian(xlim=c(1,10), ylim=c(-0.8,1.0)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.position="None") +
      ylab("Reward Prediction Error") 
    
    plot(figure)
    fig_legend <- "None"
  }
  
  return(list(figure, fig_legend))
}

## --------- Figures showing the change in RPE between episodes ---------
# Function for data shaping
# horizontal axis = Episode, vertical axis = RPE
hEpisode_vRPE_plot <- function(data, epi_num, fig_num, legend){
  
  # extract data of State 1 & 10 (Start & Goal)
  ex_dat <- data %>% filter(Episode <= epi_num) %>%
    filter(State==1|State==10) %>%
    group_by(Simulation, Episode, State, Action) %>%
    summarize(mean_rpe = mean(RPE), sum_rpe = sum(RPE), .groups = "drop") %>%
    group_by(Episode, State, Action) %>%
    summarize(mean_mean=mean(mean_rpe), sum_mean=mean(sum_rpe), 
              mean_sd=sd(mean_rpe), sum_sd=sd(sum_rpe), .groups = "drop")
  
  # create dataframe for plotting
  stay_dat <- ex_dat %>% filter(Action=="No-Go") %>% 
    select(Episode, State, sum_mean, sum_sd)
  
  RPE_mean <- c(ex_dat$mean_mean, stay_dat$sum_mean)
  RPE_sd <- c(ex_dat$mean_sd, stay_dat$sum_sd)
  State <- c(ex_dat$State, stay_dat$State)
  Episode <- c(ex_dat$Episode, stay_dat$Episode)
  Action <- c(rep(c("Go", "No Go (mean)", "Goal"), epi_num), 
              rep("No Go (sum)", epi_num))
  
  fig_dat <- data.frame(Episode, State, Action, RPE_mean, RPE_sd)
  
  # labels necessary for legends
  labels <- c(expression(bold(paste({S[1]}, " : Go"))), 
              expression(bold(paste({S[10]}, " : Goal"))), 
              expression(bold(paste({S[1]}, " : No Go (Mean)"))), 
              expression(bold(paste({S[1]}, " : No Go (Sum)"))))
  
  # Figure 2, 4, 7
  if (fig_num != 3 & fig_num != 6) {
    if (legend == 1) { # with legend
      figure <- ggplot(fig_dat, aes(x=Episode, y=RPE_mean, group=interaction(State, Action))) +
        geom_hline(yintercept=0, linetype="dashed", colour="gray") +
        geom_line(aes(colour=interaction(State, Action), 
                      linetype=interaction(State, Action)), size=0.70) +
        geom_ribbon(aes(ymin=RPE_mean-RPE_sd, ymax=RPE_mean+RPE_sd, 
                        fill=interaction(State, Action)), alpha=0.2) +
        scale_colour_manual(values=c("blue", "black", "red", "magenta"), labels=labels) +
        scale_linetype_manual(values=c("solid", "solid", "solid", "solid"), labels=labels) +
        scale_fill_manual(values=c("blue", "black", "red", "magenta"), labels=labels) +
        scale_y_continuous(breaks=c(-0.25, 0.0, 0.25, 0.5), expand=c(0,0)) + 
        coord_cartesian(xlim=c(0,200), ylim=c(-0.25, 0.50)) + 
        theme_classic() +
        theme(aspect.ratio=5/6) +
        theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
              axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
        theme(axis.text.x = element_text(size=14, face="bold"),
              axis.text.y = element_text(size=14, face="bold")) +
        theme(legend.title=element_blank()) +
        theme(legend.text = element_text(size=10, family="Arial")) +
        theme(legend.text.align = 0) +
        theme(legend.position=c(0.3,0.55)) + 
        ylab("Reward Prediction Error")
      
      plot(figure)
      
      # extract legend
      fig_legend <- g_legend(figure)
    }
    
    else { # without legend
      figure <- ggplot(fig_dat, aes(x=Episode, y=RPE_mean, group=interaction(State, Action))) +
        geom_hline(yintercept=0, linetype="dashed", colour="gray") +
        geom_line(aes(colour=interaction(State, Action), 
                      linetype=interaction(State, Action)), size=0.70) +
        geom_ribbon(aes(ymin=RPE_mean-RPE_sd, ymax=RPE_mean+RPE_sd, 
                        fill=interaction(State, Action)), alpha=0.2) +
        scale_colour_manual(values=c("blue", "black", "red", "magenta"), labels=labels) +
        scale_linetype_manual(values=c("solid", "solid", "solid", "solid"), labels=labels) +
        scale_fill_manual(values=c("blue", "black", "red", "magenta"), labels=labels) +
        scale_y_continuous(breaks=c(-0.25, 0.0, 0.25, 0.5), expand=c(0,0)) + 
        coord_cartesian(xlim=c(0,200), ylim=c(-0.25, 0.50)) + 
        theme_classic() +
        theme(aspect.ratio=5/6) +
        theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
              axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
        theme(axis.text.x = element_text(size=14, face="bold"),
              axis.text.y = element_text(size=14, face="bold")) +
        theme(legend.title=element_blank()) +
        theme(legend.text = element_text(size=10, family="Arial")) +
        theme(legend.text.align = 0) +
        theme(legend.position="None") +
        ylab("Reward Prediction Error")
      
      plot(figure)

      fig_legend <- "None"
    }
  }
  
  # Figure 3, 6
  else {
    figure <- ggplot(fig_dat, aes(x=Episode, y=RPE_mean, group=interaction(State, Action))) +
      geom_hline(yintercept=0, linetype="dashed", colour="gray") +
      geom_line(aes(colour=interaction(State, Action), 
                    linetype=interaction(State, Action)), size=0.70) +
      geom_ribbon(aes(ymin=RPE_mean-RPE_sd, ymax=RPE_mean+RPE_sd, 
                      fill=interaction(State, Action)), alpha=0.2) +
      scale_colour_manual(values=c("blue", "black", "red", "magenta")) +
      scale_linetype_manual(values=c("solid", "solid", "solid", "solid")) +
      scale_fill_manual(values=c("blue", "black", "red", "magenta")) +
      coord_cartesian(ylim=c(-0.8,1.0)) + 
      scale_y_continuous(breaks=seq(-0.8, 1.0, 0.2),
                         labels=c("-0.8", "" , "", "", "0.0", "", "", "", "", "1.0"),
                         expand = c(0.0,0.0)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.position="None") +
      ylab("Reward Prediction Error")
    
    plot(figure)
    
    fig_legend <- "None"
  }
  
  return(list(figure, fig_legend))
}

## -------- Function for plotting Figure 5A ---------
fig5A_plot <- function(data, epi1, epi2, epi3, legend) {
  
  # Prepare data
  # Initial SR
  gamma <- 0.97
  state_n <- 10
  sr0 <- c()
  for (k in 1:state_n){
    sr0 <- append(sr0, gamma^(state_n - k))
  }
  
  # create dataframe for Fig5A
  F5A_dat <- data %>%
    filter(Episode==epi1 | Episode==epi2 | Episode==epi3) %>%
    group_by(Episode, State) %>%
    summarize(sr_m = mean(SR), sr_sd = sd(SR), .groups = "drop") %>%
    ungroup() %>%
    add_row(Episode = rep(0,10), State = seq(1,10,1), 
            sr_m = sr0, sr_sd = rep(0,10), .before=1) 
  
  F5A_dat$Episode <- as.factor(F5A_dat$Episode)
  
  # Plot Figure 5A
  if (legend == 1) { # with legend
    fig5A <- ggplot(F5A_dat, aes(x=State, y=sr_m, colour=Episode)) +
      geom_errorbar(aes(ymax = sr_m+sr_sd, ymin = sr_m-sr_sd), width=0.2) +
      geom_point(aes(shape=Episode, colour=Episode), size=1.8, stroke=1.0) +
      geom_line(aes(linetype=Episode, colour=Episode)) +
      scale_colour_manual(values=c("gray", "black", "black", "black")) +
      scale_linetype_manual(values=c("solid", "dotted", "dashed", "solid")) +
      scale_shape_manual(values = c(15, 16, 4, 17)) + 
      scale_x_continuous(breaks=seq(1,10,1)) + 
      scale_y_continuous(expand=c(0,0)) +
      coord_cartesian(xlim=c(1,10), ylim=c(0.0,1.03)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
            axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=14, face="bold"),
            axis.text.y = element_text(size=14, face="bold")) +
      theme(legend.title = element_text(size=10, family="Arial", face="bold"), 
            legend.text = element_text(size=10, family="Arial", face="bold")) +
      theme(legend.background = element_rect(fill = "white", colour = "black")) +
      ylab("Scalar Feature")
    
    
    plot(fig5A)
    
    # save the legend
    fig5A_legend <- g_legend(fig5A)
  }
  
  else { # without legend
    fig5A <- ggplot(F5A_dat, aes(x=State, y=sr_m, colour=Episode)) +
      geom_errorbar(aes(ymax = sr_m+sr_sd, ymin = sr_m-sr_sd), width=0.2) +
      geom_point(aes(shape=Episode, colour=Episode), size=1.8, stroke=1.0) +
      geom_line(aes(linetype=Episode, colour=Episode)) +
      scale_colour_manual(values=c("gray", "black", "black", "black")) +
      scale_linetype_manual(values=c("solid", "dotted", "dashed", "solid")) +
      scale_shape_manual(values = c(15, 16, 4, 17)) + 
      scale_x_continuous(breaks=seq(1,10,1)) + 
      scale_y_continuous(expand=c(0,0)) +
      coord_cartesian(xlim=c(1,10), ylim=c(0.0,1.03)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
            axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=14, face="bold"),
            axis.text.y = element_text(size=14, face="bold")) +
      theme(legend.position="None") + 
      ylab("Scalar Feature")
    
    
    plot(fig5A)
    
    fig5A_legend <- "None"
  }
  
  return(list(fig5A, fig5A_legend))
}

## -------- Function for plotting Figure 7Ca and 7Cb ---------
hState_vCoef_plot <- function(data, epi_num) {
  
  w_dat <- data %>%
    filter(Episode == epi_num & State == 9) %>%
    select(-X, -Episode, -State, -Action, -RPE) %>%
    summarize_at(vars(W1:W10), list(mean=mean, sd=sd))
  
  # create dataframe
  w_mean <- as.numeric(w_dat[1,1:10])
  w_sd <- as.numeric(w_dat[1,11:20])
  w_index <- seq(1,10,1)
  coef_dat <- data.frame(w_index, w_mean, w_sd)
  
  # Plot Figure
  figure <- ggplot(coef_dat, aes(x=w_index, y=w_mean)) +
    geom_hline(yintercept=0, linetype="dashed", colour="gray") +
    geom_hline(yintercept=1.0, linetype="dashed", colour="gray") +
    geom_errorbar(aes(ymax=w_mean+w_sd, ymin=w_mean-w_sd), width=0.2) +
    geom_point(size=2, stroke=1.0, shape=1) +
    geom_line() +
    coord_cartesian(xlim=c(1,10)) +
    scale_x_continuous(breaks=seq(1,10,1)) + 
    theme_classic() +
    theme(aspect.ratio=5/6) +
    theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
          axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
    theme(axis.text.x = element_text(size=14, face="bold"),
          axis.text.y = element_text(size=14, face="bold")) +
    theme(legend.position="None") +
    labs(x="State", y=expression(bold(paste("Coefficient  ", {w[j]}))))
  
  plot(figure)
  
  return(figure)
}

## ------- Function for plotting Figure 7D --------
fig7D_plot <- function(data, epi_num, legend) {

  # create dataframe
  w_dat <- data %>%
    filter(Episode <= epi_num & State == 10) %>%
    group_by(Episode) %>%
    summarize(w1_m=mean(W1), w9_m=mean(W9), w10_m=mean(W10), w1_sd=sd(W1), w9_sd=sd(W9), 
              w10_sd=sd(W10), .groups = "drop")
  
  w_mean <- c(w_dat$w1_m, w_dat$w9_m, w_dat$w10_m)
  w_sd <- c(w_dat$w1_sd, w_dat$w9_sd, w_dat$w10_sd)
  Episode <- rep(seq(1,epi_num,1), 3)
  w_index <- c(rep(1, epi_num), rep(9, epi_num), rep(10, epi_num))
  
  F7D_dat <- data.frame(Episode, w_index, w_mean, w_sd)
  F7D_dat$w_index <- as.factor(F7D_dat$w_index)
  
  # prepare labels
  labels <- c(expression(bold(paste(w[1]))), expression(bold(paste(w[9]))), expression(bold(paste(w[10]))))
  
  if (legend == 1) {# with legend
    # plot Figure 7D
    fig7D <- ggplot(F7D_dat, aes(x=Episode, y=w_mean, group=w_index)) +
      geom_hline(yintercept = 0, color="gray", linetype="dashed") +
      geom_hline(yintercept = 1.0, color="gray", linetype="dashed") +
      geom_line(aes(color=w_index, linetype=w_index), size=0.70) +
      geom_ribbon(aes(ymin=w_mean - w_sd, ymax=w_mean + w_sd, fill=w_index), alpha=0.2) +
      scale_color_manual(values=c("red", "blue", "black"), labels=labels) +
      scale_linetype_manual(values=c("solid", "solid", "solid"), labels=labels) + 
      scale_fill_manual(values=c("red", "blue", "black"), labels=labels) + 
      theme_classic(base_family = "Arial") +
      theme(aspect.ratio = 5/6) +
      theme(axis.text.x = element_text(size=14, face="bold"),
            axis.text.y = element_text(size=14, face="bold")) +
      theme(axis.title.x = element_text(size=15, face="bold"),
            axis.title.y = element_text(size=15, face="bold")) +
      theme(legend.title=element_blank()) +
      theme(legend.text = element_text(size=10, family="Arial")) +
      theme(legend.text.align = 0) +
      labs(x="Episode", y=expression(bold(paste("Coefficient  ", {w[j]}))))
    
    
    plot(fig7D)
    
    # save legend
    fig7D_legend <- g_legend(fig7D)
  }
  
  else {# without legend
    # plot Figure 7D
    fig7D <- ggplot(F7D_dat, aes(x=Episode, y=w_mean, group=w_index)) +
      geom_hline(yintercept = 0, color="gray", linetype="dashed") +
      geom_hline(yintercept = 1.0, color="gray", linetype="dashed") +
      geom_line(aes(color=w_index, linetype=w_index), size=0.70) +
      geom_ribbon(aes(ymin=w_mean - w_sd, ymax=w_mean + w_sd, fill=w_index), alpha=0.2) +
      scale_color_manual(values=c("red", "blue", "black"), labels=labels) +
      scale_linetype_manual(values=c("solid", "solid", "solid"), labels=labels) + 
      scale_fill_manual(values=c("red", "blue", "black"), labels=labels) + 
      theme_classic(base_family = "Arial") +
      theme(aspect.ratio = 5/6) +
      theme(axis.text.x = element_text(size=14, face="bold"),
            axis.text.y = element_text(size=14, face="bold")) +
      theme(axis.title.x = element_text(size=15, face="bold"),
            axis.title.y = element_text(size=15, face="bold")) +
      theme(legend.position = "None") + 
      labs(x="Episode", y=expression(bold(paste("Coefficient  ", {w[j]}))))
    
    plot(fig7D)

    fig7D_legend <- "None"
  }
  
  return(list(fig7D, fig7D_legend))
}

## ------- Figures showing the change in Q values across episodes ------
# horizontal axis = Episode, vertical axis = Q values
hEpisode_vQ_plot <- function(data, sim_num, legend) {
  
  # ptate = frepare dataframe
  qdat <- data %>%
    filter(Simulation == sim_num) %>%
    filter(State == 1 | State == 5 | State == 9) %>%
    select(-X, -Simulation) %>%
    pivot_longer(cols=Q_go:Q_stay, names_to="Action", 
                 values_to="Q_value") %>%
    mutate(S_A = interaction(State, Action)) %>%
    mutate(S_A = factor(S_A, levels=c("9.Q_go", "9.Q_stay", "5.Q_go", "5.Q_stay",
                                      "1.Q_go", "1.Q_stay")))
  
  # labels necessary for legends
  labels <- c(expression(bold(paste({S[9]}, " : Go"))), 
              expression(bold(paste({S[9]}, " : No-Go"))),
              expression(bold(paste({S[5]}, " : Go"))),
              expression(bold(paste({S[5]}, " : No-Go"))), 
              expression(bold(paste({S[1]}, " : Go"))),
              expression(bold(paste({S[1]}, " : No-Go"))))
  
  # Plot
  if (legend == 1) {# if legend is needed
    figure <- ggplot(qdat, aes(x=Episode, y=Q_value, group=S_A)) +
      geom_line(aes(colour=S_A, linetype=S_A), size=1.0) +
      scale_colour_manual(values=c("blue", "red", "turquoise", "magenta", 
                                   "lightskyblue", "tomato"), labels=labels) +
      scale_linetype_manual(values=rep("solid", 6), labels=labels) +
      scale_y_continuous(breaks=seq(0.0, 1.6, 0.4), expand=c(0,0)) +
      coord_cartesian(ylim=c(0.0, 1.6)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.title=element_blank()) +
      theme(legend.text = element_text(size=10, family="Arial")) +
      theme(legend.title=element_blank()) +
      theme(legend.text.align = 0) +
      ylab("Q values")
    
    plot(figure)
    
    # save the legend
    fig_legend <- g_legend(figure)
  }
  
  else {
    figure <- ggplot(qdat, aes(x=Episode, y=Q_value, group=S_A)) +
      geom_line(aes(colour=S_A, linetype=S_A), size=1.0) +
      scale_colour_manual(values=c("blue", "red", "turquoise", "magenta", 
                                   "lightskyblue", "tomato"), labels=labels) +
      scale_linetype_manual(values=rep("solid", 6), labels=labels) +
      scale_y_continuous(breaks=seq(0.0, 1.6, 0.4), expand=c(0,0)) +
      coord_cartesian(ylim=c(0.0, 1.6)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.position="None") +
      ylab("Q values")
    
    plot(figure)
    
    fig_legend <- "None"
  }
  
  return(list(figure, fig_legend))
}

## --------- Figures showing mean Q values at each state ---------
# horizontal axis = State, vertical axis = Q values
hState_vQ_plot <- function(data, epi1, epi2, legend) {
  
  # prepare dataframe
  qdat <- data %>%
    filter(Episode > epi1 & Episode <= epi2) %>%
    group_by(Simulation, State) %>%
    summarize(Qgo_mean=mean(Q_go), Qstay_mean=mean(Q_stay), .groups="drop") %>%
    group_by(State) %>%
    summarize(Qgo_mean2=mean(Qgo_mean), Qgo_sd=sd(Qgo_mean), 
              Qstay_mean2=mean(Qstay_mean), Qstay_sd=sd(Qstay_mean), 
              .groups="drop")
  
  Q_mean <- c(qdat$Qgo_mean2, qdat$Qstay_mean2)
  Q_sd <- c(qdat$Qgo_sd, qdat$Qstay_sd)
  State <- rep(qdat$State, 2)
  Action <- c(rep("Go", 9), rep("No-Go", 9))
  
  qdat2 <- data.frame(State, Action, Q_mean, Q_sd)
  
  if (legend == 1) {
    figure <- ggplot(qdat2, aes(x=State, y=Q_mean, group=Action)) +
      geom_errorbar(aes(ymax=Q_mean+Q_sd, ymin=Q_mean-Q_sd, colour=Action), 
                    width=0.4) + 
      geom_point(aes(colour=Action, shape=Action), size=2, stroke=1.5) + 
      geom_line(aes(colour=Action, 
                    linetype=Action), size=1.0) +
      scale_colour_manual(values=c("blue", "red")) +
      scale_linetype_manual(values=c("solid", "solid")) +
      scale_x_continuous(breaks=seq(1,9,1)) +
      scale_y_continuous(breaks=seq(0.0, 1.6, 0.4), expand=c(0,0)) +
      coord_cartesian(ylim=c(0.0, 1.6)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.title=element_blank()) +
      theme(legend.text = element_text(size=10, family="Arial")) +
      theme(legend.title=element_blank()) +
      theme(legend.text.align = 0) +
      ylab("Q values")
    
    plot(figure)
    
    # save legend
    fig_legend <- g_legend(figure)
  }
  
  else {
    figure <- ggplot(qdat2, aes(x=State, y=Q_mean, group=Action)) +
      geom_errorbar(aes(ymax=Q_mean+Q_sd, ymin=Q_mean-Q_sd, colour=Action), 
                    width=0.4) + 
      geom_point(aes(colour=Action, shape=Action), size=2, stroke=1.5) + 
      geom_line(aes(colour=Action, 
                    linetype=Action), size=1.0) +
      scale_colour_manual(values=c("blue", "red")) +
      scale_linetype_manual(values=c("solid", "solid")) +
      scale_x_continuous(breaks=seq(1,9,1)) +
      scale_y_continuous(breaks=seq(0.0, 1.6, 0.4), expand=c(0,0)) +
      coord_cartesian(ylim=c(0.0, 1.6)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.position="None") +
      ylab("Q values")
    
    plot(figure)
    
    # save legend
    fig_legend <- "None"
  }
  
  return(list(figure, fig_legend))
}

## ------ Figures showing mean Q values difference at each state -------
# horizontal axis: State, vertical axis: difference in Q values
hState_vQdif_plot <- function(data, epi1, epi2) {
  
  # prepare dataframe
  data$Q_dif <- data$Q_go - data$Q_stay
  
  qdif_dat <- data %>%
    filter(Episode > epi1 & Episode <= epi2) %>%
    group_by(Simulation, State) %>%
    summarize(Qdif_mean=mean(Q_dif), .groups="drop") %>%
    group_by(State) %>%
    summarize(Qdif_mean2=mean(Qdif_mean), Qdif_sd=sd(Qdif_mean), 
              .groups="drop")
  
  # plot
  figure <- ggplot(qdif_dat, aes(x=State, y=Qdif_mean2)) +
    geom_point(colour="turquoise", size=2, stroke=1.5) +
    geom_line(colour="turquoise", size=0.70) +
    geom_errorbar(aes(ymax=Qdif_mean2+Qdif_sd, ymin=Qdif_mean2-Qdif_sd),
                  colour="turquoise", width=0.4) +
    scale_x_continuous(breaks=seq(1,9,1)) +
    scale_y_continuous(breaks=seq(0.02, 0.12, 0.02)) +
    coord_cartesian(ylim=c(0.01, 0.12)) +
    theme_classic() +
    theme(aspect.ratio=5/6) +
    theme(axis.title.x = element_text(size=15, family="Arial", face="bold"),
          axis.title.y = element_text(size=15, family="Arial", face="bold")) + 
    theme(axis.text.x = element_text(size=14, face="bold"),
          axis.text.y = element_text(size=14, face="bold")) +
    theme(legend.title=element_blank()) +
    theme(legend.text = element_text(size=10, family="Arial")) +
    theme(legend.title=element_blank()) +
    theme(legend.text.align = 0) +
    ylab("Q[Go] - Q[No-Go]")
  
  plot(figure)
  
  return(figure)
  
}

## ------- Q difference in the same figure -------
hState_vQdif_shape <- function(data, epi1, epi2) {
  data$Q_dif <- data$Q_go - data$Q_stay
  
  qdif_dat <- data %>%
    filter(Episode > epi1 & Episode <= epi2) %>%
    group_by(Simulation, State) %>%
    summarize(Qdif_mean=mean(Q_dif), .groups="drop") %>%
    group_by(State) %>%
    summarize(Qdif_mean2=mean(Qdif_mean), Qdif_sd=sd(Qdif_mean), 
              .groups="drop")
  
  return(qdif_dat)
}

hState_vQdif_plot2 <- function(kappa0, kappa20, kappa40, epi1, epi2, legend) {
  
  # prepare dataframe
  q_dat1 <- hState_vQdif_shape(kappa0, epi1, epi2)
  q_dat2 <- hState_vQdif_shape(kappa20, epi1, epi2)
  q_dat3 <- hState_vQdif_shape(kappa40, epi1, epi2)
  
  s <- seq(1,9,1)
  State <- c(s-0.2, s, s+0.2)
  Kappa <- c(rep(0.0, 9), rep(0.2, 9), rep(0.4, 9))
  Qdif_mean <- c(q_dat1$Qdif_mean2, q_dat2$Qdif_mean2, q_dat3$Qdif_mean2)
  Qdif_sd <- c(q_dat1$Qdif_sd, q_dat2$Qdif_sd, q_dat3$Qdif_sd)
  
  fig_dat <- data.frame(State, Kappa, Qdif_mean, Qdif_sd)
  fig_dat$Kappa <- as.factor(fig_dat$Kappa)
  
  # prepare labels
  k1 <- 0
  k2 <- 0.2
  k3 <- 0.4
  
  labs <- c(parse(text=sprintf('kappa=="%.0f"', k1)), 
            parse(text=sprintf('kappa=="%.1f"', k2)),
            parse(text=sprintf('kappa=="%.1f"', k3)))
  
  if (legend == 1){# with legend
    figure <- ggplot(fig_dat, aes(x=State, y=Qdif_mean, group=Kappa)) +
      geom_errorbar(aes(ymax=Qdif_mean+Qdif_sd, ymin=Qdif_mean-Qdif_sd), 
                    colour="black", width=0.2) +
      geom_line(colour="black", size=0.90) +
      geom_point(aes(fill=Kappa), shape=21, size=2.5, stroke=1.0) +
      scale_fill_manual(values=c("white","gray","black"), labels=labs) +
      scale_x_continuous(breaks=seq(1,9,1)) +
      scale_y_continuous(breaks=seq(0.0, 0.16, 0.04), expand=c(0,0)) +
      coord_cartesian(ylim=c(0.0, 0.17)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.title=element_blank()) +
      theme(legend.text = element_text(size=10, family="Arial")) +
      theme(legend.title=element_blank()) +
      theme(legend.text.align = 0) +
      ylab("Q[Go] - Q[No-Go]")
    
    plot(figure)
    
    # save legend
    fig_legend <- g_legend(figure)
  }
  
  else {
    figure <- ggplot(fig_dat, aes(x=State, y=Qdif_mean, group=Kappa)) +
      geom_errorbar(aes(ymax=Qdif_mean+Qdif_sd, ymin=Qdif_mean-Qdif_sd), 
                    colour="black", width=0.2) +
      geom_line(colour="black", size=0.90) +
      geom_point(aes(fill=Kappa), shape=21, size=2.5, stroke=1.0) +
      scale_fill_manual(values=c("white","gray","black"), labels=labs) +
      scale_x_continuous(breaks=seq(1,9,1)) +
      scale_y_continuous(breaks=seq(0.0, 0.16, 0.04), expand=c(0,0)) +
      coord_cartesian(ylim=c(0.0, 0.17)) +
      theme_classic() +
      theme(aspect.ratio=5/6) +
      theme(axis.title.x = element_text(size=16, family="Arial", face="bold"),
            axis.title.y = element_text(size=16, family="Arial", face="bold")) + 
      theme(axis.text.x = element_text(size=16, face="bold"),
            axis.text.y = element_text(size=16, face="bold")) +
      theme(legend.position="None") +
      ylab("Q[Go] - Q[No-Go]")
    
    plot(figure)
    
    # save legend
    fig_legend <- "None"
  }
  
  return(list(figure, fig_legend))
  
}