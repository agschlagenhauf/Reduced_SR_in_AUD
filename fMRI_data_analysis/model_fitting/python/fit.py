#
# simulate.py
#

import numpy as np
import importlib
from utilities import *

#
# Run Simulations
#
def run_model_fitting(participant_id, participant_data, conditions, model, initial_parameters):
    '''
    Fits a given model to data of a given participant.

    Arguments:
        - participant: ID given in input df
        - conditions: which conditions to use for parameter estimation
        - model: str, e.g. "model_free", "full_sr", "reduced_sr"
        - initial_parameters: initial values for parameters

    Returns:
        - parameter_estimates: list of parameters
    '''

    # import model.py as module (has 4 available functions, learning(), update_parameters(), relearning(), test())
    model_package = importlib.import_module(model)

    #
    # Seed random number generator
    #
    np.random.seed(42)

    #
    # Initialize environment
    #
    num_pairs = 13
    num_states = 10

    #
    # Initialize Parameters
    #
    parameter_estimates = initial_parameters

    #
    # Initialize Log Probability of all actions per participant
    #
    logp_participant = np.zeros(len(participant_data))

    #
    # Simulation loop
    #
    for condition in conditions:

        #
        # Print Condition
        #
        print(f"  > Condition: {CYAN}{condition}{RESET} ...", end=end_character)

        # 
        # Get data for condition
        #
        condition_data = participant_data[participant_data["condition"] == condition]

        #
        # Initialize Values and Model-Specific Structures
        #
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [0], [0], [0], [0]]

        ###### model-free ######
        if model == "model_free":

            v_state = []

            for j in range(len(rewards)):
                row = []
                for k in range(len(rewards[j])):
                    row.append(0)
                v_state.append(row)

            model_structures = [v_state]

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

            # raw transition matrix
            init_t_counts = np.zeros((num_pairs, num_states))
            # normalized transition matrix
            init_t_matrix = init_t_counts

            model_structures = [v_state, init_t_counts, init_t_matrix, init_weight]

        ###### full & reduced SR ######
        elif model == "full_sr":
            v_state = np.zeros(num_pairs)
            init_weight = np.zeros(num_pairs)

            # init M with identity matrix as in Russek et al. 2017
            init_sr = np.identity(num_pairs)
            logp_all_actions = np.zeros(len(actions))

            model_structures = [num_pairs, v_state, init_sr, init_weight, logp_all_actions]

        elif model == "reduced_sr":
            v_state = np.zeros(num_pairs)
            init_weight = np.zeros(num_pairs)

            # hard-coded number of columns - adapt!
            init_reduced_weight = np.zeros((num_pairs, 2))

            # init M with identity matrix as in Russek et al. 2017
            init_sr = np.identity(num_pairs)

            # hard-coded number of columns - adapt!
            init_reduced_sr = np.zeros((num_pairs, 2))

            model_structures = [num_pairs, v_state, init_sr, init_reduced_sr, init_weight, init_reduced_weight]
            
        #
        # Fit learning and re-learning trials
        #
        logp_condition, parameter_estimates = model_package.fit_all_trials(
            condition_data,
            parameter_estimates,
            model_structures
        )


    print(f"  > Done\n")

    # return results for one model, one condition with all phases, all simulations
    return parameter_estimates
