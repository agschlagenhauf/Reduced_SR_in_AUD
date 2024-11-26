import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.spatial.distance import squareform
from scipy.stats import pearsonr

### Set parameters

## beta determines whether choices are highly deterministic on values (beta = 1) or random (beta = 0)
beta = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
## gamma determines how much visits of successor states are discounted the further they are in the future
gamma = 0.6

### Define functions

## Plotting
def plot_matrices(matrix_pre, matrix_post):
    fig, axes = plt.subplots(1, 2, figsize=(12, 12))  # 2 rows, 2 columns

    # Plot matrix_pre
    sns.heatmap(matrix_pre, cmap="Oranges", annot=False, cbar=True, ax=axes[0])
    axes[0].set_title("Pre")
    axes[0].set_xlabel("State-Action Pairs (To)")
    axes[0].set_ylabel("State-Action Pairs (From)")
    axes[0].set_yticklabels(axes[0].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_post
    sns.heatmap(matrix_post, cmap="Oranges", annot=False, cbar=True, ax=axes[1])
    axes[1].set_title("Post")
    axes[1].set_xlabel("State-Action Pairs (To)")
    axes[1].set_ylabel("State-Action Pairs (From)")
    axes[1].set_yticklabels(axes[1].get_yticklabels(), rotation=360, ha='right')

    plt.tight_layout()
    plt.show()

def softmax(beta, values):
    return np.exp(beta*np.array(values)) / np.sum(np.exp(beta*np.array(values)))

## Transform state-action-state matrix T to state-action-state-action matrix T
def transform_sa_s_to_sa_sa(T, Q_values_per_state):
    """
    Transform a state-action-to-state transition matrix T into a state-action-to-state-action format using a softmax policy.
    
    T: state-action-by-state transition matrix (shape: [state_action_pairs, states])
    Q_values_per_state: list of Q-values for available actions per state (list of lists)
    """
    num_sa_pairs = T.shape[0]
    num_states = T.shape[1]
    
    T_sa_sa = np.zeros((num_sa_pairs, num_sa_pairs))
    
    # Keep track of how many state-action pairs we have processed
    sa_index = 0
    
    for s in range(num_states):
        actions_in_state = len(Q_values_per_state[s])  # Number of actions is the length of the Q-values list for this state
        
        for a in range(actions_in_state):
            # Index for state-action pair (s, a)
            sa_t = sa_index

            for s_prime in range(num_states):
                # Apply softmax to only the Q-values for the available actions in state s_prime
                actions_in_s_prime = len(Q_values_per_state[s_prime])
                softmax_probs = softmax(beta, Q_values_per_state[s_prime])

                for a_prime in range(actions_in_s_prime):
                    # Index for state-action pair (s', a')
                    sa_prime = sum(len(Q) for Q in Q_values_per_state[:s_prime]) + a_prime

                    # Compute state-action-to-state-action transition probability
                    T_sa_sa[sa_t, sa_prime] = T[sa_t, s_prime] * softmax_probs[a_prime]

            # Increment the state-action pair index
            sa_index += 1
    
    return T_sa_sa

## Transform state-action-to-state-action matrix T to M
def compute_t_based_sr_matrix(T, gamma):
    """
    Compute the Successor Representation matrix M from a state-action-to-state-action transition matrix T.
    
    T: state-action-to-state-action transition matrix
    gamma: discount factor
    """
    I = np.eye(T.shape[0])  # Identity matrix of size (state-action pairs)
    M = np.linalg.inv(I - gamma * T)
    return M

## Calculate correlation between 2 matrices based on upper triangular part
def upper_triangular_correlation(matrix1, matrix2):
    # Check if both matrices are square and have the same dimensions
    if isinstance(matrix1, pd.DataFrame):
        matrix1 = matrix1.to_numpy()
    if isinstance(matrix2, pd.DataFrame):
        matrix2 = matrix2.to_numpy()

    # Check if both matrices have the same shape
    if matrix1.shape != matrix2.shape:
        raise ValueError("Matrices must have the same dimensions.")
    
    # Extract upper triangular parts of the matrices (excluding the diagonal)
    upper_tri_matrix1 = matrix1[np.triu_indices(matrix1.shape[0], k=1)]
    upper_tri_matrix2 = matrix2[np.triu_indices(matrix2.shape[0], k=1)]
    
    # Compute the Pearson correlation between the upper triangular elements
    corr, _ = pearsonr(upper_tri_matrix1, upper_tri_matrix2)
    
    return corr


### Define matrices after Learning in Transition Revaluation

df = pd.read_csv("simulated_matrices/model_based_beta0.csv")

## Successor Matrix M
M_pre = np.array([[1, 0, 0.2, 0.8, 0, 0, 0.1, 0.7, 0, 0.05, 0.6, 0, 0.5],
            [0, 1, 0, 0, 0.2, 0.8, 0, 0.1, 0.7, 0, 0.05, 0.6, 0.5],
            [0, 0, 1, 0, 0, 0, 1, 0, 0, 0.9, 0, 0, 0.8],
            [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0.9, 0, 0.8],
            [0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0.9, 0, 0.8],
            [0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0.9, 0.8],
            [0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0.9],
            [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0.9],
            [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0.9],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]])

