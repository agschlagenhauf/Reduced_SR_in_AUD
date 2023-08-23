import pandas as pd
import numpy as np
import Simulate

num_trials = 1000
models = ["Punctate", "FullSR", "ReducedSR"]
conditions = ["Control", "Reward", "Transition", "Policy", "Goal"]

model = "FullSR"
condition = "Reward"

#success_rates = open("./Results/success_rates.txt", "w")
success_rates = open("./Results/success_rates_hyperparameter_search.txt", "w")
success_rates.write(model + " model, " + condition + " condition:\n\n")

alphas = [0.5, 0.75, 0.9, 0.95, 0.99]
epsilons = [0, 0.1, 0.25, 0.5, 0.75, 0.9, 1]

#for model in models:
    #for condition in conditions:
for alpha in alphas:
    for epsilon in epsilons:
        #milestone_results = Simulate.simulate(model, condition, alpha, epsilon, num_trials, "./Results/" + model + "_" + condition + ".csv", full_logging=False)
        #success_rates.write(model + " model, " + condition + " condition:\n")
        milestone_results = Simulate.simulate(model, condition, num_trials, alpha, epsilon, "./Results/Alpha_" + str(alpha) + "_Epsilon_" + str(epsilon) + \
                                              ".csv", full_logging=False)
        success_rates.write("alpha = " + str(alpha) + ", epsilon = " + str(epsilon) + "\n")

        initial_results = np.array(milestone_results[milestone_results['Phase'] == "After Learning"]['Test Result'])
        final_results = np.array(milestone_results[milestone_results['Phase'] == "After Relearning"]['Test Result'])

        initial_success = sum(initial_results == 3)
        final_results_correctly_trained = final_results[initial_results == 3]

        if condition == "Control":
            relearn_success = sum(final_results_correctly_trained == 3)
        else:
            relearn_success = sum(final_results_correctly_trained == 2)

        init_percent = initial_success / num_trials * 100
        relearn_percent = relearn_success / initial_success * 100

        success_rates.write("Successful Initial Learning: " + str(initial_success) + "/" + str(num_trials) + ", " + str(init_percent) + "%\n")
        success_rates.write("Successful Relearning: " + str(relearn_success) + "/" + str(initial_success) + ", " + str(relearn_percent) + "%\n\n")
        print(alpha, epsilon)

success_rates.close()
