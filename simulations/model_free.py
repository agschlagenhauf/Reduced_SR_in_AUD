#
# model_free.py
#

import numpy as np
import random as rd
from utilities import *

def run_trial(gamma, alpha, explore_chance, end_state, start_state, rewards, transitions, v_state):
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
        v_state: calculated Q-values of each state-action pair (should generally be initialized as zeroes)
        state_list: states visited at each time step
        action_list: actions taken at each time step
        RPE_list: reward prediction error for each time step
        value_list: each state-action pair's Q-values at each time step
    Outputs:
        v_state: Q-values updated after the current episode
        state_list, action_list, RPE_list, value_list: with episode's values appended to the end
    '''

    current_state = start_state - 1
    transition_log_lines = []  # all transitions per trial
    
    while True:

        if (current_state + 1) == start_state:

            # Determine the next state, either a random subsequent state or the highest-value one based on the exploration parameter
            # Determine the next state, either a random subsequent state or the highest-value subsequent state, depending on the exploration parameter
            next_values = v_state[current_state]
            # If the next action values are all the same we also choose randomly to avoid argmax defaulting to the first action
            if np.random.uniform() < explore_chance or np.all([i == next_values[0] for i in next_values]):
                next_move = np.random.randint(len(transitions[current_state]))
            else:
                next_move = np.argmax(next_values)  # get index of max value
            next_state = transitions[current_state][next_move] - 1  # get next state

            # Determine the action taken from the NEXT state, either the best action or a random one, depending on the exploration parameter
            # By having a random explore chance, we ensure that the successor matrix represents all possible successor actions, but has larger values for the
            # highest-reward ones.
            second_next_values = v_state[next_state]
            # If the next action values are all the same we also choose randomly to avoid argmax defaulting to the first action
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)  # get index of max value
            second_next_state = transitions[next_state][second_next_move] - 1  # get second next state

            # Update Q-values with TD learning on reward obtained
            reward = rewards[current_state][next_move]
            delta = reward + gamma * v_state[next_state][second_next_move] - v_state[current_state][next_move]
            v_state[current_state][next_move] += alpha * delta

            # Transition log line: state,action,reward,weight_delta,feature_delta,{values},{weights},{flattened_features}
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{comma_separate(v_state)}"
            )

            # Move to the next state
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

        elif (current_state + 1) != end_state:

            # Determine the action taken from the NEXT state, either the best action or a random one, depending on the exploration parameter
            # By having a random explore chance, we ensure that the successor matrix represents all possible successor actions, but has larger values for the
            # highest-reward ones.
            second_next_values = v_state[next_state]
            # If the next action values are all the same we also choose randomly to avoid argmax defaulting to the first action
            if np.random.uniform() < explore_chance or np.all([i == second_next_values[0] for i in second_next_values]):
                second_next_move = np.random.randint(len(transitions[next_state]))
            else:
                second_next_move = np.argmax(second_next_values)  # get index of max value
            second_next_state = transitions[next_state][second_next_move] - 1  # get second next state

            # Update Q-values with TD learning on reward obtained
            reward = rewards[current_state][next_move]
            delta = reward + gamma * v_state[next_state][second_next_move] - v_state[current_state][next_move]
            v_state[current_state][next_move] += alpha * delta

            # Transition log line: state,action,reward,weight_delta,feature_delta,{values},{weights},{flattened_features}
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{comma_separate(v_state)}"
            )

            # Move to the next state
            current_state = next_state
            next_move = second_next_move
            next_state = second_next_state

        elif (current_state + 1) == end_state:

            # Update Q-values with TD learning on reward obtained
            reward = rewards[current_state][next_move]
            delta = reward - v_state[current_state][next_move]
            v_state[current_state][next_move] += alpha * delta

            # Transition log line: state,action,reward,weight_delta,feature_delta,{values},{weights},{flattened_features}
            transition_log_lines.append(
                f"{current_state + 1},{next_move + 1},{comma_separate(v_state)}"
            )

            # end loop
            break
        else:
            assert False

    return v_state, transition_log_lines


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
        v_state: calculated Q-values of each state-action pair (should generally be initialized as zeroes)
    Outputs:
        v_state: calculated state values after pretraining
        logging_lists: with new simulation's values appended to the end
        
    '''
    v_state = model_parameters[0]

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
        v_state, transition_log_lines = run_trial(
            gamma,
            alpha,
            explore_chance,
            end_state,
            start_state,
            rewards,
            transitions,
            v_state
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [v_state]
        
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
        v_state: calculated Q-values of each state-action pair, held over from the pretraining
    Outputs:
        v_state: calculated state values after pretraining
        logging_lists: with new simulation's values appended to the end
    '''
    v_state = model_parameters[0]

    # Create start states
    if condition == "transition":
        start_states = np.array([2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3])
    else:
        start_states = np.array([4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6])

    np.random.shuffle(start_states)

    transition_log = []
    for trial_index, start_state in enumerate(start_states):
        v_state, transition_log_lines = run_trial(
            gamma,
            alpha,
            explore_chance,
            end_state,
            start_state,
            rewards,
            transitions,
            v_state
        )

        transition_log_lines = prefix_all(f"{trial_index + 1},", transition_log_lines)
        transition_log.extend(transition_log_lines)

    new_params = [v_state]

        
    return new_params, transition_log

'''
Simulates the test phase by comparing the action values of the two possible starting-state actions. The test state action is assumed to always be 
the higher-value choice
Input: v_state: 2d list of Q-values (rows are states, columns are actions)
Output: preferred starting state action
'''
def test(model_parameters):

    v_state = model_parameters[0]

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

