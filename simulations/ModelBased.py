import numpy as np
import random as rd


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
Finds the probability of choosing each action of a given state under the current policy
Inputs:
    values: 1D list of the calculated Q-values of all actions from a single state
    explore-chance: probability that the current policy will choose a random action
Output: policy - the probability that each action will be chosen
'''
def policy(values, explore_chance):
    if np.all([i == values[0] for i in values]):
        policy = np.repeat((1 / len(values)), len(values))
    else:
        policy = np.repeat((explore_chance / len(values)), len(values))
        policy[np.argmax(values)] += 1 - explore_chance
    return policy


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
    num_pairs: the number of state-action pairs
    feat: the successor matrix
    weight: the weight vector
    state_list: states visited at each time step
    action_list: actions taken at each time step
    RPE_list: reward prediction error for each time step
    value_list: each state-action pair's Q-values at each time step
Outputs:
    feat, weight: values updated after the current episode
    state_list, action_list, RPE_list, value_list: with episode's values appended to the end
    timestep_list: Total number of timesteps in this episode, used to pad all logs to the same length
'''
def successor_episode(gamma, alpha, explore_chance, end_states, start_state, rewards, transitions, v_state, t_counts, weight, state_list, action_list, RPE_list, value_list):
    time_step = 1

    # Transition matrix is a normalized count of the number of times each state follows directly from each state-action pair
    # In our case, transitions are deterministic so this effectively be a one-hot array
    t_matrix = np.zeros((len(list_flatten(rewards)), len(rewards)))
        
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

            # Update weights with TD learning on the reward
            reward = rewards[current_state][next_move]
            weight_delta = reward - weight[current_state][next_move]
            weight[current_state][next_move] += alpha * weight_delta

            # Update transition counts and re-normalize
            t_counts[get_flattened_index(rewards, current_state, next_move), next_state] += 1
            for index, row in enumerate(t_counts):
                if np.sum(row) == 0:
                    t_matrix[index] = np.zeros(len(rewards))
                else:
                    t_matrix[index] = row / np.sum(row)
            
            # Update the Q-Values according to the Bellman Equation
            next_state_values = [np.sum(v_state[state] * policy(v_state[state], explore_chance)) for state in range(len(rewards))]
            for i in range(len(rewards)):
                for j in range(len(rewards[i])):
                    v_state[i][j] = weight[i][j] + gamma * np.sum(t_matrix[get_flattened_index(rewards, i, j)] * next_state_values)

            state_list.append(current_state + 1)
            action_list.append(next_state + 1)
            RPE_list.append(weight_delta)
            timestep_list.append(time_step)
            
            values_flat = list_flatten(v_state)
            for k in range(len(values_flat)):
                value_list[k].append(values_flat[k])
            
            # Move to the next state
            current_state = next_state
            
            time_step += 1

    return v_state, t_counts, weight, state_list, action_list, RPE_list, value_list, timestep_list


'''
Simulates the pre-training learning phase, where the agent has access to the starting state
Inputs:
    gamma: the time discounting constant
    alpha: the learning rate constant
    explore_chance: probability that the agent will choose a random action instead of the highest-value one
    end_states: list of states that are considered end states
    rewards: list of rewards corresponding to each action
    transitions: list of valid transitions from each state
    model_parameters: the components of a successor representation, in order:
        num_pairs: the number of state-action pairs
        feat: the successor matrix (should generally be initialized with zeros)
        weight: the weight vector (also generally initialized with zeros)
    logging lists: list of various logging variables, lists in order are:
        state_list: states visited at each time step
        action_list: actions taken at each time step
        RPE_list: reward prediction error for each time step
        epi_num_list: tracks the current episode number
        phase_list: tracks the current learning phase (1 = pretraining, 2 = retraining, 3 = test)
        value_list: each state-action pair's Q-values at each time step
Outputs:
    model_parameters: calculated successor matrix and weight after pretraining
    logging_lists: with new simulation's values appended to the end
    epi_length: Total number of timesteps in the pretraining, used to pad all logs to the same length
'''
def pretraining(gamma, alpha, explore_chance, end_states, rewards, transitions, model_parameters, logging_lists):
    # Unpack logging_lists and model parameters into component variables
    v_state, t_counts, weight = model_parameters
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    # Create the list of starting states, randomly ordered, but guaranteed a certain number of starts in each starting state
    #start_states = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 5, 5, 6, 6])
    start_states = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
    start_states= np.append(start_states, np.random.randint(1, 7, 5))
    np.random.shuffle(start_states)
    for index, k in enumerate(start_states):
        c_v_state, c_t_counts, c_weight, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        successor_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, v_state, t_counts, weight, state_list, action_list, RPE_list, value_list)

        # Update the logs that depend on the length of the current episode
        for j in range(len(timestep_list)):
            epi_num_list.append(index+1)
            epi_length.append(index+1)
            phase_list.append(1)

        v_state = c_v_state
        t_counts = c_t_counts
        weight = c_weight
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        value_list = c_value_list

    logs_new = [c_state_list, c_action_list, c_RPE_list, epi_num_list, phase_list]
    logs_new.append(value_list)
    new_params = [v_state, t_counts, weight]
        
    return new_params, logs_new, epi_length


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
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [40], [0], [30], [0]]
    elif condition == "Transition":
        transitions = [[2, 3], [5, 6], [4, 5], [7], [8], [9], [10], [10], [10], [11]]
    elif condition == "Policy":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [40], [20], [30], [0]]
    elif condition == "Goal":
        rewards = [[0, 0], [0, 0], [0, 0], [20], [0], [0], [20], [0], [30], [0]]
    else:
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [20], [0], [40], [0]]
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
    model parameters: the components of a successor representation, in order:
        num_pairs: the number of state-action pairs
        feat: the successor matrix, held over from the pretraining
        weight: the weight vector, held over from pretraining
    logging lists: list of various logging variables, lists in order are:
        state_list: states visited at each time step
        action_list: actions taken at each time step
        RPE_list: reward prediction error for each time step
        epi_num_list: tracks the current episode number
        phase_list: tracks the current learning phase (1 = pretraining, 2 = retraining, 3 = test)
        value_list: each state-action pair's Q-values at each time step
