#
# full_sr.py
#

'''
IMPLEMENTATION OF A SUCCESSOR REPRESENTATION AGENT USING TEMPORAL-DIFFERENCE LEARNING TO UPDATE WEIGHT VECTOR AND
SUCCESSOR MATRIX
'''

import numpy as np
import random as rd
from utilities import *

#
# Run Trial
#
def run_trial(phase, trial_index, gamma, alpha_td, alpha_m, beta, end_state, start_state, forced_choice_switch, forced_choice_trial_order, rewards, transitions, num_pairs, v_state, feat, weight):
    '''
    Simulates a single trial, from the given start state until the end state is reached.

    Arguments:
        gamma: the time discounting constant
        alpha_m: the learning rate constant used to learn the SR matrix M
        alpha_td: the learning rate constant used to learn the weight vector
        beta: softmax inverse temperature
        end_state: terminal state
        start_state: state that the agent starts in
        forced_choice_switch: include forced choice trials during learning or not
        forced_choice_trial_order: random order of forced choice trials in the beginning
        rewards: list of rewards corresponding to each action
        transitions: list of valid transitions from each state
        num_pairs: the number of state-action pairs
        v_state: value of all state-action pairs
        feat: the successor matrix
        weight: the weight vector

    Returns: (
        - feat: successor matrix updated after the current trial
        - weight: weight vector updated after the current trial
        - transition_log_lines: [str]
    )
    '''

    current_state = start_state - 1
    transition_log_lines = []

    while True:

        ###### First state ######
        if (current_state + 1) == start_state:

            ###### Determine next and second next state ######
            
            # if forced choice trials included in learning phase
            if forced_choice_switch == True:
            
                ## 4 forced-choice trials
                if (trial_index == forced_choice_trial_order[0]):
                    # Determine the next state
                    next_move = 0 # forced left choice
                    next_state = transitions[current_state][next_move] - 1
                    # Determine the second next state
                    second_next_move = 0 # forced left choice
                    second_next_state = transitions[next_state][second_next_move] - 1
                elif (trial_index == forced_choice_trial_order[1]):
                    # Determine the next state
                    next_move = 0  # forced left choice
                    next_state = transitions[current_state][next_move] - 1
                    # Determine the second next state
                    second_next_move = 1  # forced right choice
                    second_next_state = transitions[next_state][second_next_move] - 1
                elif (trial_index == forced_choice_trial_order[2]):
                    # Determine the next state
                    next_move = 1  # forced right choice
                    next_state = transitions[current_state][next_move] - 1
                    # Determine the second next state
                    second_next_move = 0  # forced left choice
                    second_next_state = transitions[next_state][second_next_move] - 1
                elif (trial_index == forced_choice_trial_order[3]):
                    # Determine the next state
                    next_move = 1  # forced right choice
                    next_state = transitions[current_state][next_move] - 1
                    # Determine the second next state
                    second_next_move = 1  # forced right choice
                    second_next_state = transitions[next_state][second_next_move] - 1
                
                ## free-choice trials of other index than 0-3
                else:
                    # Determine the next state
                    next_move_index = get_flattened_index(transitions, current_state, 0)
                    next_values = v_state[next_move_index:(next_move_index + len(transitions[current_state]))]
                    if len(next_values) == 1:
                        next_move = 0
                    else:
                        next_choice_probs = softmax(beta, next_values)
                        next_move = rng.choice([0, 1], p=next_choice_probs)
                    next_state = transitions[current_state][next_move] - 1
    
                    # Determine the second next state
                    second_next_move_index = get_flattened_index(transitions, next_state, 0)
                    second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[next_state]))]
                    if len(second_next_values) == 1:
                        second_next_move = 0
                    else:
                        second_next_choice_probs = softmax(beta, second_next_values)
                        second_next_move = rng.choice([0, 1], p=second_next_choice_probs)
                    second_next_state = transitions[next_state][second_next_move] - 1
            
            # if no forced choice trials during learning
            else:
                ## free-choice trials for all indices
                # Determine the next state
                next_move_index = get_flattened_index(transitions, current_state, 0)
                next_values = v_state[next_move_index:(next_move_index + len(transitions[current_state]))]
                if len(next_values) == 1:
                    next_move = 0
                else:
                    next_choice_probs = softmax(beta, next_values)
                    next_move = rng.choice([0, 1], p=next_choice_probs)
                next_state = transitions[current_state][next_move] - 1

                # Determine the second next state
                second_next_move_index = get_flattened_index(transitions, next_state, 0)
                second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[next_state]))]
                if len(second_next_values) == 1:
                    second_next_move = 0
                else:
                    second_next_choice_probs = softmax(beta, second_next_values)
                    second_next_move = rng.choice([0, 1], p=second_next_choice_probs)
                second_next_state = transitions[next_state][second_next_move] - 1
                    

            ###### No update of successor matrix in first state, as we did not transition from anywhere ######

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)] - \
                           v_state[get_flattened_index(transitions, current_state, next_move)]
            # scale feature according to Russek et al. 2017
            feat_scaled = (feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)],
                np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            ))
            weight += alpha_td * weight_delta * feat_scaled

            ###### Update values of all state-action pairs ######
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])

            ###### Fill in transition log line ######
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(feat))}"
            )

            ###### Move to the next state ######
            last_state = current_state
            last_move = next_move
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

        ###### Middle states ######
        elif (current_state + 1) != end_state:

            ###### Determine next and second next state ######
            # Next state determined in last state
            # Determine second next state
            second_next_move_index = get_flattened_index(transitions, next_state, 0)
            second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[next_state]))]
            if len(second_next_values) == 1:
                second_next_move = 0
            else:
                second_next_choice_probs = softmax(beta, second_next_values)
                second_next_move = rng.choice([0, 1], p=second_next_choice_probs)
            second_next_state = transitions[next_state][second_next_move] - 1

            ###### Update the successor matrix row correpsonding to last state ######
            one_hot = np.zeros(num_pairs)
            one_hot[get_flattened_index(transitions, last_state, last_move)] = 1
            feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[
                get_flattened_index(transitions, last_state, last_move)]
            feat[get_flattened_index(transitions, last_state,
                                     last_move)] += alpha_m * feat_delta

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)] - \
                           v_state[get_flattened_index(transitions, current_state, next_move)]
            # scale feature according to Russek et al. 2017
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)],
                np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )
            weight += alpha_td * weight_delta * feat_scaled

            ###### Update values of all state-action pairs ######
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])

            ###### Fill in transition log line ######
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(feat))}"
            )

            ###### Move to the next state ######
            last_state = current_state
            last_move = next_move
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

        ###### Last state ######
        elif (current_state + 1) == end_state:

            ###### Update the successor matrix row correpsonding to last state ######
            one_hot = np.zeros(num_pairs)
            one_hot[get_flattened_index(transitions, last_state, last_move)] = 1
            feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[
                get_flattened_index(transitions, last_state, last_move)]
            feat[get_flattened_index(transitions, last_state, last_move)] += alpha_m * feat_delta
            #print(f"feat delta: {feat_delta}")

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward - v_state[get_flattened_index(transitions, current_state, next_move)]
            #print(f"weight delta in state 10: {weight_delta}")
            # scale feature according to Russek et al. 2017
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)],
                np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )
            #print(f"weight before update: {weight}")
            #print(f"scaled feature in state 10: {feat_scaled}")
            weight += alpha_td * weight_delta * feat_scaled
            #print(f"weight update in state 10: {alpha * weight_delta * feat_scaled}")
            #print(f"weight after update: {weight}")

            ###### Update values of all state-action pairs ######
            #print(f"weight: {weight} \n"
            #      f"feature: {feat[k]}")
            for k in range(num_pairs):
                v_state[k] = np.sum(weight * feat[k])

            ###### Fill in transition log line ######
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(feat))}"
            )

            ###### End loop ######
            break

        else:
            assert False

    return v_state, feat, weight, transition_log_lines


