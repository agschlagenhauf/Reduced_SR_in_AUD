#
# model_based.py
#

import numpy as np
import random as rd
from utilities import *

from utilities import *

def policy(values, explore_chance):
    '''
    Finds the probability of choosing each action of a given state under the current policy

    Arguments:
        values: 1D list of the calculated Q-values of all actions from a single state
        explore-chance: probability that the current policy will choose a random action

    Returns:
        - policy - the probability that each action will be chosen
    '''
    if np.all([i == values[0] for i in values]):
        policy = np.repeat((1 / len(values)), len(values))
    else:
        policy = np.repeat((explore_chance / len(values)), len(values))
        policy[np.argmax(values)] += 1 - explore_chance
    return policy

#
# Run Trial
#
def run_trial(gamma, alpha, explore_chance, end_state, start_state, rewards, transitions, v_state, t_counts, t_matrix, weight):
    '''
    Simulates a single episode, from the given start state until an end state is reached
    Inputs:
        gamma: the time discounting constant
        alpha: the learning rate constant
        explore_chance: probability that the agent will choose a random action instead of the highest-value one
        end_state: list of states that are considered end states
        start_state: state that the agent starts in
        rewards: list of rewards corresponding to each action
        transitions: list of valid transitions from each state
        num_pairs: the number of state-action pairs
        t_counts:
        weight:
    Outputs:
        feat, weight: values updated after the current episode
        state_list, action_list, RPE_list, value_list: with episode's values appended to the end
        timestep_list: Total number of timesteps in this episode, used to pad all logs to the same length
    '''
    current_state = start_state - 1
    transition_log_lines = []  # all transitions per trial

    while True:

        ###### First state ######
        if (current_state + 1) == start_state:

            ###### Determine next and second next state ######
            # Determine the next state
            next_values = v_state[current_state]
            if np.random.uniform() < explore_chance or np.all([i == next_values[0] for i in next_values]):
                next_move = np.random.randint(len(transitions[current_state]))
            else:
                next_move = np.argmax(next_values)  # get index of max value
            next_state = transitions[current_state][next_move] - 1  # get next state
            # Determine the second next state
            second_next_values = v_state[next_state]
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)  # get index of max value
            second_next_state = transitions[next_state][second_next_move] - 1  # get second next state

            ###### No update of transition matrix in first state, as we did not transition from anywhere ######
            #t_matrix = np.zeros((len(flatten(rewards)), len(rewards)))

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[next_state][second_next_move] - \
                           v_state[current_state][next_move]  # get weight prediction error
            weight[current_state][next_move] += alpha * weight_delta  # update weight

            ###### Update values of all state-action pairs (Bellman Equation) ######
            next_state_values = [np.sum(v_state[state] * policy(v_state[state], explore_chance)) for state in range(len(rewards))]
            for i in range(len(rewards)):
                for j in range(len(rewards[i])):
                    v_state[i][j] = weight[i][j] + gamma * np.sum(t_matrix[get_flattened_index(rewards, i, j)] * next_state_values)

            ###### Fill in transition log line ######
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(t_matrix))}"
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
            second_next_values = v_state[next_state]
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values) # get index of max value
            second_next_state = transitions[next_state][second_next_move] - 1 # get second next state

            ###### Update the transition counts row correpsonding to last state and re-normalize transition matrix ######
            t_counts[get_flattened_index(transitions, last_state, last_move), current_state] += 1
            #print(t_counts)
            for index, row in enumerate(t_counts):
                if np.sum(row) == 0:
                    t_matrix[index] = np.zeros(len(rewards))
                else:
                    t_matrix[index] = row / np.sum(row)
            #print(t_matrix)

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward + gamma * v_state[next_state][second_next_move] - \
                           v_state[current_state][next_move] # get weight prediction error
            weight[current_state][next_move] += alpha * weight_delta # update weight
            
            ###### Update values of all state-action pairs (Bellman Equation) ######
            next_state_values = [np.sum(v_state[state] * policy(v_state[state], explore_chance)) for state in
                                 range(len(rewards))]
            #print(next_state_values)
            for i in range(len(v_state)):
                for j in range(len(v_state[i])):
                    v_state[i][j] = weight[i][j] + gamma * np.sum(t_matrix[get_flattened_index(v_state, i, j)] * next_state_values)
                    #print(f"i={i}, j={j}")
                    #print(np.sum(t_matrix[get_flattened_index(v_state, i, j)]))
                    #print(t_matrix[get_flattened_index(v_state, i, j)])
            ###### Fill in transition log line ######
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{comma_separate(v_state)},{comma_separate(weight)},{comma_separate(flatten(t_matrix))}"
            )

            ###### Move to the next state ######
            last_state = current_state
            last_move = next_move
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

        ###### Last state ######
        elif (current_state + 1) == end_state:

            ###### Update the transition counts row correpsonding to last state and re-normalize transition matrix ######
            t_counts[get_flattened_index(rewards, last_state, last_move), current_state] += 1
            for index, row in enumerate(t_counts):
                if np.sum(row) == 0:
                    t_matrix[index] = np.zeros(len(rewards))
                else:
                    t_matrix[index] = row / np.sum(row)

            ###### Update weights with TD learning ######
            reward = rewards[current_state][next_move]
            weight_delta = reward - v_state[current_state][next_move]  # get weight prediction error
            weight[current_state][next_move] += alpha * weight_delta  # update weight

            ###### Update values of all state-action pairs (Bellman Equation) ######
            for i in range(len(v_state)):
                for j in range(len(v_state[i])):
                    v_state[i][j] = weight[i][j]

            ###### Fill in transition log line ######
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{reward},{weight_delta},{flatten(v_state)},{comma_separate(weight)},{comma_separate(flatten(t_matrix))}"
            )

            ###### End loop ######
            break

        else:
            assert False

    return v_state, t_counts, weight, transition_log_lines