Outputs:
    model_parameters: calculated successor matrix and weight after pretraining
    logging_lists: with new simulation's values appended to the end
    epi_length: Total number of timesteps in the pretraining, used to pad all logs to the same length
'''
def retraining(condition, gamma, alpha, explore_chance, end_states, rewards, transitions, model_parameters, logging_lists):
    # Unpack logging_lists and model parameters into component variables
    v_state, t_counts, weight = model_parameters
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    # Create the list of starting states, randomly ordered, but guaranteed a certain number of starts in each starting state
    if condition == "Transition":
        #start_states = np.array([2, 2, 2, 3, 3, 3, 4, 5, 6])
        start_states = np.array([2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3])
    else:
        start_states = np.array([4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6])
    np.random.shuffle(start_states)
    for index, k in enumerate(start_states):
        c_v_state, c_t_counts, c_weight, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        successor_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, v_state, t_counts, weight, state_list, action_list, RPE_list, value_list)

        # Update the logs that depend on the length of the current episode
        for j in range(len(timestep_list)):
            epi_num_list.append(index+1)
            epi_length.append(index+1)
            phase_list.append(1)

        v_state = c_v_state
        t_counts = c_t_counts
        weight = c_weight
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        value_list = c_value_list

    logs_new = [c_state_list, c_action_list, c_RPE_list, epi_num_list, phase_list]
    logs_new.append(value_list)
    new_params = [v_state, t_counts, weight]
        
    return new_params, logs_new, epi_length


'''
Appends the current weight vector and successor matrix and corresponding simulation and phase labels to the milestone logs
Inputs:
    milestone_logs: list holding each phase's learned weights and (flattened) successor matrix
    milestone_labels: list holding the simulation number and current phase for each row
    sim_num: Number of the current simulation
    phase: String describing the current learning phase
    model_parameters: the components of a successor representation, in order:
        num_pairs: the number of state-action pairs
        feat: the successor matrix
        weight: the weight vector
Outputs:
    milestone logs, milestone labels: with new learning phase's values appended to the end
'''
def update_logs(milestone_logs, milestone_labels, sim_num, phase, model_parameters):
    num_pairs = 13
    num_states = 10
    v_state, t_counts, weight = model_parameters
    weights_flat = list_flatten(weight)

    for k in range(num_pairs):
        milestone_logs[k].append(weights_flat[k])
    for m in range(num_pairs):
        for n in range(int(len(milestone_logs) / num_pairs) - 1):
            milestone_logs[m*(int(len(milestone_logs) / num_pairs) - 1) + n + num_pairs].append(t_counts[m][n])
    milestone_labels[0].append(sim_num + 1)
    milestone_labels[1].append(phase)
    return milestone_logs, milestone_labels


'''
Simulates the test phase by comparing the action values of the two possible starting-state actions. The test state action is assumed to always be 
the higher-value choice
Input: model_parameters: the components of a successor representation, in order:
        num_pairs: the number of state-action pairs
        feat: the successor matrix
        weight: the weight vector
Output: preferred starting state action
'''
def test(model_parameters):
    v_state, t_counts, weight = model_parameters
    return np.argmax(v_state[0]) + 2
