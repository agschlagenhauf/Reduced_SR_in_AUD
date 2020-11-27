#!/usr/bin/env python
# coding: utf-8

# In[1]:


# Create a foler to store results
import pathlib
pathlib.Path('./Full_SR').mkdir()


# In[2]:


# Reward function: Get reward(=1) only at the goal state
def R(current_state, end_state):
    if current_state == end_state:
        reward = 1
    else:
        reward = 0
    return reward


# function for one episode
def fullSR1(gamma, alpha, state_n, init_sr, init_weight, stay_prob,             state_list, action_list, RPE_list, weight_list): # weight_list=[[],[],[], ..., []]
    weight = init_weight # [0,0,0,0,0,0,0,0,0,1]
    time_step = 1
    feat = init_sr # feature vector; Successor Representation
    
    # Initial state value
    v_state = []
    for k in range(state_n):
        v_state.append(np.sum(weight*feat[k]))
        
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
            if current_state == state_n - 1: # at the goal
                next_state = current_state + 1
                go = 1
            else:
                if rd.random() < stay_prob: # stay
                    next_state = current_state
                    go = 0
                else: # move
                    next_state = current_state + 1
                    go = 1
            
            # calculate RPE
            if current_state == state_n - 1: # at the goal state
                delta = reward + 0 - v_state[current_state]
            else:
                delta = reward + gamma*v_state[next_state] - v_state[current_state]
            
            # update weights
            weight += alpha * delta * feat[current_state]
            
            # update state value
            for k in range(state_n):
                v_state[k] = np.sum(weight*feat[k])
            
            state_list.append(current_state+1)
            if go == 0:
                action_list.append("No-Go")
            else:
                action_list.append("Go")
            RPE_list.append(delta)
            timestep_list.append(time_step)
            
            for k in range(state_n):
                weight_list[k].append(weight[k])
            
            # Move to the next state
            current_state = next_state
            
            time_step += 1

    return weight, state_list, action_list, RPE_list, timestep_list, weight_list

# function for multi episodes
def fullSR2(epi_num, gamma, alpha, state_n, init_sr, init_weight,               stay_prob, state_list, action_list, RPE_list, weight_list, epi_num_list):
    epi_length = []
    for k in range(epi_num):
        c_weight, c_state_list, c_action_list, c_RPE_list, timestep_list, c_weight_list =         fullSR1(gamma, alpha, state_n, init_sr, init_weight, stay_prob, state_list, action_list, RPE_list, weight_list)
        
        for j in range(len(timestep_list)):
            epi_num_list.append(k+1)
                
        for j in range(len(timestep_list)):
            epi_length.append(k+1)
        
        init_weight = c_weight
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        weight_list = c_weight_list
        
    return c_weight, c_state_list, c_action_list, c_RPE_list, c_weight_list, epi_num_list, epi_length


# function for multi simulations
def fullSR3(sim_num, epi_num, gamma, alpha, state_n, init_weight,               stay_prob, state_list, action_list, RPE_list, weight_list, epi_num_list):
    sim_num_list = []
    
    # SR
    init_sr = np.array([])
    for j in range(state_n):
        row = np.array([])
    
        z = np.zeros(j)
        row = np.append(row, z)

        for k in range(state_n - j):
            row = np.append(row, gamma**(k))
            
        init_sr = np.append(init_sr, row)

    init_sr = init_sr.reshape((state_n, state_n))
    
    # Simulation
    for t in range(sim_num):
        # initialize weight
        init_weight = np.append(np.zeros(state_n - 1), np.ones(1))
        
        c_weight, c_state_list, c_action_list, c_RPE_list, c_weight_list, c_epi_num_list, epi_length =         fullSR2(epi_num, gamma, alpha, state_n, init_sr, init_weight, stay_prob, state_list, action_list, RPE_list, weight_list, epi_num_list)
        
        for u in range(len(epi_length)):
            sim_num_list.append(t+1)
    
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        weight_list = c_weight_list
        epi_num_list = c_epi_num_list
    
    return c_weight, c_state_list, c_action_list, c_RPE_list, c_weight_list, c_epi_num_list, sim_num_list


# In[3]:


# Multi Simulations
import numpy as np
import random as rd
rd.seed(46)

sim_num = 100
epi_num = 200
gamma = 0.97
alpha = 0.50
state_n = 10
stay_prob = 0.75
state_list = []
action_list = []
RPE_list = []
weight_list = [[] for k in range(state_n)]
init_weight = []
epi_num_list = []

rl = fullSR3(sim_num, epi_num, gamma, alpha, state_n, init_weight, stay_prob, 
             state_list, action_list, RPE_list, weight_list, epi_num_list)

# Create dataframe
import pandas as pd

result = pd.DataFrame({'Simulation': rl[6], 'Episode': rl[5], 'State': rl[1], 'Action': rl[2], 
              'RPE': rl[3], 'W1': rl[4][0], 'W2': rl[4][1], 'W3': rl[4][2], 'W4': rl[4][3], 
              'W5': rl[4][4], 'W6': rl[4][5], 'W7': rl[4][6], 'W8': rl[4][7], 'W9': rl[4][8], 
              'W10': rl[4][9]})

# Convert dataframe to csv
result.to_csv('./Full_SR/{}sim_{}epi_g{:.0f}_s{:.0f}_{:.0f}states.csv'.format(sim_num, epi_num, 100*gamma, 100*stay_prob, state_n))


# In[ ]:




