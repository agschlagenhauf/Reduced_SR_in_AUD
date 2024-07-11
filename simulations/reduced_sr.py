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
    Deletes all columns of the successor matrix that don't correspond to a reward-giving action, converting a full to a reduced successor matrix

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


def run_trial(phase, gamma, alpha, alpha_sr, explore_chance, end_state, start_state, rewards, transitions, num_pairs, v_state, feat, weight):
    '''
    Simulates a single trial, from the given start state until the end state is reached.

    Arguments:
        gamma: the time discounting constant
        alpha: the learning rate constant
        alpha_sr: the learning rate for SR
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
    current_state = start_state - 1
    transition_log_lines = []

    while True:

        ###### First state ######

        if (current_state + 1) == start_state:

            ###### Determine next and second next state ######
            # Determine the next state
            next_move_index = get_flattened_index(transitions, current_state,0)
            next_values = v_state[next_move_index:(next_move_index + len(transitions[current_state]))]
            if np.random.uniform() < explore_chance or np.all([i == next_values[0] for i in next_values]):
                next_move = np.random.randint(len(transitions[current_state]))
            else:
                next_move = np.argmax(next_values)
            next_state = transitions[current_state][next_move] - 1

            # Determine the second next state
            second_next_move_index = get_flattened_index(transitions, next_state, 0)
            second_next_values = v_state[second_next_move_index:(second_next_move_index + len(transitions[next_state]))]
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)
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
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)
            second_next_state = transitions[next_state][second_next_move] - 1

            if phase == "learning":
                ###### Update the successor matrix row correpsonding to last state ######
                one_hot = np.zeros(num_pairs)
                one_hot[get_flattened_index(transitions, last_state, last_move)] = 1
                feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[
                    get_flattened_index(transitions, last_state, last_move)]
                feat[get_flattened_index(transitions, last_state,
                                         last_move)] += alpha_sr * feat_delta

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

            if phase == "learning":
                ###### Update the successor matrix row correpsonding to last state ######
                one_hot = np.zeros(num_pairs)
                one_hot[get_flattened_index(transitions, last_state, last_move)] = 1
                feat_delta = one_hot + gamma * feat[get_flattened_index(transitions, current_state, next_move)] - feat[
                    get_flattened_index(transitions, last_state, last_move)]
                feat[get_flattened_index(transitions, last_state, last_move)] += alpha_sr * feat_delta

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward - v_state[get_flattened_index(transitions, current_state, next_move)]
            # scale feature according to Russek et al. 2017
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


def learning(gamma, alpha, alpha_sr, explore_chance, end_state, rewards, transitions, model_parameters):
    '''
    Simulates the learning phase, where the agent has access to the starting state.

    Arguments:
        - gamma: the time discounting constant
        - alpha: the learning rate constant
        - alpha_sr: the learning rate for SR
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
    num_pairs, v_state, feat, weight = model_parameters
    phase = "learning"

    # Create start states
    start_states_1 = np.array([1, 1])

    start_states_2 = np.array([1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9])
    np.random.shuffle(start_states_2)

    start_states_3 = np.array([1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3])
    np.random.shuffle(start_states_3)

    #start_states = np.concatenate([start_states_1, start_states_2, start_states_3])
    start_states = np.ones(30, dtype=np.int8)

    # Run trials
    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        v_state, feat, weight, transition_log_lines = run_trial(
            phase,
            gamma,
            alpha,
            alpha_sr,
            explore_chance,
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
        
    return new_params, transition_log

#
# Relearning
#
def update_parameters(condition, rewards, transitions):
    if condition == "reward":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [90], [0], [30], [0]]
    elif condition == "transition":
        transitions = [[2, 3], [5, 6], [4, 5], [7], [8], [9], [10], [10], [10], [11]]
    elif condition == "policy":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [90], [20], [30], [0]]
    elif condition == "goal":
        rewards = [[0, 0], [0, 0], [0, 0], [70], [0], [0], [20], [0], [30], [0]]
    else:
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [20], [0], [40], [0]]
        
    return rewards, transitions



def relearning(condition, gamma, alpha, alpha_sr, explore_chance, end_state, rewards, transitions, model_parameters):
    '''
    Simulates the relearning phase, where the agent does not directly experience the starting state.

    Arguments:
        - condition: string representing the relearning condition
        - gamma: the time discounting constant
        - alpha: the learning rate constant
        - alpha_sr: the learning rate for SR
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
    num_pairs, v_state, feat, weight = model_parameters
    phase = "relearning"

    reduced_feat, reduced_weight = reduce_weight_and_feat(feat, weight, rewards)

    # Create start states
    if condition == "transition":
        start_states = np.array([2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3])
    else:
        start_states = np.array([4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6])

    np.random.shuffle(start_states)

    # Run trials
    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        v_state, feat, weight, transition_log_lines = run_trial(
            phase,
            gamma,
            alpha,
            alpha_sr,
            explore_chance,
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

    new_params = [num_pairs, v_state, feat, weight]
        
    return new_params, transition_log

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