## One-step Transition Matrix T sa to s
T_sa_s_pre = np.array([[0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]])

## One-step Transition Matrix T sa to sa
Q_pre = [[0.2, 0.8],
    [0.1, 0.6],
    [0.6, 0.9],
    [0],
    [0.6],
    [0.9],
    [0],
    [0.7],
    [1],
    [0]]
T_sa_sa_pre = transform_sa_s_to_sa_sa(T_sa_s_pre, Q_pre)

## M derived from T sa sa
M_derived_pre = compute_t_based_sr_matrix(T_sa_sa_pre, gamma)



### Define matrices after Re-Learning in transition revaluation condition

## Successor Matrix M
M_post = np.array([[1, 0, 0.2, 0.8, 0, 0, 0.1, 0.7, 0, 0.05, 0.6, 0, 0.5],
            [0, 1, 0, 0, 0.2, 0.8, 0, 0.1, 0.7, 0, 0.05, 0.6, 0.5],
            [0, 0, 1, 0, 0, 0, 1, 0, 0, 0.9, 0, 0, 0.8],
            [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0.9, 0, 0.8],
            [0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0.9, 0, 0.8],
            [0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0.9, 0.8],
            [0, 0, 0, 0, 0, 0, 1, 0, 0, 0.2, 0, 0.8, 0.9],
            [0, 0, 0, 0, 0, 0, 0, 1, 0, 0.8, 0.2, 0, 0.9],
            [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0.8, 0.2, 0.9],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]])

## One-step Transition Matrix T sa to s
T_sa_s_post = np.array([[0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]])

## One-step Transition Matrix T sa to sa
Q_post = [[0.8, 0.2],
    [0.9, 0.1],
    [0.1, 0.6],
    [0.9],
    [0],
    [0.6],
    [0],
    [0.7],
    [1],
    [0]]
T_sa_sa_post = transform_sa_s_to_sa_sa(T_sa_s_post, Q_post)

## M derived from T sa sa
M_derived_post = compute_t_based_sr_matrix(T_sa_sa_post, gamma)



### Plotting

## Create labels
sa_labels = ["S1A1", "S1A2", "S2A1", "S2A2", "S3A1", "S3A2", "S4A1", "S5A1", "S6A1", "S7A1", "S8A1", "S9A1", "S10A1"]            
s_labels = ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10"]            

## Transform all matrices to pd df
M_pre = pd.DataFrame(M_pre, index=sa_labels, columns=sa_labels)
T_sa_s_pre = pd.DataFrame(T_sa_s_pre, index=sa_labels, columns=s_labels)
T_sa_sa_pre = pd.DataFrame(T_sa_sa_pre, index=sa_labels, columns=sa_labels)
M_derived_pre = pd.DataFrame(M_derived_pre, index=sa_labels, columns=sa_labels)

M_post = pd.DataFrame(M_post, index=sa_labels, columns=sa_labels)
T_sa_s_post = pd.DataFrame(T_sa_s_post, index=sa_labels, columns=s_labels)
T_sa_sa_post = pd.DataFrame(T_sa_sa_post, index=sa_labels, columns=sa_labels)
M_derived_post = pd.DataFrame(M_derived_post, index=sa_labels, columns=sa_labels)

## Plotting
plot_matrices(M_pre, M_post)
plot_matrices(T_sa_s_pre, T_sa_s_post)
plot_matrices(T_sa_sa_pre, T_sa_sa_post)
plot_matrices(M_derived_pre, M_derived_post)

plot_matrices(M_post, M_derived_post)

upper_triangular_correlation(M_post, M_derived_post)
