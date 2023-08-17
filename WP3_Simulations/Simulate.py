import numpy as np
import pandas as pd
import importlib

def simulate(model, condition, sim_num, output_filename):
    # Select the module we want to simulate on
    model_package = importlib.import_module(model)

    # Initialize the default parameters
    alpha = 0.50
    gamma = 0.95
    explore_chance = 0.5
    end_states = [10, 11, 12, 13]
    num_pairs = 15

    # Initialize logging variables, each batch of simulations' logs goes in one .csv file
    # Logs are, in order: states visited, actions taken, reward prediction error, episode number, learning phase, and calculated values of each action
    logging_lists = [[], [], [], [], []]
    logging_lists.append([[] for k in range(num_pairs)])

    sim_num_list = []

    for i in range(sim_num):
    # Initialize the simulation-specific parameters
        transitions = [[2, 3], [4, 5], [5, 6], [7], [8], [9], [10], [11], [12], [13], [13], [13]]

        if condition == "Policy":
            rewards = [[0, 0], [0, 0], [0, 0], [0], [15], [30], [0], [0], [0], [0], [0], [0]]
        else:
            rewards = [[0, 0], [0, 0], [0, 0], [15], [0], [30], [0], [0], [0], [0], [0], [0]]


        if model == "Punctate":
            v_state = []
            for j in range(len(rewards)):
                row = []
                for k in range(len(rewards[j])):
                    row.append(0)
                v_state.append(row)
            model_parameters = v_state
        else:
            init_sr = np.zeros((num_pairs, num_pairs))
            init_weight = np.zeros(num_pairs)
            
            # We wrap the model parameters in a single list so we can use the same function call for every model
            model_parameters = [num_pairs, init_sr, init_weight]

        # Perform the simulation
        pretrained_values, logging_lists, epi_length_pretraining = \
            model_package.pretraining(gamma, alpha, explore_chance, end_states, rewards, transitions, model_parameters, logging_lists)
        new_rewards, new_transitions = model_package.update_parameters(condition, rewards, transitions)
        retrained_values, logging_lists, epi_length_retraining = \
            model_package.retraining(condition, gamma, alpha, explore_chance, end_states, new_rewards, new_transitions, pretrained_values, logging_lists)
        test_result = model_package.test(retrained_values)

        for l in range(len(epi_length_pretraining) + len(epi_length_retraining)):
            sim_num_list.append(i+1)

    #result = pd.DataFrame({'Model': model, 'Condition': condition, 'Simulation': sim_num_list, 'Phase': logging_lists[4], 'Episode': logging_lists[3], \
    #    'State': logging_lists[0], 'Action': logging_lists[1], 'RPE': logging_lists[2]})

    result = pd.DataFrame({'Model': model, 'Condition': condition, 'Simulation': sim_num_list, 'Phase': logging_lists[4], 'Episode': logging_lists[3], \
        'State': logging_lists[0], 'Action': logging_lists[1], 'RPE': logging_lists[2], 'VS1A2': logging_lists[5][0], 'VS1A3': logging_lists[5][1], \
            'VS2A4': logging_lists[5][2], 'VS2A5': logging_lists[5][3], 'VS3A5': logging_lists[5][4], 'VS3A6': logging_lists[5][5], 'VS4A7': logging_lists[5][6], \
                'VS5A8': logging_lists[5][7], 'VS6A9': logging_lists[5][8], 'VS7A10': logging_lists[5][9], 'VS8A11': logging_lists[5][10], \
                    'VS9A12': logging_lists[5][11], 'VS10A13': logging_lists[5][12], 'VS11A13': logging_lists[5][13], 'VS12A13': logging_lists[5][14]})

    result.to_csv(output_filename)
        


def simulate_custom_parameters(parameter_file):
    pass