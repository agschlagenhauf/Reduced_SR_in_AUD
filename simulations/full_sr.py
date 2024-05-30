#
# full_sr.py
#

import numpy as np
import random as rd
from utilities import *

#
# Run Trial
#
def run_trial(gamma, alpha, explore_chance, end_state, start_state, rewards, transitions, num_pairs, feat, weight):
    '''
    Simulates a single trial, from the given start state until an end state is reached.

    Arguments:
        gamma: the time discounting constant
        alpha: the learning rate constant
        explore_chance: probability that the agent will choose a random action instead of the highest-value one
        end_state: terminal state
        start_state: state that the agent starts in
        rewards: list of rewards corresponding to each action
        transitions: list of valid transitions from each state
        num_pairs: the number of state-action pairs
        feat: the successor matrix
        weight: the weight vector

    Returns: (
        - feat: value updated after the current trial
        - weight: value updated after the current trial
        - transition_log_lines: [str]
    )
    '''
    # For every state-action pair, append value
    # 13 Q-values (1 for each state-action pair) based on dot product of weight vector and successor matrix
    v_state = []
    for k in range(num_pairs):
        v_state.append(np.sum(weight * feat[k]))
    
    current_state = start_state - 1 # index starting at 0
    transition_log_lines = [] # all transitions per trial

    while True:
        if (current_state + 1) == start_state:
            # Determine the next state, either a random subsequent state or the highest-value subsequent state, depending on the exploration parameter
            next_move_index = get_flattened_index(transitions, current_state, 0)  # get index of element in transitions correpsonding to current state
            next_values = v_state[next_move_index:(next_move_index + len(transitions[current_state]))]  # get V for all state-action pairs available from current state (indexing not inclusive)

            # If the next action values are all the same we also choose randomly to avoid argmax defaulting to the first action
            if np.random.uniform() < explore_chance or np.all([i == next_values[0] for i in next_values]):
                next_move = np.random.randint(len(transitions[current_state]))
            else:
                next_move = np.argmax(next_values)  # get index of max value

            next_state = transitions[current_state][next_move] - 1  # get next state

            # Determine the action taken from the NEXT state, either the best action or a random one, depending on the exploration parameter
            # By having a random explore chance, we ensure that the successor matrix represents all possible successor actions, but has larger values for the
            # highest-reward ones.
            second_next_move_index = get_flattened_index(transitions, next_state, 0)
            second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[next_state]))]  # get V for all state-action pairs available from next state (indexing not inclusive)

            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)

            second_next_state = transitions[next_state][second_next_move] - 1  # get next state

            # Update weights with TD learning
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)] - v_state[get_flattened_index(transitions, current_state, next_move)]

            # scale feature according to Russek et al. 2017
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)], np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )

            weight += alpha * weight_delta * feat_scaled

            # Update value of current state-action pair based on updated weight and initial feature vector
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])

            # Transition log line: state,action,reward,weight_delta,{values},{weights},{flattened_features}
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(feat))}"
            )

            # Move to the next state
            last_state = current_state
            last_move = next_move
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

        elif (current_state + 1) != end_state:
            # Determine the action taken from the NEXT state, either the best action or a random one, depending on the exploration parameter
            # By having a random explore chance, we ensure that the successor matrix represents all possible successor actions, but has larger values for the
            # highest-reward ones.
            second_next_move_index = get_flattened_index(transitions, next_state, 0)
            second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[next_state]))]  # get V for all state-action pairs available from next state (indexing not inclusive)

            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)

            second_next_state = transitions[next_state][second_next_move] - 1  # get next state

            # Update the current state's row of the successor matrix with TD learning
            # Theoretically happens when next state is reached
            # The learning rate for the feature vector is lower than for the weights so that the occupancies from previous trials
            # stay mostly intact if a different action is chosen, even with a high alpha

            # Create vector with all zeros except the position of the current state-action pair
            # (an action is always considered to succeed itself)
            one_hot = np.zeros(num_pairs)
            one_hot[get_flattened_index(transitions, last_state, last_move)] = 1

            feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[get_flattened_index(transitions, last_state, last_move)]
            
            feat[get_flattened_index(transitions, last_state, last_move)] += alpha * feat_delta  # adapt SR learning rate here

            # Update weights with TD learning
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)] - v_state[get_flattened_index(transitions, current_state, next_move)]

            # scale feature according to Russek et al. 2017
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)], np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )

            weight += alpha * weight_delta * feat_scaled

            # Update value of current state-action pair based on updated weight and current feature vector
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])

            # Transition log line: state,action,reward,weight_delta,{values},{weights},{flattened_features}
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(feat))}"
            )

            # Move to the next state
            last_state = current_state
            last_move = next_move
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

        elif (current_state + 1) == end_state:
            # Update the current state's row of the successor matrix with TD learning
            # Theoretically happens when next state is reached
            # The learning rate for the feature vector is lower than for the weights so that the occupancies from previous trials
            # stay mostly intact if a different action is chosen, even with a high alpha

            # Create vector with all zeros except the position of the current state-action pair
            # (an action is always considered to succeed itself)
            one_hot = np.zeros(num_pairs)
            one_hot[get_flattened_index(transitions, last_state, last_move)] = 1

            feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[
                get_flattened_index(transitions, last_state, last_move)]

            feat[get_flattened_index(transitions, last_state,
                                     last_move)] += alpha * 0.25 * feat_delta  # adapt SR learning rate here

            # Update weights with TD learning
            reward = rewards[current_state][next_move]
            weight_delta = reward - v_state[
                get_flattened_index(transitions, current_state, next_move)]  # no discounted value of next state

            # scale feature according to Russek et al. 2017
            feat_scaled = safe_divide(feat[get_flattened_index(transitions, current_state, next_move)], np.matmul(feat[get_flattened_index(transitions, current_state, next_move)], np.transpose(feat[get_flattened_index(transitions, current_state, next_move)]))
                                      )
            weight += alpha * weight_delta * feat_scaled

            # Update value of current state-action pair based on updated weight and current feature vector
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])

            # Transition log line: state,action,reward,weight_delta,{values},{weights},{flattened_features}
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(feat))}"
            )

            # end loop
            break
        else:
            assert False

    return feat, weight, transition_log_lines

