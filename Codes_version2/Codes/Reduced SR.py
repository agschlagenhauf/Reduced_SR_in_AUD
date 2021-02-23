#!/usr/bin/env python
# coding: utf-8

# In[7]:


# Create a folder to store results
import pathlib
pathlib.Path('./Reduced_SR').mkdir()


# In[8]:


# Reward function: Get reward(=1) only at the goal state
def R(current_state, end_state):
    if current_state == end_state:
        reward = 1
    else:
        reward = 0
    return reward

# function for one episode
def reduced1(gamma, alpha, alpha_sr, state_n, init_feat, init_weight, 
              stay_prob, state_list, action_list, RPE_list, weight_list):
    weight = init_weight
    time_step = 1
    feat = init_feat # feature vector; Successor Representation
    feat = np.array(feat)
    v_state = weight * feat
    current_state = 0
    timestep_list = []
    not_end = True
    
    while not_end:
        if current_state == state_n:
            not_end = False
            break
        
        else:
            # Get reward
            reward = R(current_state, state_n - 1)
            
            # Determine the next state
            if current_state == state_n - 1:
                next_state = current_state + 1
                go = 1
            else:
                if rd.random() < stay_prob: # stay
                    next_state = current_state
                    go = 0
                else: # move
                    next_state = current_state + 1
                    go = 1
            
            # calculate RPE and update weights, state values, and feature
            if current_state == state_n - 1: # at the goal state
                delta = reward + 0 - v_state[current_state]
                delta_sr = 1 + 0 - feat[current_state]
            else:
                delta = reward + gamma*v_state[next_state] - v_state[current_state]
                delta_sr = 0 + gamma*feat[next_state] - feat[current_state]
            
            
            weight += alpha * delta * feat[current_state]
            feat[current_state] += alpha_sr * delta_sr
            v_state = feat * weight
            
            state_list.append(current_state+1)
            if go == 0:
                action_list.append("No-Go")
            else:
                action_list.append("Go")
            RPE_list.append(delta)
            timestep_list.append(time_step)
            weight_list.append(weight)
            
            # Move to the next state
            current_state = next_state
            
            time_step += 1

    return weight, feat, state_list, action_list, RPE_list, timestep_list, weight_list

# function for multi episodes
def reduced2(epi_num, gamma, alpha, alpha_sr, state_n, init_feat, feat_list, init_weight,                 stay_prob, state_list, action_list, RPE_list, weight_list, epi_num_list):
    epi_length = []
    for k in range(epi_num):
        c_weight, c_feat, c_state_list, c_action_list, c_RPE_list, timestep_list, c_weight_list =         reduced1(gamma, alpha, alpha_sr, state_n, init_feat, init_weight, stay_prob, state_list, action_list, RPE_list, weight_list)
        
        for j in range(len(timestep_list)):
            epi_num_list.append(k+1)
                
        for j in range(len(timestep_list)):
            epi_length.append(k+1)
        
        feat_list.append(c_feat)
        init_feat = c_feat
        init_weight = c_weight
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        weight_list = c_weight_list
        
    return c_weight, c_feat, feat_list, c_state_list, c_action_list, c_RPE_list, c_weight_list, epi_num_list, epi_length


# function for multi simulations
def reduced3(sim_num, epi_num, gamma, alpha, alpha_sr, state_n, feat_list,                 stay_prob, state_list, action_list, RPE_list, weight_list, epi_num_list):
    
    sim_num_list = []
    
    for t in range(sim_num):
        # initialize weight and feature vector
        init_weight = 1.0
        init_feat = []
        for k in range(state_n):
            init_feat.append(gamma**(state_n - k - 1)) # feat = [gamma^n-1, gamma^n-2, ..., gamma, 1]
        
        c_weight, c_feat, c_feat_list, c_state_list, c_action_list, c_RPE_list, c_weight_list, c_epi_num_list, epi_length =         reduced2(epi_num, gamma, alpha, alpha_sr, state_n, init_feat, feat_list, init_weight, stay_prob, state_list, action_list, RPE_list, weight_list, epi_num_list)
        
        for u in range(len(epi_length)):
            sim_num_list.append(t+1)
    
        feat_list = c_feat_list
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        weight_list = c_weight_list
        epi_num_list = c_epi_num_list
    
    return c_weight, c_feat, c_feat_list, c_state_list, c_action_list, c_RPE_list, c_weight_list, c_epi_num_list, sim_num_list


