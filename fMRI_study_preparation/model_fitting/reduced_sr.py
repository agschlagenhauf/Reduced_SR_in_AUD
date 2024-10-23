#
# reduced_sr.py
#

'''
IMPLEMENTATION OF A RIGID, GOAL-BASED, REDUCED SUCCESSOR REPRESENTATION AGENT USING TEMPORAL-DIFFERENCE LEARNING TO UPDATE WEIGHT VECTOR AND SUCCESSOR VECTOR
'''

import numpy as np
import random as rd
from utilities import *

def reduce_weight_and_feat(feat, weight, rewards):
    '''
    Deletes all columns of the successor matrix and the reward vector
    that don't correspond to a reward-giving action, converting a full to a reduced successor matrix

    Arguments:
        - sr: the full successor matrix
        - rewards: list rewards for each state and action
        - num_pairs: the number of state-action pairs

    Returns:
        - reduced_sr: the reduced successor matrix
        - reduced_weight: the reduced weight vector

    '''
    reduced_sr = []
    reduced_weight = []

    flattened_rewards = flatten(rewards)

    for i, reward in enumerate(flattened_rewards):
        if reward != 0:
            non_zero_feat_column = feat[:,i]
            reduced_sr.append(non_zero_feat_column)
            non_zero_weight = weight[i]
            reduced_weight.append(non_zero_weight)

    return np.transpose(reduced_sr), reduced_weight


def run_trial(phase, trial_index, gamma, alpha, beta, end_state, start_state, rewards, transitions, num_pairs, v_state, feat, weight):
    '''
    Simulates a single trial, from the given start state until the end state is reached.

    Arguments:
        gamma: the time discounting constant
        alpha: the learning rate constant
        beta: softmax inverse temperatureend_state: terminal state
        start_state: state that the agent starts in
        rewards: list of rewards corresponding to each action
        transitions: list of valid transitions from each state
        num_pairs: the number of state-action pairs
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
            ###### Determine next and second next state ######
            if ((phase == "learning") and (trial_index == 0)):
                # Determine the next state
                next_move = 0  # forced left choice
                next_state = transitions[current_state][next_move] - 1
                # Determine the second next state
                second_next_move = 0  # forced left choice
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

            ###### No update of successor matrix in first state, as we did not transition from anywhere ######

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[get_flattened_index(transitions, next_state, second_next_move)] - \
                           v_state[get_flattened_index(transitions, current_state, next_move)]
            # scale feature according to Russek et al. 2017
            denominator = np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)],
                np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )

            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] * safe_divide(1, denominator)

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

            ###### Determine second next state ######
            # Next state determined in last state visit
            # Determine second next state
            second_next_move_index = get_flattened_index(transitions, next_state, 0)
            second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[next_state]))]
            if len(second_next_values) == 1:
                second_next_move = 0
            else:
                second_next_choice_probs = softmax(beta, second_next_values)
                second_next_move = rng.choice([0, 1], p=second_next_choice_probs)
            second_next_state = transitions[next_state][second_next_move] - 1

            ###### Update the successor matrix row correpsonding to last state ONLY during learning for rigid SR ######
            if phase == "learning":
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
            denominator = np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)],
                np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] * safe_divide(1, denominator)

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

            ###### If learning phase: Update the successor matrix row correpsonding to last state (Rigid red SR during re-learning ######
            if phase == "learning":
                one_hot = np.zeros(num_pairs)
                one_hot[get_flattened_index(transitions, last_state, last_move)] = 1
                feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[
                    get_flattened_index(transitions, last_state, last_move)]
                feat[get_flattened_index(transitions, last_state, last_move)] += alpha * feat_delta

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward - v_state[get_flattened_index(transitions, current_state, next_move)]
            # scale feature according to Russek et al. 2017
            denominator = np.matmul(
                feat[get_flattened_index(transitions, current_state, next_move)],
                np.transpose(feat[get_flattened_index(transitions, current_state, next_move)])
            )
            feat_scaled = feat[get_flattened_index(transitions, current_state, next_move)] * safe_divide(1, denominator)

            weight += alpha * weight_delta * feat_scaled

            ###### Update values of all state-action pairs ######
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
def learning(gamma, alpha, beta, end_state, rewards, transitions, model_parameters):
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
    num_pairs, v_state, feat, reduced_feat, weight, reduced_weight = model_parameters
    phase = "learning"

    # Create start states
    start_states = np.ones(30, dtype=np.int8)

    # Run trials
    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        v_state, feat, weight, transition_log_lines = run_trial(
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

    # create reduced SR
    reduced_feat, reduced_weight = reduce_weight_and_feat(feat, weight, rewards)

    new_params = [num_pairs, v_state, feat, reduced_feat, weight, reduced_weight]
        
    return new_params, transition_log

#
# Relearning
#
def update_parameters(condition, rewards, transitions):
    if condition == "reward":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [45], [0], [30], [0]]
    elif condition == "transition":
        transitions = [[2, 3], [4, 5], [5, 6], [9], [7], [8], [10], [10], [10], [11]]
    elif condition == "policy":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [45], [15], [30], [0]]
    elif condition == "goal":
        rewards = [[0, 0], [0, 0], [0, 0], [45], [0], [0], [15], [0], [30], [0]]
    else:
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [15], [0], [45], [0]]

    return rewards, transitions


def relearning(condition, gamma, alpha, beta, end_state, rewards, transitions, model_parameters):
    '''
    Simulates the relearning phase, where the agent does not directly experience the starting state.

    Arguments:
        - condition: string representing the relearning condition
        - gamma: the time discounting constant
        - alpha: the learning rate constant
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
    num_pairs, v_state, feat, reduced_feat, weight, reduced_weight = model_parameters
    phase = "relearning"

    # Create start states
    start_states = np.array([4, 4, 4, 5, 5, 5, 6, 6, 6])
    np.random.shuffle(start_states)

    # Run trials
    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        v_state, reduced_feat, reduced_weight, transition_log_lines = run_trial(
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
            reduced_feat,
            reduced_weight
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [num_pairs, v_state, feat, reduced_feat, weight, reduced_weight]
        
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
    num_pairs, v_state, feat, reduced_feat, weight, reduced_weight = model_parameters

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