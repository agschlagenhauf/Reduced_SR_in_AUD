#!/usr/bin/env python
# coding: utf-8

# In[5]:


# Create a folder to store csv files
import pathlib
pathlib.Path('./Punctate').mkdir()


# In[6]:


# Reward function: Get reward(=1) only at the goal state
def R(current_state, end_state):
    if current_state == end_state:
        reward = 1
    else:
        reward = 0
    return reward


# function for one episode
def punc1(gamma, alpha, state_n, v_state, stay_prob, state_list, action_list, RPE_list):
    time_step = 1
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
            
            # calculate RPE and update weights and state values
            if current_state == state_n - 1: # at the goal state
                delta = reward + 0 - v_state[current_state]
            else:
                delta = reward + gamma*v_state[next_state] - v_state[current_state]
            
            # update state value
            v_state[current_state] += alpha * delta
            
            state_list.append(current_state+1)
            if go == 0:
                action_list.append("No-Go")
            else:
                action_list.append("Go")
            RPE_list.append(delta)
            timestep_list.append(time_step)

            # Move to the next state
            current_state = next_state
            
            time_step += 1

    return v_state, state_list, action_list, RPE_list, timestep_list

# function for multi episodes
def punc2(epi_num, gamma, alpha, state_n, v_state, stay_prob,               state_list, action_list, RPE_list, epi_num_list):
    epi_length = []
    for k in range(epi_num):
        c_v_state, c_state_list, c_action_list, c_RPE_list, timestep_list =         punc1(gamma, alpha, state_n, v_state, stay_prob, state_list, action_list, RPE_list)
        
        for j in range(len(timestep_list)):
            epi_num_list.append(k+1)
                
        for j in range(len(timestep_list)):
            epi_length.append(k+1)
        
        v_state = c_v_state
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        
    return c_v_state, c_state_list, c_action_list, c_RPE_list, epi_num_list, epi_length


# function for multi simulations
def punc3(sim_num, epi_num, gamma, alpha, state_n, stay_prob,               state_list, action_list, RPE_list, epi_num_list):
    sim_num_list = []
    
    for t in range(sim_num):
        v_state = [] # initialize
        for k in range(state_n):
            v_state.append(gamma**(state_n - k - 1)) # v_state = [gamma^n-1, gamma^n-2, ..., gamma, 1]; true value under "Non-resistant" policy
        
        c_v_state, c_state_list, c_action_list, c_RPE_list, c_epi_num_list, epi_length =         punc2(epi_num, gamma, alpha, state_n, v_state, stay_prob, state_list, action_list, RPE_list, epi_num_list)
        
        for u in range(len(epi_length)):
            sim_num_list.append(t+1)
        
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        epi_num_list = c_epi_num_list
    
    return c_v_state, c_state_list, c_action_list, c_RPE_list, c_epi_num_list, sim_num_list


# In[7]:


# Simulations with various parameters
import numpy as np
import random as rd
import pandas as pd

seed_list = [22, 76, 50, 57, 30, 55, 33, 54,  0]
index = 0

for gamma in [0.95, 0.97, 0.99]:
    for stay_prob in [0.50, 0.75, 0.90]:
        
        rd.seed(seed_list[index])
        
        # set constant variables
        sim_num = 100
        epi_num = 200
        alpha = 0.50
        state_n = 10
        state_list = []
        action_list = []
        RPE_list = []
        epi_num_list = []
        
        # simulation
        rl = punc3(sim_num, epi_num, gamma, alpha, state_n, stay_prob, state_list,
                  action_list, RPE_list, epi_num_list)
        
        # create dataframe and convert it to csv
        result = pd.DataFrame({'Simulation': rl[5], 'Episode': rl[4], 'State': rl[1],
                              'Action': rl[2], 'RPE': rl[3]})
        result.to_csv('./Punctate/g{:.0f}_s{:.0f}_{:.0f}states.csv'.format(100*gamma, 100*stay_prob, state_n))
        index += 1


# In[ ]:




