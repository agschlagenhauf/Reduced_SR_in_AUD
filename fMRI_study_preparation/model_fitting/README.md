# Simulating agents' behavior in sequential decision-making task
This code runs simulations of various RL models in the decision-making task adapted from Momennejad et al. (2017).

## Usage
Setup python virtualenv and install dependencies:
```
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Run the simulations with:
```
python main.py
```
This script will run `simulate.py` for the models and conditions specified in `main.py`. Each model is saved as a separate script containing `learning` and `relearning` functions which run the respective `run_trial` function.

## Output
Output is stored in the `results/` directory:
1. `{model}.csv`: entire log of actions
1. `success_counts.txt`: learning and relearning test results

## Simulation Tuning
- Hyperparameters (alpha, gamma, explore_chance) can be directly changed in simulate.py.

- To change the number of trials for each phase, you can change the `start_states` variable in the learning and relearning functions in each model file.

- Changing the task structure can be done by changing the `transitions` and `rewards` lists, which has to be done both in simulate.py and in each model's update_parameters function. 
  - Each row in the top-level list corresponds to a state of the task, and each item in that row corresponds to a state it can transition into or the reward given for that transition, respectively. 
  - You'll also need to change the variables `end_states`, `num_pairs` (the total number of actions), and `num_states` in simulate.py.
