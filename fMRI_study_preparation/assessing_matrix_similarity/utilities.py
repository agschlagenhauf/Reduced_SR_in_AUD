#
# Define helper functions for predicted_matrices-py
#

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.spatial.distance import squareform
from scipy.stats import pearsonr

## Plotting
def plot_matrices(condition, timepoint, beta, matrix1, matrix2, matrix3, matrix4):
    fig, axes = plt.subplots(1, 4, figsize=(16, 4))

    # Plot matrix_pre
    sns.heatmap(matrix1, cmap="Oranges", annot=False, cbar=True, ax=axes[0])
    axes[0].set_title('M')
    axes[0].set_xlabel("State-Action Pairs (To)")
    axes[0].set_ylabel("State-Action Pairs (From)")
    axes[0].set_yticklabels(axes[0].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_post
    sns.heatmap(matrix2, cmap="Oranges", annot=False, cbar=True, ax=axes[1])
    axes[1].set_title('redM')
    axes[1].set_xlabel("State-Action Pairs (To)")
    axes[1].set_ylabel("State-Action Pairs (From)")
    axes[1].set_yticklabels(axes[1].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_post
    sns.heatmap(matrix3, cmap="Oranges", annot=False, cbar=True, ax=axes[2])
    axes[2].set_title('T')
    axes[2].set_xlabel("State-Action Pairs (To)")
    axes[2].set_ylabel("State-Action Pairs (From)")
    axes[2].set_yticklabels(axes[2].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_post
    sns.heatmap(matrix4, cmap="Oranges", annot=False, cbar=True, ax=axes[3])
    axes[3].set_title('T-derived M')
    axes[3].set_xlabel("State-Action Pairs (To)")
    axes[3].set_ylabel("State-Action Pairs (From)")
    axes[3].set_yticklabels(axes[3].get_yticklabels(), rotation=360, ha='right')

    # Adjust the layout to prevent overlapping
    plt.tight_layout(rect=[0, 0, 1, 0.95])  # Ensures the subplots don't overlap
    fig.suptitle(f'{condition}, {timepoint}-re-learning, beta={beta}', fontsize=16)

    # Adjust space for suptitle (move it upwards)
    plt.subplots_adjust(top=0.85)  # Adjust top to create space for suptitle

    plt.show()

    # Save the figure to a file
    plt.savefig(f"results/plot_{condition}_{timepoint}_beta{beta}.png", format='png', dpi=400)  # Save the figure with a specified name


def softmax(beta, values):
    return np.exp(beta*np.array(values)) / np.sum(np.exp(beta*np.array(values)))

## Transform state-action-state matrix T to state-action-state-action matrix T
def transform_sa_s_to_sa_sa(T, Q_values_per_state, beta):
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
    if matrix1.shape != matrix2.shape:
        raise ValueError("Matrices must be the same size.")
    
    if matrix1.shape[0] != matrix1.shape[1]:
        raise ValueError("Matrices must be square.")
    
    # Extract upper triangular parts of the matrices (excluding the diagonal)
    upper_tri_matrix1 = matrix1.where(np.triu(np.ones(matrix1.shape), k=1).astype(bool)).stack()
    upper_tri_matrix2 = matrix2.where(np.triu(np.ones(matrix2.shape), k=1).astype(bool)).stack()
    
    # Compute the Pearson correlation between the upper triangular elements
    corr, _ = pearsonr(upper_tri_matrix1.to_numpy(), upper_tri_matrix2.to_numpy())
    
    return corr