import numpy as np
import random as rd

def list_flatten(list):
    return [item for row in list for item in row]

def get_flattened_index(list, row, item):
    index = 0
    for i in range(row):
        index += len(list[i])
    index += item
    return index

def clear_non_goal_occupancies(sr, rewards, num_pairs):
    for i in range(len(rewards)):
        for j in range(len(rewards[i])):
            if rewards[i][j] == 0:
                sr[:, get_flattened_index(rewards, i, j)] = np.zeros(num_pairs)
    return sr


def reduced_successor_episode(gamma, alpha, explore_chance, end_states, start_state, rewards, transitions, num_pairs, feat, weight, state_list, action_list, RPE_list, value_list):
    time_step = 1
    
    # Initial state value (will also be zeros)
    v_state = []
    for k in range(num_pairs):
        v_state.append(np.sum(weight*feat[k]))
        
    current_state = start_state - 1
    timestep_list = []
    not_end = True
    end_states_adjusted = [i-1 for i in end_states]
    
    while not_end:
        if current_state in end_states_adjusted:
            not_end = False
            break
        
        else:
            # Determine the next state, either a random subsequent state or the highest-value subsequent state, depending on the exploration parameter
            if np.random.uniform() < explore_chance:
                next_move = np.random.randint(len(transitions[current_state]))
            else:
                next_move_index = get_flattened_index(transitions, current_state, 0)
                next_values = v_state[next_move_index:(next_move_index+len(transitions[current_state]))]
                next_move = np.argmax(next_values)

            next_state = transitions[current_state][next_move] - 1

            # Determine the best action to take from the NEXT state, used to calculate the one-hot vector for updating the successor matrix
            next_move_index = get_flattened_index(transitions, next_state, 0)
            next_values = v_state[next_move_index:(next_move_index+len(transitions[next_state]))]

            # Occasionally assume a random next move as the immediate successor instead of the best next move.
            # This way the successor matrix will reflect all possible successor states but have larger values for the highest-reward ones
            # This is important for the policy reevaluation condition
            best_next_move = np.argmax(next_values) + next_move_index
            random_next_move = np.random.randint(len(transitions[next_state])) + next_move_index
            if np.random.uniform() < explore_chance:
                next_move_one_hot = random_next_move
            else:
                next_move_one_hot = best_next_move

            # Get reward
            reward = rewards[current_state][next_move]

            weight_delta = reward - weight[get_flattened_index(rewards, current_state, next_move)]

            weight[get_flattened_index(rewards, current_state, next_move)] += alpha * weight_delta

            one_hot = np.zeros(num_pairs)

            one_hot[get_flattened_index(transitions, current_state, next_move)] = 1

            feat_delta = one_hot + gamma * feat[next_move_one_hot] - feat[get_flattened_index(transitions, current_state, next_move)]

            feat[get_flattened_index(transitions, current_state, next_move)] += alpha * feat_delta

            feat = clear_non_goal_occupancies(feat, rewards, num_pairs)
            
            
            # update state value
            for k in range(num_pairs):
                v_state[k] = np.sum(weight*feat[k])
            
            state_list.append(current_state + 1)
            action_list.append(next_state + 1)
            RPE_list.append(weight_delta)
            timestep_list.append(time_step)
            
            for k in range(num_pairs):
                value_list[k].append(v_state[k])
            
            # Move to the next state
            current_state = next_state
            
            time_step += 1

    return feat, weight, state_list, action_list, RPE_list, value_list, timestep_list


def pretraining(gamma, alpha, explore_chance, end_states, rewards, transitions, model_parameters, logging_lists):
    num_pairs, feat, weight = model_parameters
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    # Create the list of starting states, randomly ordered, but guaranteed a certain number of starts in each starting state
    start_states = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 5, 5, 6, 6])
    start_states= np.append(start_states, np.random.randint(1, 7, 5))
    np.random.shuffle(start_states)
    for index, k in enumerate(start_states):
        c_feat, c_weight, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        reduced_successor_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, num_pairs, feat, weight, state_list, action_list, RPE_list, value_list)

        # Update the logs that depend on the length of the current episode
        for j in range(len(timestep_list)):
            epi_num_list.append(index+1)
            epi_length.append(index+1)
            phase_list.append(1)

        feat = c_feat
        weight = c_weight
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        value_list = c_value_list

    logs_new = [c_state_list, c_action_list, c_RPE_list, epi_num_list, phase_list]
    logs_new.append(value_list)
    new_params = [num_pairs, feat, weight]
        
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
        rewards = [[0, 0], [0, 0], [0, 0], [45], [0], [30], [0], [0], [0], [0], [0], [0]]
    elif condition == "Transition":
        transitions = [[2, 3], [5, 6], [4, 5], [7], [8], [9], [10], [11], [12], [], [], []]
    elif condition == "Policy":
        rewards = [[0, 0], [0, 0], [0, 0], [45], [15], [30], [0], [0], [0], [0], [0], [0]]
    elif condition == "Goal":
        rewards = [[0, 0], [0, 0], [0, 0], [15], [0], [30], [30], [0], [0], [0], [0], [0]]
    return rewards, transitions


def retraining(condition, gamma, alpha, explore_chance, end_states, rewards, transitions, model_parameters, logging_lists):
    num_pairs, feat, weight = model_parameters
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    if condition == "Transition":
        start_states = np.array([2, 2, 2, 3, 3, 3, 4, 5, 6])
    else:
        start_states = np.array([4, 4, 4, 5, 5, 5, 6, 6, 6])
    np.random.shuffle(start_states)
    for index, k in enumerate(start_states):
        c_feat, c_weight, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        reduced_successor_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, num_pairs, feat, weight, state_list, action_list, RPE_list, value_list)

        # Update the logs that depend on the length of the current episode
        for j in range(len(timestep_list)):
            epi_num_list.append(index+1)
            epi_length.append(index+1)
            phase_list.append(2)

        feat = c_feat
        weight = c_weight
        state_list = c_state_list
        action_list = c_action_list
        RPE_list = c_RPE_list
        value_list = c_value_list

    logs_new = [c_state_list, c_action_list, c_RPE_list, epi_num_list, phase_list]
    logs_new.append(value_list)
    new_params = [num_pairs, feat, weight]
        
    return new_params, logs_new, epi_length


def test(model_parameters):
    num_pairs, feat, weight = model_parameters
    v_state = np.zeros(num_pairs)
    for k in range(num_pairs):
        v_state[k] = np.sum(weight*feat[k])
    return np.argmax(v_state[0:2]) + 2