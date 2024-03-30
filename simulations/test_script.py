import pandas as pd
import numpy as np
import Simulate


num_trials = 1000
models = ["Punctate", "ModelBased", "FullSR", "ReducedSR"] # "Punctate", "ModelBased", "FullSR", "ReducedSR"
conditions = ["Control", "Reward", "Transition", "Policy", "Goal"] # "Control", "Reward", "Transition", "Policy", "Goal"

success_rates = open("./Results/success_rates.txt", "w")

# Runs several simulations of each model/condition combination and writes the overall success rate of each to a text file
for model in models:
    for condition in conditions:
      
        print(f"Running model {model} in condition {condition}...")
        
        milestone_results = Simulate.simulate(model, condition, num_trials, "./Results/" + model + "_" + condition + ".csv", full_logging=False)
        success_rates.write(model + " model, " + condition + " condition:\n")

        initial_results = np.array(milestone_results[milestone_results['Phase'] == "After Learning"]['Test Result'])
        final_results = np.array(milestone_results[milestone_results['Phase'] == "After Relearning"]['Test Result'])

        # Initial success: Out of all trials, in how many does the agent correctly find the best action after the initial learning phase
        initial_success = sum(initial_results == 3)
        final_results_correctly_trained = final_results[initial_results == 3]

        # Final success: Out of ONLY the trials where the agent learned the correct initial action, in how many does it correctly adjust its preferred action to 
        # reflect the reward or transition changes
        if condition == "Control":
            relearn_success = sum(final_results_correctly_trained == 3)
        else:
            relearn_success = sum(final_results_correctly_trained == 2)

        init_percent = initial_success / num_trials * 100
        relearn_percent = relearn_success / initial_success * 100

        success_rates.write("Successful Initial Learning: " + str(initial_success) + "/" + str(num_trials) + ", " + str(init_percent) + "%\n")
        success_rates.write("Successful Relearning: " + str(relearn_success) + "/" + str(initial_success) + ", " + str(relearn_percent) + "%\n\n")

success_rates.close()
