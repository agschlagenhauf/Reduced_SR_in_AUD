#
# simulate.py
#

import numpy as np
import importlib
from utilities import *

#
# Simulation Result
#
class SimulationResult:

    def __init__(self, transition_log, learning_test_result, relearning_test_result):
        """
        Initializes a SimulationResult.

        Arguments:
            - transition_log: str, one row entry in .csv format
            - learning_test_result: bool, true if the test after learning phase was successful
            - relearning_test_result: bool, true if the test after relearning phase was successful
        """

        self.transition_log = transition_log
        self.learning_test_result = learning_test_result
        self.relearning_test_result = relearning_test_result

#
# Run Simulations
#
def run_simulations(model, condition, num_simulations):
    '''
    Runs a number of simulations of a given model, including the learning, relearning, and test phases.

    Arguments:
        - model: str, e.g. "model_free", "full_sr", "reduced_sr"
        - condition: str, e.g. "control", "reward", "transition", "policy", "goal"
        - num_simulations: int, number of simulations to run

    Returns:
        - [SimulationResult]: list of simulation results for a (model, condition) pair
    '''

    # import model.py as module (has 4 available functions, learning(), update_parameters(), relearning(), test())
    model_package = importlib.import_module(model)

    #
    # Seed random number generator
    #
    np.random.seed(42)

    #
    # Initialize default parameters
    #
    alpha = 0.9
    gamma = 0.5
    beta = 1.0
    end_state = 10
    num_pairs = 13 # (state, action) pairs
    num_states = 10

    #
    # Simulation loop
    #
    simulation_results = []

    for simulation_number in range(1, num_simulations + 1):
        #
        # Print Simulation Number
        #
        end_character = "\n" if simulation_number == num_simulations else "\r"
        print(f"  > Simulation number: {CYAN}{simulation_number} / {num_simulations}{RESET} ...", end=end_character)

        #
        # Initialize Generic Parameters
        #
        transitions = [[2, 3], [4, 5], [5, 6], [7], [8], [9], [10], [10], [10], [11]]

        if condition == "policy" or condition == "transition":
            rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [0], [15], [30], [0]]
        else:
            rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [15], [0], [30], [0]]

        #
        # Initialize Model-Specific Parameters
        #

        ###### model-free ######
        if model == "model_free":

            v_state = []

            for j in range(len(rewards)):
                row = []
                for k in range(len(rewards[j])):
                    row.append(0)
                v_state.append(row)

            model_parameters = [v_state]

        ###### model-based ######
        elif model == "model_based":
            v_state = []
            init_weight = []

            for j in range(len(rewards)):
                row = []
                for k in range(len(rewards[j])):
                    row.append(0)
                v_state.append(row)
                init_weight.append(row.copy())

            init_t_counts = np.zeros((num_pairs, num_states))
            init_t_matrix = init_t_counts # normalized transition matrix
            model_parameters = [v_state, init_t_counts, init_t_matrix, init_weight]


        ###### full & reduced SR ######
        elif model == "full_sr":
            v_state = np.zeros(num_pairs)
            init_weight = np.zeros(num_pairs)
            init_sr = np.identity(num_pairs)  # init M with identity matrix as in Russek et al. 2017

            model_parameters = [num_pairs, v_state, init_sr, init_weight]

        elif model == "reduced_sr":
            v_state = np.zeros(num_pairs)
            init_weight = np.zeros(num_pairs)
            init_reduced_weight = np.zeros((num_pairs, 2)) # hard-coded number of columns - adapt!
            init_sr = np.identity(num_pairs)  # init M with identity matrix as in Russek et al. 2017
            init_reduced_sr = np.zeros((num_pairs, 2)) # hard-coded number of columns - adapt!

            model_parameters = [num_pairs, v_state, init_sr, init_reduced_sr, init_weight, init_reduced_weight]

        #
        # Learning Phase
        #
        learned_parameters, learning_transition_log = model_package.learning(
            gamma,
            alpha,
            beta,
            end_state,
            rewards,
            transitions,
            model_parameters
        )

        learning_test_action, learning_test_transition_log = model_package.test(learned_parameters)
        
        #
        # Relearning Phase
        #
        new_rewards, new_transitions = model_package.update_parameters(condition, rewards, transitions)

        relearned_parameters, relearning_transition_log = model_package.relearning(
            condition,
            gamma,
            alpha,
            beta,
            end_state,
            new_rewards,
            new_transitions,
            learned_parameters
        )

        relearning_test_action, relearning_test_transition_log = model_package.test(relearned_parameters)
       
        #
        # Results
        #
        learning_transition_log = prefix_all("learning,", learning_transition_log);
        learning_test_transition_log = prefix_all("learning_test,", learning_test_transition_log);

        relearning_transition_log = prefix_all("relearning,", relearning_transition_log);
        relearning_test_transition_log = prefix_all("relearning_test,", relearning_test_transition_log);

        transition_log = flatten([
            learning_transition_log,
            learning_test_transition_log,
            relearning_transition_log,
            relearning_test_transition_log
        ])

        transition_log = prefix_all(f"{simulation_number},{model},{condition},", transition_log)

        # ecode correctness of test (TRUE = correct)
        if condition == "control":
            learning_test_result = (learning_test_action == ACTION_RIGHT)
            relearning_test_result = (relearning_test_action == ACTION_RIGHT)
        else:
            learning_test_result = (learning_test_action == ACTION_RIGHT)
            relearning_test_result = (relearning_test_action == ACTION_LEFT)

        simulation_results.append(
            SimulationResult(
                transition_log=transition_log,
                learning_test_result=learning_test_result,
                relearning_test_result=relearning_test_result
            )
        )

    print(f"  > Done\n")

    # return results for one model, one condition with all phases, all simulations
    return simulation_results