#
# Learning
#
def learning(gamma, alpha_td, alpha_m, beta, end_state, rewards, transitions, model_parameters, forced_choice_switch):
    '''
    Simulates the learning phase, where the agent has access to the starting state.

    Arguments:
        - gamma: the time discounting constant
        - alpha_m: the learning rate constant used to learn the SR matrix M
        - alpha_td: the learning rate constant used to learn the weight vector
        - beta: softmax inverse temperature
        - end_state: terminal state
        - rewards: list of rewards corresponding to each action
        - transitions: list of valid transitions from each state
        - model_parameters: [
            - num_pairs: the number of state-action pairs
            - feat: the successor matrix (should generally be initialized with zeros)
            - weight: the weight vector (also generally initialized with zeros)
        - forced_choice_switch: include forced choice trials during learning or not
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
    num_pairs, v_state, feat, weight = model_parameters
    phase = "learning"

    # Create start states
    start_states = np.ones(24, dtype=np.int8)
    
    # Create random forced choice trials order
    forced_choice_trial_order = [0,1,2,3]
    rd.shuffle(forced_choice_trial_order)

    # Run trials
    transition_log = []

    for trial_index, start_state in enumerate(start_states):
        v_state, feat, weight, transition_log_lines = run_trial(
            phase,
            trial_index,
            gamma,
            alpha_td,
            alpha_m,
            beta,
            end_state,
            start_state,
            forced_choice_switch,
            forced_choice_trial_order,
            rewards,
            transitions,
            num_pairs,
            v_state,
            feat,
            weight
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [num_pairs, v_state, feat, weight]

    return new_params, transition_log

#
# Relearning
#
def update_parameters(condition, rewards, transitions):
    if condition == "reward":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [200], [0], [30], [0]]
    elif condition == "transition":
        transitions = [[2, 3], [4, 5], [5, 6], [9], [7], [8], [10], [10], [10], [11]]
    elif condition == "policy":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [200], [15], [30], [0]]
    elif condition == "goal":
        rewards = [[0, 0], [0, 0], [0, 0], [200], [0], [0], [15], [0], [30], [0]]
    else:
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [15], [0], [200], [0]]

    return rewards, transitions


def relearning(condition, gamma, alpha_td, alpha_m, beta, end_state, rewards, transitions, model_parameters):
    '''
    Simulates the relearning phase, where the agent does not directly experience the starting state.

    Arguments:
        - condition: string representing the relearning condition
        - gamma: the time discounting constant
        - alpha_m: the learning rate constant used to learn the SR matrix M
        - alpha_td: the learning rate constant used to learn the weight vector
        - beta: softmax inverse temperature
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
    num_pairs, v_state, feat, weight = model_parameters
    phase = "relearning"

    # Create start states
    start_states = np.array([4, 4, 4, 5, 5, 5, 6, 6, 6])
    np.random.shuffle(start_states)
    
    forced_choice_switch = False # never starts with forced 2-choice trials, as all trials are 1-choice anyways
    
    # Create empty forced choice trials order to fulfill input of run_trials
    forced_choice_trial_order = []

    # Run trials
    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        v_state, feat, weight, transition_log_lines = run_trial(
            phase,
            trial_index,
            gamma,
            alpha_td,
            alpha_m,
            beta,
            end_state,
            start_state,
            forced_choice_switch,
            forced_choice_trial_order,
            rewards,
            transitions,
            num_pairs,
            v_state,
            feat,
            weight
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [num_pairs, v_state, feat, weight]

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
    num_pairs, v_state, feat, weight = model_parameters

    action_index = np.argmax(v_state[0:2])

    if action_index == 0:
        action = ACTION_LEFT
    elif action_index == 1:
        action = ACTION_RIGHT
    else:
        raise ValueError

    # Transition log_line: trial,state,action,reward
    transition_log_line = f"1,1,{action},0"

    return action, [transition_log_line]