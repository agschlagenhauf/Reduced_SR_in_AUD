#
# main.py
#

import sys
import os
import pandas as pd
from os.path import join
from fit import *
from utilities import *

#
# Constants
#
DATA_DIR = "/Users/milenamusial/Library/CloudStorage/OneDrive-Charité-UniversitätsmedizinBerlin/PhD/04_B01/WP3/WP3_DATA"
OUTPUT_DIR = "results"
OUTPUT_FILENAME = "parameter_estimates.txt"

#
# Data to fit 
#
df = pd.read_csv(os.path.join(DATA_DIR, "PILOT_3/behavioral_data/data_to_fit.csv"))
n_participants = df["ID"].nunique()

#
# Models and conditions to fit
#
MODELS = ["full_sr"] # "full_sr", "reduced_sr", "model_based", "model_free"
CONDITIONS = ["control", "reward", "transition", "goal-state"] # "control", "reward", "transition", "policy", "goal-state"

#
# Main
#
def main(n_participants, conditions, models, df):
    """
    Fits specified models and conditions and writes results to OUTPUT_DIR.

    Arguments:
        - models: [str], list of model names
        - models: [str], list of condition names
    """

    model_fit_results = []

    # Fit model
    for model in models:
        
        # Do data of all participants
        for participant in n_participants:

            participant_id = df["ID"].unique()[participant]
            print(f"> Fitting participant {GREEN}{participant_id}{RESET} with model {GREEN}{format_model(model)}{RESET} ...")

            # Get participant data
            participant_data = df[df["ID"] == participant_id]

            # Initialize parameters
            alpha = 0.5
            gamma = 0.5
            beta = 0.5
            initial_parameters = [alpha, gamma, beta]
            
            # Fitting results per model and condition: [SimulationResult]
            participant_model_loglik = run_model_fitting(
                initial_parameters, 
                participant_data,
                conditions, 
                model)

            # Minimize 
            result = scipy.optimize.minimize(participant_model_loglik, 
                                            initial_parameters,
                                            args=(participant_data, conditions, model),
                                            method="BFGS")

            # Add to simulation results per model for all conditions
            model_fit_results.extend([model, participant, flatten(parameter_estimates)])

        # Write model simulation results to .csv file
        model_fit_results_filepath = join(OUTPUT_DIR, OUTPUT_FILENAME)

        print(f"> Writing parameter estimates to {GREEN}{OUTPUT_DIR}{RESET} ...")
        with open(model_fit_results_filepath, "w") as model_fit_results_file:

            # Write csv header
            model_fit_results_file.write("model,participant,alpha,beta,gamma")

            # Write csv rows
            model_fit_results_file.writelines(
                suffix_all(model_fit_results, "\n")
            )

            print("> Done\n")

if __name__ == "__main__":
    main(models=MODELS, conditions=CONDITIONS)