#
# Learning
#
def learning(gamma, alpha, explore_chance, end_state, rewards, transitions, model_parameters):
    '''
    Simulates the learning phase, where the agent has access to the starting state.

    Arguments:
        - gamma: the time discounting constant
        - alpha: the learning rate constant
        - explore_chance: probability that the agent will choose a random action instead of the highest-value one
        - end_state: terminal state
        - rewards: list of rewards corresponding to each action
        - transitions: list of valid transitions from each state
        - model_parameters: [
            - num_pairs: the number of state-action pairs
            - feat: the successor matrix (should generally be initialized with zeros)
            - weight: the weight vector (also generally initialized with zeros)
        ]

    Returns: (
        - model_parameters: [
            - num_pairs: the number of state-action pairs
            - feat: the successor matrix
            - weight: the weight vector
        ]
        - transition_log: [str]
    )
    '''
    num_pairs, feat, weight = model_parameters

    # Create start states
    start_states_1 = np.array([1, 1])

    start_states_2 = np.array([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9])
    np.random.shuffle(start_states_2)

    start_states_3 = np.array([1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3])
    np.random.shuffle(start_states_3)

    start_states = np.concatenate([start_states_1, start_states_2, start_states_3])

    # Run trials
    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        feat, weight, transition_log_lines = run_trial(
            gamma,
            alpha,
            explore_chance,
            end_state,
            start_state,
            rewards,
            transitions,
            num_pairs,
            feat,
            weight
        )
        
        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [num_pairs, feat, weight]
        
    return new_params, transition_log

#
# Relearning
#
def update_parameters(condition, rewards, transitions):
    if condition == "reward":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [40], [0], [30], [0]]
    elif condition == "transition":
        transitions = [[2, 3], [5, 6], [4, 5], [7], [8], [9], [10], [10], [10], [11]]
    elif condition == "policy":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [40], [20], [30], [0]]
    elif condition == "goal":
        rewards = [[0, 0], [0, 0], [0, 0], [20], [0], [0], [20], [0], [30], [0]]
    else:
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [20], [0], [40], [0]]

    return rewards, transitions

def relearning(condition, gamma, alpha, explore_chance, end_state, rewards, transitions, model_parameters):
    '''
    Simulates the relearning phase, where the agent does not directly experience the starting state.

    Arguments:
        - condition: string representing the relearning condition
        - gamma: the time discounting constant
        - alpha: the learning rate constant
        - explore_chance: probability that the agent will choose a random action instead of the highest-value one
        - end_state: terminal state
        - rewards: list of rewards corresponding to each action
        - transitions: list of valid transitions from each state
        - model parameters: [
            - num_pairs: the number of state-action pairs
            - feat: the successor matrix, held over from learning
            - weight: the weight vector, held over from learning
        ]

    Returns: (
        - model_parameters: [
            - num_pairs: the number of state-action pairs
            - feat: the successor matrix
            - weight: the weight vector
        ]
        - transition_log: [str]
    )
    '''
    num_pairs, feat, weight = model_parameters

    # Create start states
    if condition == "transition":
        start_states = np.array([2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9])
    elif condition == "goal":
        start_states = np.array([4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 9, 9])
    else:
        start_states = np.array([7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9])

    np.random.shuffle(start_states)

    # Run trials
    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        feat, weight, transition_log_lines = run_trial(
            gamma,
            alpha,
            explore_chance,
            end_state,
            start_state,
            rewards,
            transitions,
            num_pairs,
            feat,
            weight
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [num_pairs, feat, weight]
        
    return new_params, transition_log

#
# Test
#
def test(model_parameters):
    '''
    Simulates the test phase by comparing the action values of the two possible starting-state actions. The test state action is assumed to always be 
    the higher-value choice.

    Arguments:
        - model_parameters: [
            - num_pairs: the number of state-action pairs
            - feat: the successor matrix, held over from learning
            - weight: the weight vector, held over from learning
        ]

    Returns: (
        - action: int, (1 = left, 2 = right)
        - transition_log: [str]
    )
    '''
    num_pairs, feat, weight = model_parameters
    v_state = np.zeros(num_pairs)

    for k in range(num_pairs):
        v_state[k] = np.sum(weight * feat[k])

    action_index = np.argmax(v_state[0:2])

    if action_index == 0:
        action = ACTION_LEFT
    elif action_index == 1:
        action = ACTION_RIGHT
    else:
        raise ValueError

    # Transition log_line: trial,state,action,reward
    transition_log_line = f"1,1,{action},0,,{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(feat))}"

    return action, [transition_log_line]
