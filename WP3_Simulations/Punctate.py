import numpy as np
import random as rd
import pandas as pd

def punc1(gamma, alpha, end_states, rewards, transitions, v_state, state_list, action_list, RPE_list):
    time_step = 1
    current_state = 0
    timestep_list = []
    not_end = True
    
    while not_end:
        if current_state in end_states:
            not_end = False
            break
        
        else:
            # Get reward
            reward = rewards[current_state]
            
            # Determine the next state
            # Random chance of choosing any of the subsequent states(?)
            next_move = np.random.randint(len(transitions[current_state]))
            next_state = transitions[current_state][next_move]
            
            # calculate RPE and update weights and state values
            if current_state in end_states: # at the goal state
                delta = reward + 0 - v_state[current_state]
            else:
                delta = reward + gamma*v_state[next_state] - v_state[current_state]
            
            # update state value
            v_state[current_state] += alpha * delta
            
            state_list.append(current_state+1)
            action_list.append(next_state)
            RPE_list.append(delta)
            timestep_list.append(time_step)

            # Move to the next state
            current_state = next_state
            
            time_step += 1

    return v_state, state_list, action_list, RPE_list, timestep_list


# function for multi episodes
def punc2(epi_num, gamma, alpha, end_states, rewards, transitions, v_state, state_list, action_list, RPE_list, epi_num_list):
    epi_length = []
    for k in range(epi_num):
        c_v_state, c_state_list, c_action_list, c_RPE_list, timestep_list = \
        punc1(gamma, alpha, end_states, rewards, transitions, v_state, state_list, action_list, RPE_list)
        
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
def punc3(sim_num, epi_num, gamma, alpha, end_states, rewards, transitions, state_list, action_list, RPE_list, epi_num_list):
    sim_num_list = []
    
    for t in range(sim_num):
        v_state = rewards
        
        c_v_state, c_state_list, c_action_list, c_RPE_list, c_epi_num_list, epi_length = \
        punc2(epi_num, gamma, alpha, end_states, rewards, transitions, v_state, state_list, action_list, RPE_list, epi_num_list)
        
        for u in range(len(epi_length)):
            sim_num_list.append(t+1)
        
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        epi_num_list = c_epi_num_list
    
    return c_v_state, c_state_list, c_action_list, c_RPE_list, c_epi_num_list, sim_num_list


sim_num = 10
epi_num = 1
alpha = 0.50
gamma = 0.95
state_list = []
action_list = []
RPE_list = []
epi_num_list = []

end_states = [3, 4, 5]
rewards = [0, 0, 0, 15, 0, 30]
transitions = [[1, 2], [3, 4, 5],[3, 4, 5]]

rl = punc3(sim_num, epi_num, gamma, alpha, end_states, rewards, transitions, state_list, action_list, RPE_list, epi_num_list)