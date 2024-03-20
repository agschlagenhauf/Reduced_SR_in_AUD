import numpy as np
import random as rd
import pandas as pd


'''
Helper function that returns a flattened list
Input: list: a 2-dimensional list, which can be ragged
Output: the flattened list
'''
def list_flatten(list):
    return [item for row in list for item in row]


'''
Helper function that converts an index of a ragged 2d array into the equivalent index of the flattened array
Inputs:
    list: a 2 dimensional list, which can be ragged
    row: desired row index of the list
    item: desired item index of the given row
Output: the corresponding index of the flattened list
'''
def get_flattened_index(list, row, item):
    index = 0
    for i in range(row):
        index += len(list[i])
    index += item
    return index


'''
Simulates a single episode, from the given start state until an end state is reached
Inputs:
    gamma: the time discounting constant
    alpha: the learning rate constant
    explore_chance: probability that the agent will choose a random action instead of the highest-value one
    end_states: list of states that are considered end states
    start_state: state that the agent starts in
    rewards: list of rewards corresponding to each action
    transitions: list of valid transitions from each state
    v_state: calculated Q-values of each state-action pair (should generally be initialized as zeroes)
    state_list: states visited at each time step
    action_list: actions taken at each time step
    RPE_list: reward prediction error for each time step
    value_list: each state-action pair's Q-values at each time step
Outputs:
    v_state: Q-values updated after the current episode
    state_list, action_list, RPE_list, value_list: with episode's values appended to the end
    timestep_list: Total number of timesteps in this episode, used to pad all logs to the same length
'''
def punctate_episode(gamma, alpha, explore_chance, end_states, start_state, rewards, transitions, v_state, state_list, action_list, RPE_list, value_list):
    time_step = 1
    current_state = start_state - 1
    timestep_list = []
    not_end = True
    end_states_adjusted = [i-1 for i in end_states]
    
    while not_end:
        if current_state in end_states_adjusted:
            not_end = False
            break
        
        else:
            
            # Determine the next state, either a random subsequent state or the highest-value one based on the exploration parameter
            next_values = v_state[current_state]
            # If the next action values are all the same we also choose randomly to avoid argmax defaulting to the first action
            if np.random.uniform() < explore_chance or np.all([i == next_values[0] for i in next_values]):
                next_move = np.random.randint(len(transitions[current_state]))
            else:
                next_move = np.argmax(next_values)

            next_state = transitions[current_state][next_move] - 1

            # Update Q-values with TD learning on reward obtained
            reward = rewards[current_state][next_move]
            if next_state in end_states_adjusted: # reached the goal state
                delta = reward + 0 - v_state[current_state][next_move]
            else:
                delta = reward + gamma*np.max(v_state[next_state]) - v_state[current_state][next_move]
            v_state[current_state][next_move] += alpha * delta
            
            state_list.append(current_state + 1)
            action_list.append(next_state + 1)
            RPE_list.append(delta)

            values_flat = list_flatten(v_state)
            for k in range(len(values_flat)):
                value_list[k].append(values_flat[k])
            timestep_list.append(time_step)

            # Move to the next state
            current_state = next_state
            
            time_step += 1

    return v_state, state_list, action_list, RPE_list, value_list, timestep_list


'''
Simulates the pre-training learning phase, where the agent has access to the starting state
Inputs:
    gamma: the time discounting constant
    alpha: the learning rate constant
    explore_chance: probability that the agent will choose a random action instead of the highest-value one
    end_states: list of states that are considered end states
    rewards: list of rewards corresponding to each action
    transitions: list of valid transitions from each state
    v_state: calculated Q-values of each state-action pair (should generally be initialized as zeroes)
    logging lists: list of various logging variables, lists in order are:
        state_list: states visited at each time step
        action_list: actions taken at each time step
        RPE_list: reward prediction error for each time step
        epi_num_list: tracks the current episode number
        phase_list: tracks the current learning phase (1 = pretraining, 2 = retraining, 3 = test)
        value_list: each state-action pair's Q-values at each time step
Outputs:
    v_state: calculated state values after pretraining
    logging_lists: with new simulation's values appended to the end
    epi_length: Total number of timesteps in the pretraining, used to pad all logs to the same length
'''
def pretraining(gamma, alpha, explore_chance, end_states, rewards, transitions, v_state, logging_lists):
    # Unpack logging_lists into component logs
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    # Create the list of starting states, randomly ordered, but guaranteed a certain number of starts in each starting state
    start_states = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 5, 5, 6, 6])
    start_states= np.append(start_states, np.random.randint(1, 7, 5))
    np.random.shuffle(start_states)
    for index, k in enumerate(start_states):
        c_v_state, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        punctate_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, v_state, state_list, action_list, RPE_list, value_list)

        # Update the logs that depend on the length of the current episode
        for j in range(len(timestep_list)):
            epi_num_list.append(index+1)
            epi_length.append(index+1)
            phase_list.append(1)

        v_state = c_v_state
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        value_list = c_value_list

    logs_new = [c_state_list, c_action_list, c_RPE_list, epi_num_list, phase_list]
    logs_new.append(value_list)
        
    return c_v_state, logs_new, epi_length


