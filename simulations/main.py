#
# main.py
#

import sys
from os.path import join
from simulate import *
from utilities import *

#
# Constants
#
OUTPUT_DIR = "results"
SUCCESS_COUNT_FILENAME = "success_counts.txt"

#
# Parameters
#

NUM_SIMULATIONS = 110 # number of participants to simulate
MODELS = ["full_sr", "reduced_sr", "model_free", "model_based"] # "full_sr", "reduced_sr", "model_based", "model_free"
CONDITIONS = ["control", "reward", "transition", "policy", "goal"] # "control", "reward", "transition", "policy", "goal"

#
# Transition Log Headers
#
TRANSITION_LOG_HEADER_PREFIX = "simulation_number,model,condition,phase,trial,state,action,reward"

def get_transition_log_headers():
    """
    Creates the header lines for a .csv file for each model type.

    Returns:
        - dict: maps model name to its .csv header line 
    """

    transition_log_headers = {}

    # Action choices (left = 1, right = 2, forced = 1)
    state_action_choices = {
        1:  [ACTION_LEFT, ACTION_RIGHT],
        2:  [ACTION_LEFT, ACTION_RIGHT],
        3:  [ACTION_LEFT, ACTION_RIGHT],
        4:  [ACTION_FORCED],
        5:  [ACTION_FORCED],
        6:  [ACTION_FORCED],
        7:  [ACTION_FORCED],
        8:  [ACTION_FORCED],
        9:  [ACTION_FORCED],
        10: [ACTION_FORCED]
    }

    # e.g. S1A2
    state_strings = []
    state_action_strings = []
    for state in range(len(state_action_choices)):
        state_strings.append(f"S{state+1}")
    for state_number, choices in state_action_choices.items():
        for choice in choices:
            state_action_strings.append(f"S{state_number}A{choice}")

    value_strings = [f"V{item}" for item in state_action_strings]
    value_strings_joined = ",".join(value_strings)

    weight_strings = [f"W{item}" for item in state_action_strings]
    weight_strings_joined = ",".join(weight_strings)

    # e.g. S1A2-S3A1
    state_action_combination_strings = []
    for first_state_action_pair in state_action_strings:
        for second_state_action_pair in state_action_strings:
            state_action_combination_strings.append(f"{first_state_action_pair}-{second_state_action_pair}")

    occupancy_strings = [f"O{item}" for item in state_action_combination_strings]
    occupancy_strings_joined = ",".join(occupancy_strings)

    # e.g. S1A2-S3
    state_action_state_strings = []
    for state_action_pair in state_action_strings:
        for state in state_strings:
            state_action_state_strings.append(f"{state_action_pair}-{state}")

    transition_strings = [f"T{item}" for item in state_action_state_strings]
    transition_strings_joined = ",".join(transition_strings)

    transition_log_headers["full_sr"] = f"{TRANSITION_LOG_HEADER_PREFIX},weight_delta,{value_strings_joined},{weight_strings_joined},{occupancy_strings_joined}\n"
    transition_log_headers["reduced_sr"] = f"{TRANSITION_LOG_HEADER_PREFIX},weight_delta,{value_strings_joined},{weight_strings_joined},{occupancy_strings_joined}\n"
    transition_log_headers["model_based"] = f"{TRANSITION_LOG_HEADER_PREFIX},weight_delta,{value_strings_joined},{weight_strings_joined},{transition_strings_joined}\n"
    transition_log_headers["model_free"] = f"{TRANSITION_LOG_HEADER_PREFIX},{value_strings_joined}\n"

    return transition_log_headers

#
# Main
#
def main(num_simulations, models, conditions):
    """
    Runs several simulations for each model and writes results to OUTPUT_DIR.

    Arguments:
        - num_simulations: int, number of simulations to run on each (model, condition) pair
        - models: [str], list of model names
        - models: [str], list of condition names
    """

    success_counts = []
    transition_log_headers = get_transition_log_headers()

    for model in models:
        model_simulation_results = []

        for condition in conditions:
            print(f"> Simulating model {GREEN}{format_model(model)}{RESET} for condition {GREEN}{format_condition(condition)}{RESET} ...")
            
            # Simulation results per model and condition: [SimulationResult]
            simulation_results, alpha, beta, gamma = run_simulations(model, condition, num_simulations)

            successful_learning_results = [result for result in simulation_results if result.learning_test_result == True]

            num_successful_learning_tests = len(successful_learning_results)

            num_successful_relearning_tests = len(
                [result for result in successful_learning_results if result.relearning_test_result == True]
            )

            success_counts.append({
                "model": model,
                "condition": condition,
                "num_successful_learning_tests": num_successful_learning_tests,
                "total_learning_tests": num_simulations,
                "learning_percentage": f"{safe_divide(num_successful_learning_tests, num_simulations) * 100:0,.0f}",
                "num_successful_relearning_tests": num_successful_relearning_tests,
                "total_relearning_tests": num_successful_learning_tests,
                "relearning_percentage": f"{safe_divide(num_successful_relearning_tests, num_successful_learning_tests) * 100:0,.0f}"
            })

            # Add to simulation results per model for all conditions
            model_simulation_results.extend(simulation_results)

        # Write model simulation results to .csv file
        model_simulation_results_filepath = join(OUTPUT_DIR, f"{model}_nsimulations{num_simulations}_alpha{alpha}_beta{beta}_gamma{gamma}.csv")

        print(f"> Writing transition log to {GREEN}{model_simulation_results_filepath}{RESET} ...")
        with open(model_simulation_results_filepath, "w") as model_simulation_results_file:
            # Write csv header
            model_simulation_results_file.write(transition_log_headers[model])

            # Write csv rows
            transition_log_lines = flatten([result.transition_log for result in model_simulation_results])
            model_simulation_results_file.writelines(
                suffix_all(transition_log_lines, "\n")
            )

            print("> Done\n")

    # Write success counts to .txt file
    success_count_filepath = join(OUTPUT_DIR, SUCCESS_COUNT_FILENAME)
    print(success_counts)

    print(f"> Writing success counts to {GREEN}{success_count_filepath}{RESET} ...")
    with open(success_count_filepath, "w") as success_count_file:
        for dictionary in success_counts:
            success_count_file.writelines([
                f"{format_model(dictionary['model'])}, {format_condition(dictionary['condition'])}:\n",
                f"    - Learning: {dictionary['num_successful_learning_tests']} / {dictionary['total_learning_tests']} ({dictionary['learning_percentage']}%)\n",
                f"    - Relearning: {dictionary['num_successful_relearning_tests']} / {dictionary['total_relearning_tests']} ({dictionary['relearning_percentage']}%)\n\n"
            ])

        print("> Done\n")

if __name__ == "__main__":
        main(num_simulations=NUM_SIMULATIONS, models=MODELS, conditions=CONDITIONS)
        
        