def learning(gamma, alpha, explore_chance, end_state, rewards, transitions, model_parameters):
    '''
    Simulates the pre-training learning phase, where the agent has access to the starting state
    Inputs:
        gamma: the time discounting constant
        alpha: the learning rate constant
        explore_chance: probability that the agent will choose a random action instead of the highest-value one
        end_state: list of states that are considered end states
        rewards: list of rewards corresponding to each action
        transitions: list of valid transitions from each state
        model_parameters: the components of a successor representation, in order:
            num_pairs: the number of state-action pairs
            feat: the successor matrix (should generally be initialized with zeros)
            weight: the weight vector (also generally initialized with zeros
    Outputs:
        model_parameters: calculated successor matrix and weight after pretraining
        logging_lists: with new simulation's values appended to the end
    '''
    ##### initialize model parameters #####
    v_state, t_counts, t_matrix, weight = model_parameters

    ##### Create start states #####
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
        v_state, t_counts, weight, transition_log_lines = run_trial(
            gamma,
            alpha,
            explore_chance,
            end_state,
            start_state,
            rewards,
            transitions,
            v_state,
            t_counts,
            t_matrix,
            weight
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [v_state, t_counts, t_matrix, weight]
        
    return new_params, transition_log


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
    Simulates the relearning phase, where the agent does not directly experience the starting state
    Inputs:
        condition: string representing the relearning condition, case sensitive (needed because the Transition condition uses different starting states)
        gamma: the time discounting constant
        alpha: the learning rate constant
        explore_chance: probability that the agent will choose a random action instead of the highest-value one
        end_state: list of states that are considered end states
        rewards: list of rewards corresponding to each action
        transitions: list of valid transitions from each state
        model parameters: the components of a successor representation, in order:
            num_pairs: the number of state-action pairs
            feat: the successor matrix, held over from the pretraining
            weight: the weight vector, held over from pretraining

    Outputs:
        model_parameters: calculated successor matrix and weight after pretraining
        logging_lists: with new simulation's values appended to the end
    '''
    # Unpack logging_lists and model parameters into component variables
    v_state, t_counts, t_matrix, weight = model_parameters

    # Create start states
    if condition == "transition":
        start_states = np.array([2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3])
    else:
        start_states = np.array([4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6])

    np.random.shuffle(start_states)

    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        v_state, t_counts, weight, transition_log_lines = run_trial(
            gamma,
            alpha,
            explore_chance,
            end_state,
            start_state,
            rewards,
            transitions,
            v_state,
            t_counts,
            t_matrix,
            weight
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [v_state, t_counts, t_matrix, weight]
        
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
    v_state, t_counts, t_matrix, weight = model_parameters

    action_index = np.argmax(v_state[0][0:2])

    if action_index == 0:
        action = ACTION_LEFT
    elif action_index == 1:
        action = ACTION_RIGHT
    else:
        raise ValueError

    # Transition log_line: trial,state,action,reward
    transition_log_line = f"1,1,{action},0"

    return action, [transition_log_line]