'''
Changes the rewards and transitions for the re-learning phase, as appropriate for the condition being tested
Inputs:
    condition: String with the name of the condition being tested (case sensitive, so first letter needs to be capitalized)
    rewards: the original reward list
    transitions: the original transition list
Outputs:
    rewards: the new reward list
    transitions: the new transition list
'''
def update_parameters(condition, rewards, transitions):
    if condition == "Reward":
        rewards = [[0, 0], [0, 0], [0, 0], [45], [0], [30], [0], [0], [0], [0]]
    elif condition == "Transition":
        transitions = [[2, 3], [5, 6], [4, 5], [7], [8], [9], [10], [10], [10], [11]]
    elif condition == "Policy":
        rewards = [[0, 0], [0, 0], [0, 0], [45], [15], [30], [0], [0], [0], [0]]
    elif condition == "Goal":
        rewards = [[0, 0], [0, 0], [0, 0], [15], [0], [30], [30], [0], [0], [0]]
    else:
        rewards = [[0, 0], [0, 0], [0, 0], [15], [0], [30], [0], [0], [45], [0]]
    return rewards, transitions


'''
Simulates the relearning phase, where the agent does not directly experience the starting state
Inputs:
    condition: string representing the relearning condition, case sensitive (needed because the Transition condition uses different starting states)
    gamma: the time discounting constant
    alpha: the learning rate constant
    explore_chance: probability that the agent will choose a random action instead of the highest-value one
    end_states: list of states that are considered end states
    rewards: list of rewards corresponding to each action
    transitions: list of valid transitions from each state
    v_state: calculated Q-values of each state-action pair, held over from the pretraining
    logging lists: list of various logging variables, lists in order are:
        state_list: states visited at each time step
        action_list: actions taken at each time step
        RPE_list: reward prediction error for each time step
        epi_num_list: tracks the current episode number
        phase_list: tracks the current learning phase (1 = pretraining, 2 = retraining, 3 = test)
        value_list: each state-action pair's Q-values at each time step
Outputs:
    v_state: calculated state values after pretraining
    logging_lists: with new simulation's values appended to the end
    epi_length: Total number of timesteps in the pretraining, used to pad all logs to the same length
'''
def retraining(condition, gamma, alpha, explore_chance, end_states, rewards, transitions, v_state, logging_lists):
    # Unpack logging_lists into component logs
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    if condition == "Transition":
        start_states = np.array([2, 2, 2, 3, 3, 3, 4, 5, 6])
    else:
        start_states = np.array([4, 4, 4, 5, 5, 5, 6, 6, 6])
    np.random.shuffle(start_states)
    for index, k in enumerate(start_states):
        c_v_state, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        punctate_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, v_state, state_list, action_list, RPE_list, value_list)

        # Update the logs that depend on the length of the current episode
        for j in range(len(timestep_list)):
            epi_num_list.append(index+1)
            epi_length.append(index+1)
            phase_list.append(2)

        v_state = c_v_state
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        value_list = c_value_list

        logs_new = [c_state_list, c_action_list, c_RPE_list, epi_num_list, phase_list, value_list]
        
    return c_v_state, logs_new, epi_length


'''
Appends the current Q-values and corresponding simulation and phase labels to the milestone logs
Inputs:
    milestone_logs: list holding each phase's learned Q-values
    milestone_labels: list holding the simulation number and current phase for each row
    sim_num: Number of the current simulation
    phase: String describing the current learning phase
    v_state: The model's current Q-values
Outputs:
    milestone logs, milestone labels: with new learning phase's values appended to the end
'''
def update_logs(milestone_logs, milestone_labels, sim_num, phase, v_state):
    values_flat = list_flatten(v_state)
    for k in range(len(values_flat)):
        milestone_logs[k].append(values_flat[k])
    milestone_labels[0].append(sim_num + 1)
    milestone_labels[1].append(phase)
    return milestone_logs, milestone_labels


'''
Simulates the test phase by comparing the action values of the two possible starting-state actions. The test state action is assumed to always be 
the higher-value choice
Input: v_state: 2d list of Q-values (rows are states, columns are actions)
Output: preferred starting state action
'''
def test(v_state):
    return np.argmax(v_state[0]) + 2