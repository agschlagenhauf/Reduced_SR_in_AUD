#
# full_sr.py
#

'''
IMPLEMENTATION OF A SUCCESSOR REPRESENTATION AGENT USING TEMPORAL-DIFFERENCE LEARNING TO UPDATE WEIGHT VECTOR AND
SUCCESSOR MATRIX
'''

import numpy as np
import pandas as pd
import random as rd
from utilities import *

#
# Run Trial
#
def fit_single_trial(phase, trial_index, gamma, alpha, beta, end_state, start_state, actions, rewards, transitions, num_pairs, v_state, feat, weight):
    '''
    Simulates a single trial, from the given start state until the end state is reached.

    Arguments:
        gamma: the time discounting constant
        alpha: the learning rate constant
        beta: softmax inverse temperature
        end_state: terminal state
        start_state: state that the agent starts in
        actions: actions actually taken by participant across trials
        rewards: rewards actually received by participant across trials
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
            if ((phase == "learning") and (trial_index == 0)):
                # Determine the next state
                next_move = 0 # forced left choice
                next_state = transitions[current_state][next_move] - 1
                # Determine the second next state
                second_next_move = 0 # forced left choice
                second_next_state = transitions[next_state][second_next_move] - 1
            elif ((phase == "learning") and (trial_index == 1)):
                # Determine the next state
                next_move = 0  # forced left choice
                next_state = transitions[current_state][next_move] - 1
                # Determine the second next state
                second_next_move = 1  # forced right choice
                second_next_state = transitions[next_state][second_next_move] - 1
            elif ((phase == "learning") and (trial_index == 2)):
                # Determine the next state
                next_move = 1  # forced right choice
                next_state = transitions[current_state][next_move] - 1
                # Determine the second next state
                second_next_move = 0  # forced left choice
                second_next_state = transitions[next_state][second_next_move] - 1
            elif ((phase == "learning") and (trial_index == 3)):
                # Determine the next state
                next_move = 1  # forced right choice
                next_state = transitions[current_state][next_move] - 1
                # Determine the second next state
                second_next_move = 1  # forced right choice
                second_next_state = transitions[next_state][second_next_move] - 1
            else:
                # Determine the next state
                next_move_index = get_flattened_index(transitions, current_state,0)
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

            # Store the log probability of the observed action
            logp_action_pair = log_prob(beta, next_values)
            logp_all_actions[t] = logp_action_pair[next_move]

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
            weight += alpha * weight_delta * feat_scaled

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
                                     last_move)] += alpha * feat_delta

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)] - \
                           v_state[get_flattened_index(transitions, current_state, next_move)]
            # scale feature according to Russek et al. 2017
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] / np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)],
                np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )
            weight += alpha * weight_delta * feat_scaled

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
            feat[get_flattened_index(transitions, last_state, last_move)] += alpha * feat_delta
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
            weight += alpha * weight_delta * feat_scaled
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

    return v_state, feat, weight, -np.sum(logp_all_actions[1:])


#
# Learning
#
def fit_all_trials(condition_data, parameter_estimates, model_structures):
    '''
    Simulates the learning phase, where the agent has access to the starting state.

    Arguments:
        - gamma: the time discounting constant
        - alpha: the learning rate constant
        - beta: softmax inverse temperature
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
    alpha, beta, gamma = parameter_estimates
    num_pairs, v_state, feat, weight = model_structures
    logp_condition = np.zeros(len(condition_data))
    phase = "learning"

    # Get start states
    start_states = pd.to_numeric(condition_data.drop_duplicates(subset='trial', keep='first')["state"])

    # Fit single trials
    for trial_index, start_state in enumerate(start_states):

        # Get actions and rewards in current trial
        states = condition_data["state"][condition_data["trial"] == trial_index+1]
        actions = condition_data["choice"][condition_data["trial"] == trial_index+1]
        rewards = condition_data["reward"][condition_data["trial"] == trial_index+1]

        v_state, feat, weight = run_trial(
            phase,
            trial_index,
            gamma,
            alpha,
            beta,
            end_state,
            start_state,
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

    return logp_condition, parameter_estimates
