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
def successor_episode(gamma, alpha, explore_chance, end_states, start_state, rewards, transitions, num_pairs, feat, weight, state_list, action_list, RPE_list, value_list):
    time_step = 1

    
    # For every state-action pair, append value
    # 13 Q-values (1 for each state-action pair) based on dot product of weight vector and successor matrix
    v_state = []
    for k in range(num_pairs):
        v_state.append(np.sum(weight*feat[k]))
        
    current_state = start_state - 1 # index starting at 0
    timestep_list = []
    not_end = True
    end_states_adjusted = [i-1 for i in end_states] # index starting at 0
    
    while not_end:
        if current_state in end_states_adjusted: # end loop when end state reached
            not_end = False
            break

        elif current_state == start_state - 1:
            print(f"time_step: {time_step}")
            print(f"current_state: {current_state}")
            print(f"v_state: {v_state}")
            # Determine the next state, either a random subsequent state or the highest-value subsequent state, depending on the exploration parameter
            next_move_index = get_flattened_index(transitions, current_state,
                                                  0)  # get index of element in transitions correpsonding to current state
            next_values = v_state[next_move_index:(next_move_index + len(transitions[
                                                                             current_state]))]  # get V for all state-action pairs available from current state (indexing not inclusive)
            # If the next action values are all the same we also choose randomly to avoid argmax defaulting to the first action
            if np.random.uniform() < explore_chance or np.all([i == next_values[0] for i in next_values]):
                next_move = np.random.randint(len(transitions[current_state]))
            else:
                next_move = np.argmax(next_values)  # get index of max value
            print(f"next_move: {next_move}")

            next_state = transitions[current_state][next_move] - 1  # get next state
            print(f"next_state: {next_state}")

            # Determine the action taken from the NEXT state, either the best action or a random one, depending on the exploration parameter
            # By having a random explore chance, we ensure that the successor matrix represents all possible successor actions, but has larger values for the
            # highest-reward ones.
            second_next_move_index = get_flattened_index(transitions, next_state, 0)
            second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[
                                                                                                  next_state]))]  # get V for all state-action pairs available from next state (indexing not inclusive)
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)
            print(f"second_next_move: {second_next_move}")

            second_next_state = transitions[next_state][second_next_move] - 1  # get next state

            # Update weights with TD learning
            reward = rewards[current_state][next_move]
            weight_delta = (reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)]
                            - v_state[get_flattened_index(transitions, current_state, next_move)])
            print(
                f"reward:{reward}, gamma: {gamma}, v_state[get_flattened_index(transitions, next_state, second_next_move)]: {v_state[get_flattened_index(transitions, next_state, second_next_move)]}, v_state[get_flattened_index(transitions, current_state, next_move)]: {v_state[get_flattened_index(transitions, current_state, next_move)]}")  # reward in current state + discounted value of next state - value of current state
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)], np.transpose(feat[get_flattened_index(
                    transitions, current_state, next_move)]))  # scale feature according to Russek et al. 2017
            print(f"feat_scaled: {feat_scaled}")

            weight += alpha * weight_delta * feat_scaled
            print(f"weight: {weight}")

            # Update value of current state-action pair based on updated weight and initial feature vector
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])
            print(f"v_state: {v_state}")

            state_list.append(current_state + 1)
            action_list.append(next_state + 1)
            RPE_list.append(weight_delta)
            timestep_list.append(time_step)

            for k in range(num_pairs):
                value_list[k].append(v_state[k])

            # Move to the next state
            last_state = current_state
            last_move = next_move
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

            time_step += 1

        else:
            print(f"time_step: {time_step}")
            print(f"current_state: {current_state}")
            print(f"v_state: {v_state}")

            # Determine the action taken from the NEXT state, either the best action or a random one, depending on the exploration parameter
            # By having a random explore chance, we ensure that the successor matrix represents all possible successor actions, but has larger values for the
            # highest-reward ones.
            second_next_move_index = get_flattened_index(transitions, next_state, 0)
            second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[
                                                                                                  next_state]))]  # get V for all state-action pairs available from next state (indexing not inclusive)
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)
                print(f"second_next_move: {second_next_move}")

            second_next_state = transitions[next_state][second_next_move] - 1  # get next state

            # Update the current state's row of the successor matrix with TD learning
            # Theoretically happens when next state is reached
            # The learning rate for the feature vector is lower than for the weights so that the occupancies from previous episodes
            # stay mostly intact if a different action is chosen, even with a high alpha

            # Create vector with all zeros except the position of the current state-action pair
            # (an action is always considered to succeed itself)
            one_hot = np.zeros(num_pairs)
            one_hot[get_flattened_index(transitions, last_state, last_move)] = 1
            print(f"one_hot: {one_hot}")

            feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[
                get_flattened_index(transitions, last_state, last_move)]
            print(f"feat_delta: {feat_delta}")
            feat[get_flattened_index(transitions, last_state,
                                     last_move)] += alpha * 0.25 * feat_delta  # adapt SR learning rate here
            print(f"feat[current_state]: {feat[get_flattened_index(transitions, last_state, last_move)]}")

            # Update weights with TD learning
            reward = rewards[current_state][next_move]
            weight_delta = (reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)]
                            - v_state[get_flattened_index(transitions, current_state, next_move)])
            print(
                f"reward:{reward}, gamma: {gamma}, v_state[get_flattened_index(transitions, next_state, second_next_move)]: {v_state[get_flattened_index(transitions, next_state, second_next_move)]}, v_state[get_flattened_index(transitions, current_state, next_move)]: {v_state[get_flattened_index(transitions, current_state, next_move)]}")  # reward in current state + discounted value of next state - value of current state
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)], np.transpose(feat[get_flattened_index(
                    transitions, current_state, next_move)]))  # scale feature according to Russek et al. 2017
            print(f"feat_scaled: {feat_scaled}")

            weight += alpha * weight_delta * feat_scaled
            print(f"weight: {weight}")

            # Update value of current state-action pair based on updated weight and current feature vector
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])
            print(f"v_state: {v_state}")

            state_list.append(current_state + 1)
            action_list.append(next_state + 1)
            RPE_list.append(weight_delta)
            timestep_list.append(time_step)

            for k in range(num_pairs):
                value_list[k].append(v_state[k])

            # Move to the next state
            last_state = current_state
            last_move = next_move
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

            time_step += 1

    return feat, weight, state_list, action_list, RPE_list, value_list, timestep_list


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
    num_pairs, feat, weight = model_parameters
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    # Create the list of starting states, randomly ordered, but guaranteed a certain number of starts in each starting state
    #start_states = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 5, 5, 6, 6])
    start_states_1 = np.array([1, 1])
    start_states_2 = np.array([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10])
    np.random.shuffle(start_states_2)
    start_states_3 = np.array([1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3])
    np.random.shuffle(start_states_3)
    start_states = np.append(start_states_1, start_states_2)
    start_states = np.append(start_states, start_states_3)
    print(f"start_states: {start_states}")
    for index, k in enumerate(start_states):
        c_feat, c_weight, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        successor_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, num_pairs, feat, weight, state_list, action_list, RPE_list, value_list)

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
    num_pairs, feat, weight = model_parameters
    state_list, action_list, RPE_list, epi_num_list, phase_list = logging_lists[0:5]
    value_list = logging_lists[5:][0]
    epi_length = []
    if condition == "Transition":
        #start_states = np.array([2, 2, 2, 3, 3, 3, 4, 5, 6])
        start_states = np.array([2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3])
    else:
        start_states = np.array([7, 7, 7, 7, 8, 8, 8, 8, 9, 9, 9, 9])
    np.random.shuffle(start_states)
    for index, k in enumerate(start_states):
        c_feat, c_weight, c_state_list, c_action_list, c_RPE_list, c_value_list, timestep_list = \
        successor_episode(gamma, alpha, explore_chance, end_states, k, rewards, transitions, num_pairs, feat, weight, state_list, action_list, RPE_list, value_list)

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
    num_pairs, feat, weight = model_parameters
    for k in range(num_pairs):
        milestone_logs[k].append(weight[k])
    for m in range(num_pairs):
        for n in range(num_pairs):
            milestone_logs[m*num_pairs + n + num_pairs].append(feat[m][n])
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
    num_pairs, feat, weight = model_parameters
    v_state = np.zeros(num_pairs)
    for k in range(num_pairs):
        v_state[k] = np.sum(weight*feat[k])
    return np.argmax(v_state[0:2]) + 2