# In[9]:


# Simulations with various parameters
import numpy as np
import random as rd
import pandas as pd

seed_list = [49, 100, 82, 101, 31, 102, 37, 103, 12, 
            75, 87, 104, 42, 105, 99, 106, 85, 107]
index = 0

for gamma in [0.95, 0.97, 0.99]:
    for stay_prob in [0.50, 0.75, 0.90]:
        for alpha_sr in [0.0, 0.05]:
            
            rd.seed(seed_list[index])
            
            # set constant variables
            sim_num = 100
            epi_num = 200
            alpha = 0.50
            state_n = 10
            feat_list = []
            state_list = []
            action_list = []
            RPE_list = []
            weight_list = []
            epi_num_list = []
            
            # conduct simulation(rl: results lists)
            rl = reduced3(sim_num, epi_num, gamma, alpha, alpha_sr, state_n, 
                              feat_list, stay_prob, state_list, action_list, 
                              RPE_list, weight_list, epi_num_list)
            
            # Create dataframe and convert it to csv
            result = pd.DataFrame({'Simulation': rl[8], 'Episode': rl[7], 'State': rl[3],
                                  'Action': rl[4], 'RPE': rl[5], 'Weight': rl[6]})
            result.to_csv('./Reduced_SR/alphaSR{:.0f}_g{:.0f}_s{:.0f}_{:.0f}states.csv'.format(100*alpha_sr, 100*gamma, 100*stay_prob, state_n))
            
            # Create dataframe of SR
            sr = np.array(rl[2])
            sr = sr.flatten()
            
            Simulation = []
            Episode = []
            State = []
            
            for sim in range(sim_num):
                for epi in range(epi_num):
                    for state in range(state_n):
                        Simulation.append(sim+1)
                        Episode.append(epi+1)
                        State.append(state+1)
                        
            SRres = pd.DataFrame({'Simulation': Simulation, 'Episode': Episode,
                                 'State': State, 'SR': sr})
            
            SRres.to_csv('./Reduced_SR/SR_alphaSR{:.0f}_g{:.0f}_s{:.0f}_{:.0f}states.csv'.format(100*alpha_sr, 100*gamma, 100*stay_prob, state_n))
            
            index += 1


# In[10]:


# Simulation with alpha = 0.10
import numpy as np
import random as rd
import pandas as pd
rd.seed(20201107)

sim_num = 100
epi_num = 200
gamma = 0.97
alpha = 0.10
alpha_sr = 0.0
state_n = 10
feat_list = []
stay_prob = 0.75
state_list = []
action_list = []
RPE_list = []
weight_list = []
epi_num_list = []

# simulate
rl = reduced3(sim_num, epi_num, gamma, alpha, alpha_sr, state_n, feat_list, stay_prob, 
              state_list, action_list, RPE_list, weight_list, epi_num_list)
            
# Create dataframe and convert it to csv
result = pd.DataFrame({'Simulation': rl[8], 'Episode': rl[7], 'State': rl[3],
                       'Action': rl[4], 'RPE': rl[5], 'Weight': rl[6]})
result.to_csv('./Reduced_SR/alpha{:.0f}_alphaSR{:.0f}_g{:.0f}_s{:.0f}_{:.0f}states.csv'.format(100*alpha, 100*alpha_sr, 100*gamma, 100*stay_prob, state_n))
            
# Create dataframe of SR
sr = np.array(rl[2])
sr = sr.flatten()
            
Simulation = []
Episode = []
State = []
            
for sim in range(sim_num):
    for epi in range(epi_num):
        for state in range(state_n):
            Simulation.append(sim+1)
            Episode.append(epi+1)
            State.append(state+1)
                        
SRres = pd.DataFrame({'Simulation': Simulation, 'Episode': Episode, 'State': State, 'SR': sr})
            
SRres.to_csv('./Reduced_SR/SR_alpha{:.0f}_alphaSR{:.0f}_g{:.0f}_s{:.0f}_{:.0f}states.csv'.format(100*alpha, 100*alpha_sr, 100*gamma, 100*stay_prob, state_n))


# In[ ]:




