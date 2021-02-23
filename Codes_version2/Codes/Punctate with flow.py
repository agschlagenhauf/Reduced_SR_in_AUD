#!/usr/bin/env python
# coding: utf-8

# In[2]:


# Create a foler to store results
import pathlib
pathlib.Path('./Punctate_flow').mkdir()


# In[3]:


# function for one episode
# the agent gets reward at the goal state(=State 10)
def punc_f1(gamma, alpha, state_n, init_v, init_q, state_list, action_list, RPE_list, q_RPE_list, 
            qraw_RPE_list, stay_prob, kappa, QorS): # QorS: 0=Q-learning, 1=SARSA
    time_step = 1
    current_state = 0
    timestep_list = []
    v_state = init_v
    v_state = np.array(v_state)
    q = init_q
    q = np.array(q)
    not_end = True
    
    while not_end:
        if current_state == state_n:
            not_end = False
            break
        
        else:
            # Determine the next state and action
            if current_state == state_n - 1: # at the goal
                next_state = current_state + 1
                action = 1 # Go only
            
            else:
                if rd.random() < stay_prob:
                    next_state = current_state
                    action = 0 # No-Go
                else:
                    next_state = current_state + 1
                    action = 1 # Go
            
            # Calculate RPE
            if current_state == state_n - 1: # at the goal state
                reward = 1
                delta = reward + 0 - v_state[current_state]
                
                if QorS == 0: # Q-learning
                    # raw RPE of Q learning system
                    delta_q = reward + 0 - q[previous_state][previous_action]
                
                else: # SARSA
                    delta_q = reward + 0 - q[previous_state][previous_action]
                
            else: # at states other than the goal
                reward = 0
                delta = reward + gamma * v_state[next_state] - v_state[current_state]
                
                if QorS == 0: # Q-learning
                    if time_step == 1: # at the first time-step
                        # raw RPE of Q learning system
                        delta_q = reward + gamma * max(q[current_state]) - 0
                    else:
                        # raw RPE of Q learning system
                        delta_q = reward + gamma * max(q[current_state]) - q[previous_state][previous_action]
                
                else: # SARSA
                    if time_step == 1: # at the first trial
                        delta_q = reward + gamma * q[current_state][action] - 0
                    else:
                        delta_q = reward + gamma * q[current_state][action] - q[previous_state][previous_action]
                        
            rpe_with_flow = kappa*delta + (1-kappa)*delta_q
                
            # Update state values and Q values
            v_state[current_state] += alpha * delta
            if time_step > 1:
                q[previous_state][previous_action] += alpha * rpe_with_flow
            
            state_num = current_state + 1
            state_list.append(state_num)
            if action == 0:
                action_list.append("No-Go")
            else:
                action_list.append("Go")
            RPE_list.append(delta)
            q_RPE_list.append(rpe_with_flow)
            qraw_RPE_list.append(delta_q)
            timestep_list.append(time_step)
            
            # Move to the next state
            previous_state = current_state
            previous_action = action
            current_state = next_state
            
            time_step += 1

    return v_state, q, state_list, action_list, RPE_list, q_RPE_list, qraw_RPE_list, timestep_list

# function for multi episodes
def punc_f2(epi_num, gamma, alpha, state_n, init_v, init_q, state_list, action_list, RPE_list, 
          q_RPE_list, qraw_RPE_list, epi_num_list, stay_prob, kappa, QorS):
    epi_length = []
    q_list = []
    
    for k in range(epi_num):
        c_v_state, c_q, c_state_list, c_action_list, c_RPE_list, c_q_RPE_list, c_qraw_RPE_list, timestep_list =         punc_f1(gamma, alpha, state_n, init_v, init_q, state_list, action_list, RPE_list, q_RPE_list, 
                qraw_RPE_list, stay_prob, kappa, QorS)
        
        for j in range(len(timestep_list)):
            epi_num_list.append(k+1)
                
        for j in range(len(timestep_list)):
            epi_length.append(k+1)
        
        q_as_list = c_q.tolist()
        q_list.append(q_as_list)
        
        init_v = c_v_state
        init_q = c_q
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        qraw_RPE_list = c_qraw_RPE_list
        q_RPE_list = c_q_RPE_list
        
    return c_state_list, c_action_list, c_RPE_list, c_q_RPE_list, c_qraw_RPE_list, epi_num_list, epi_length, q_list


