import numpy as np
import pandas as pd
import importlib

'''
Runs a number of simulations of a given model, including the learning, relearning, and test phases, and logs the model parameters and test results after each 
learning phase of each simulation, as well as optionally the actions taken, RPE, and current action values after each time step
Inputs:
    model: String with the name of the model used, options are "Punctate", "FullSR", "ReducedSR"
    condition: String with the simulation condition used, options are "Control", "Reward", "Transition", "Policy", "Goal"
    sim_num: Number of simulations to be run
    output_filename: Filename the episode log should be written to (should be .csv, the learning phase summary adds "_Results" to filename)
    full_logging: If the full log actions and action values of each time step should be recorded. False means only the learning phase summary is saved. Default True.
Outputs:
    milestone_results: Pandas dataframe with the learning phase summary information (action values for Punctate, weight vector and successor matrix for SR models), 
        and test result
'''
def simulate(model, condition, sim_num, output_filename, full_logging=True):
  
    # Select the module we want to simulate on
    model_package = importlib.import_module(model)

    # Initialize the default parameters
    alpha = 0.9
    gamma = 0.95
    explore_chance = 0.5
    end_states = [10, 11]
    num_pairs = 13 # state action pairs
    num_states = 10

    # Initialize logging variables, each batch of simulations' logs goes in one .csv file
    # Logs are, in order: states visited, actions taken, reward prediction error, episode number, learning phase, and calculated values of each action
    logging_lists = [[], [], [], [], []]
    logging_lists.append([[] for k in range(num_pairs)])

    # Initialize the milestone log, which is only updated at the end of each learning phase of a given simulation and goes in a separate .csv file
    test_result_list = []
    milestone_labels = [[], []]
    if model == "Punctate":
        milestone_logs = [[] for k in range(num_pairs)]
    elif model == "ModelBased":
        milestone_logs = [[] for k in range(num_pairs * (num_states + 1))]
    else:
        milestone_logs = [[] for k in range(num_pairs * (num_pairs + 1))]

    sim_num_list = []

    for i in range(sim_num):
    # Initialize the simulation-specific parameters
        transitions = [[2, 3], [4, 5], [5, 6], [7], [8], [9], [10], [10], [10], [11]]

    if condition == "Policy":
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [10], [20], [30], [0]]
    else:
        rewards = [[0, 0], [0, 0], [0, 0], [0], [0], [0], [20], [0], [30], [0]]

        if model == "Punctate":
            v_state = []
            for j in range(len(rewards)):
                row = []
                for k in range(len(rewards[j])):
                    row.append(0)
                v_state.append(row)
            model_parameters = v_state
        elif model == "ModelBased":
            v_state = []
            init_weight = []
            for j in range(len(rewards)):
                row = []
                for k in range(len(rewards[j])):
                    row.append(0)
                v_state.append(row)
                init_weight.append(row.copy())
            init_t_counts = np.zeros((num_pairs, num_states))
            model_parameters = [v_state, init_t_counts, init_weight]
        else:
            init_sr = np.identity((num_pairs)) # init M with identity matrix as in Russek et al. 2017
            init_sr[-1,:] = 0 # set row corresponding to terminal state to 0 as in Russek et al. 2017
            init_weight = np.zeros(num_pairs)
            
            # We wrap the model parameters in a single list so we can use the same function call for every model
            model_parameters = [num_pairs, init_sr, init_weight]

        # Perform the initial learning and test the currently preferred starting action
        pretrained_values, logging_lists, epi_length_pretraining = \
            model_package.pretraining(gamma, alpha, explore_chance, end_states, rewards, transitions, model_parameters, logging_lists)
        milestone_logs, milestone_labels = model_package.update_logs(milestone_logs, milestone_labels, i, "After Learning", pretrained_values)
        test_result = model_package.test(pretrained_values)
        test_result_list.append(test_result)

        # Change the rewards or transitions, depending on the condition being simulated
        new_rewards, new_transitions = model_package.update_parameters(condition, rewards, transitions)

        # Retrain with the previously-learned model parameters and the new rewards and/or transitions
        retrained_values, logging_lists, epi_length_retraining = \
            model_package.retraining(condition, gamma, alpha, explore_chance, end_states, new_rewards, new_transitions, pretrained_values, logging_lists)
        milestone_logs, milestone_labels = model_package.update_logs(milestone_logs, milestone_labels, i, "After Relearning", pretrained_values)

        test_result = model_package.test(retrained_values)
        test_result_list.append(test_result)

        for l in range(len(epi_length_pretraining) + len(epi_length_retraining)):
            sim_num_list.append(i+1)

    # Action name formatting: VS1A3 = action going from state 1 to state 3
    move_names = ['S' + str(index+1) + 'A' + str(i) for index, k in enumerate(transitions) for i in k]

    # Occupancy name formatting: OS1A2-S2A4 = future occupancy of the S2-A4 action given the S1-A2 action
    occupancy_names = ['O' + i + '-' + j for i in move_names for j in move_names]

    # Transition name formatting: TS1A2 - S2 = probability of transitioning from state 1 to state 2 given the S1-A2 action
    transition_names = ['T' + i + '-S' + str(j + 1) for i in move_names for j in range(num_states)]

    # Save the individual time-step logs
    if full_logging == True:
        result = pd.DataFrame({'Model': model, 'Condition': condition, 'Simulation': sim_num_list, 'Phase': logging_lists[4], 'Episode': logging_lists[3], \
            'State': logging_lists[0], 'Action': logging_lists[1], 'RPE': logging_lists[2]})
    
        # Add each action's calculated values to the logging frame
        values = {}
        for index, j in enumerate(move_names):
            values['V' + j] = logging_lists[5][index]
        result = pd.concat((result, pd.DataFrame(values)), axis=1)

        result.to_csv(output_filename)

    # Save the milestone logs
    milestone_results = pd.DataFrame({'Simulation': milestone_labels[0], 'Phase': milestone_labels[1]})
    if model == "Punctate":
        # The punctate model saves the Q-value of each state-action pair
        values = {}
        for index, j in enumerate(move_names):
            values['V' + j] = milestone_logs[index]
        milestone_results = pd.concat((milestone_results, pd.DataFrame(values)), axis=1)
    elif model == "ModelBased":
        # The model-based model saves the weight vector and a flattened transition matrix
        weights_and_transitions = {}
        for index, j in enumerate(move_names):
            weights_and_transitions["W" + j] = milestone_logs[index]
        for index, j in enumerate(transition_names):
            weights_and_transitions[j] = milestone_logs[index + num_pairs]
        milestone_results = pd.concat((milestone_results, pd.DataFrame(weights_and_transitions)), axis=1)
    else:
        # The SR models save the weight vector and a flattened successor matrix
        weights_and_sr = {}
        for index, j in enumerate(move_names):
            weights_and_sr["W" + j] = milestone_logs[index]
        for index, j in enumerate(occupancy_names):
            weights_and_sr[j] = milestone_logs[index + num_pairs]
        milestone_results = pd.concat((milestone_results, pd.DataFrame(weights_and_sr)), axis=1)

    milestone_results['Test Result'] = test_result_list

    milestone_results.to_csv(output_filename[:-4] + "_Results.csv")

    return milestone_results
        


def simulate_custom_parameters(parameter_file):
    pass