# function for multi simulations
def punc_f3(sim_num, epi_num, gamma, alpha, state_n, state_list, action_list, 
          RPE_list, q_RPE_list, qraw_RPE_list, epi_num_list, stay_prob, kappa, QorS):
    sim_num_list = []
    q_list_l = []
    
    for t in range(sim_num):
        # initialize state values and Q values
        init_v = []
        init_q = []
        
        for k in range(state_n):
            init_v.append(gamma**(state_n - k - 1)) # v_state = [gamma^n-1, gamma^n-2, ..., gamma, 1]
        
        for k in range(state_n - 1):
            init_q.append([gamma**(state_n - k - 1), gamma**(state_n - k - 2)])
        
        c_state_list, c_action_list, c_RPE_list, c_q_RPE_list, c_qraw_RPE_list,         c_epi_num_list, epi_length, q_list =         punc_f2(epi_num, gamma, alpha, state_n, init_v, init_q, state_list, action_list,
                RPE_list, q_RPE_list, qraw_RPE_list, epi_num_list, stay_prob, kappa, QorS)
        
        for u in range(len(epi_length)):
            sim_num_list.append(t+1)
        
        q_list_l.append(q_list)
        
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        q_RPE_list = c_q_RPE_list
        qraw_RPE_list = c_qraw_RPE_list
        epi_num_list = c_epi_num_list
    
    return c_state_list, c_action_list, c_RPE_list, c_q_RPE_list, c_qraw_RPE_list, c_epi_num_list, sim_num_list, q_list_l


# In[4]:


# Simulation with different parameters
# and create dataframe + convert it to csv
import numpy as np
import random as rd
import pandas as pd
rd.seed(20201119)

for QorS in [0, 1]:
    for kappa in [0.0, 0.20, 0.40]:
        # set fixed parameters
        sim_num = 100
        epi_num = 200
        gamma = 0.97
        alpha = 0.50
        state_n = 10
        state_list = []
        action_list = []
        RPE_list = []
        q_RPE_list = []
        qraw_RPE_list = []
        epi_num_list = []
        stay_prob = 0.75
    
        # Simulation
        rl = punc_f3(sim_num, epi_num, gamma, alpha, state_n, state_list, action_list, 
                        RPE_list,q_RPE_list, qraw_RPE_list, epi_num_list, stay_prob, kappa, QorS)
    
        # Create dataframe
        punc_f_res =         pd.DataFrame({'Simulation': rl[6], 'Episode': rl[5], 'State': rl[0], 'Action': rl[1], 
                      'RPE':rl[2], 'Q_RPE':rl[3], 'Q_RPE_raw':rl[4]})

        # convert dataframe to csv
        if QorS == 0:
            punc_f_res.to_csv('./Punctate_flow/Q_g{:.0f}_s{:.0f}_kappa{:.0f}_{:.0f}states.csv'.format(100*gamma, 100*stay_prob, 100*kappa, state_n))
            
        else:
            punc_f_res.to_csv('./Punctate_flow/SARSA_g{:.0f}_s{:.0f}_kappa{:.0f}_{:.0f}states.csv'.format(100*gamma, 100*stay_prob, 100*kappa, state_n))
    
        # Create dataframe for Q values
        q_list = rl[7]
        sim_list = []
        epi_list = []
        state_list = []
        q_go = []
        q_stay = []

        for sim in range(sim_num):
            for epi in range(epi_num):
                for state in range(state_n - 1):
                    qs = q_list[sim][epi][state]
                    sim_list.append(sim+1)
                    epi_list.append(epi+1)
                    state_list.append(state+1)
                    q_go.append(qs[1])
                    q_stay.append(qs[0])
            
        q_values =         pd.DataFrame({'Simulation': sim_list, 'Episode': epi_list, 'State': state_list, 'Q_go': q_go, 'Q_stay': q_stay})

        # convert dataframe to csv
        if QorS == 0:
            q_values.to_csv('./Punctate_flow/Q_Qvalues_g{:.0f}_s{:.0f}_kappa{:.0f}_{:.0f}states.csv'.format(100*gamma, 100*stay_prob, 100*kappa, state_n))
            
        else:
            q_values.to_csv('./Punctate_flow/SARSA_Qvalues_g{:.0f}_s{:.0f}_kappa{:.0f}_{:.0f}states.csv'.format(100*gamma, 100*stay_prob, 100*kappa, state_n))


# In[ ]:




