#
# Define helper functions for predicted_matrices-py
#

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.spatial.distance import squareform
from scipy.stats import pearsonr, zscore
import statsmodels.api as sm
from statsmodels.stats.outliers_influence import variance_inflation_factor


## Plotting
def plot_matrices(condition, timepoint, beta, matrix1, matrix2, matrix3, matrix4, matrix5, matrix6, matrix7, matrix8):
    fig, axes = plt.subplots(2, 4, figsize=(16, 8))

    # Plot matrix_1
    sns.heatmap(matrix1, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[0,0])
    axes[0,0].set_title('M')
    axes[0,0].set_xlabel("State-Action Pairs (To)")
    axes[0,0].set_ylabel("State-Action Pairs (From)")
    axes[0,0].set_yticklabels(axes[0,0].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_2
    sns.heatmap(matrix2, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[0,1])
    axes[0,1].set_title('reduced M')
    axes[0,1].set_xlabel("State-Action Pairs (To)")
    axes[0,1].set_ylabel("State-Action Pairs (From)")
    axes[0,1].set_yticklabels(axes[0,1].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_3
    sns.heatmap(matrix3, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[0,2])
    axes[0,2].set_title('T')
    axes[0,2].set_xlabel("State-Action Pairs (To)")
    axes[0,2].set_ylabel("State-Action Pairs (From)")
    axes[0,2].set_yticklabels(axes[0,2].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_4
    sns.heatmap(matrix4, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[0,3])
    axes[0,3].set_title('T-derived M')
    axes[0,3].set_xlabel("State-Action Pairs (To)")
    axes[0,3].set_ylabel("State-Action Pairs (From)")
    axes[0,3].set_yticklabels(axes[0,3].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_5
    sns.heatmap(matrix5, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[1,0])
    axes[1,0].set_title('M neuro')
    axes[1,0].set_xlabel("State-Action Pairs (To)")
    axes[1,0].set_ylabel("State-Action Pairs (From)")
    axes[1,0].set_yticklabels(axes[1,0].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_6
    sns.heatmap(matrix6, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[1,1])
    axes[1,1].set_title('reduced M neuro')
    axes[1,1].set_xlabel("State-Action Pairs (To)")
    axes[1,1].set_ylabel("State-Action Pairs (From)")
    axes[1,1].set_yticklabels(axes[1,1].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_7
    sns.heatmap(matrix7, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[1,2])
    axes[1,2].set_title('T neuro')
    axes[1,2].set_xlabel("State-Action Pairs (To)")
    axes[1,2].set_ylabel("State-Action Pairs (From)")
    axes[1,2].set_yticklabels(axes[1,2].get_yticklabels(), rotation=360, ha='right')

    # Plot matrix_8
    sns.heatmap(matrix8, cmap="Oranges", vmin=-0.3, vmax=1, annot=False, cbar=True, ax=axes[1,3])
    axes[1,3].set_title('T-derived M neuro')
    axes[1,3].set_xlabel("State-Action Pairs (To)")
    axes[1,3].set_ylabel("State-Action Pairs (From)")
    axes[1,3].set_yticklabels(axes[1,3].get_yticklabels(), rotation=360, ha='right')

    # Adjust the layout to prevent overlapping
    plt.tight_layout(pad=2.5, rect=[0, 0, 1, 0.9])  # Ensures the subplots don't overlap
    fig.suptitle(f'{condition}, {timepoint}-re-learning, beta={beta}', fontsize=16)

    # Adjust space for subtitle (move it upwards)
    plt.subplots_adjust(top=0.90)  # Adjust top to create space for subtitle

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

# Plot pairwise correlations between upper triangular parts as a heatmap
def pairwise_upper_tri_correlation_heatmap(condition, beta, timepoint, matrix_names, *matrices):
    num_matrices = len(matrices)
    
    # Initialize a correlation matrix to store the pairwise correlations
    correlation_matrix = np.zeros((num_matrices, num_matrices))
    
    # Calculate pairwise correlations between matrices
    for i in range(num_matrices):
        for j in range(i, num_matrices):  # Only compute upper triangular part
            correlation_matrix[i, j] = upper_triangular_correlation(matrices[i], matrices[j])
            correlation_matrix[j, i] = correlation_matrix[i, j]  # Symmetry
    
    # Plot the heatmap
    plt.figure(figsize=(8, 6))
    ax = sns.heatmap(correlation_matrix, annot=True, cmap="YlGn", cbar=True)
    
    # Set tick positions and labels
    ax.set_xticklabels(matrix_names, rotation=45, ha='right')
    ax.set_yticklabels(matrix_names, rotation=0, ha='right')

    plt.title(f'Pairwise Correlations btw. S-A representations \n and neural S-A similarity matrices \n {condition}, {timepoint}-re-learning, beta={beta}')
    plt.subplots_adjust(left=0.2, bottom=0.2)
    plt.show()

    # Save the figure to a file
    plt.savefig(f"results/plot_2ndorder_heatmap_{condition}_{timepoint}_beta{beta}.png", format='png', dpi=400)  # Save the figure with a specified name

# calculate correlation between rows of a matrix
def calculate_row_correlations(matrix):
    # row-wise correlation
    correlation_matrix = np.corrcoef(matrix)
    # Replace NaN with 0
    correlation_matrix = np.nan_to_num(correlation_matrix, nan=0.0)
    # Z-score all values (flatten, z-score, reshape)
    correlation_matrix = zscore(correlation_matrix.flatten()).reshape(correlation_matrix.shape)
    # Remove the lower triangular part, keeping the diagonal
    correlation_matrix = np.triu(correlation_matrix, k=0)
    return correlation_matrix

# calculate variance inflation factor per row
def compute_vif(*matrices):
    """
    Computes the Variance Inflation Factor (VIF) for the columns of a matrix
    formed by combining the upper triangular parts of multiple input matrices.

    Parameters:
    *matrices: A variable number of 2D numpy arrays of the same shape.

    Returns:
    list: A list of VIF values for each column in the combined matrix.
    """
    # Ensure all input matrices are numpy arrays and have the same shape
    matrices = [np.asarray(matrix) for matrix in matrices]
    matrix_shape = matrices[0].shape
    
    for matrix in matrices:
        if matrix.shape != matrix_shape:
            raise ValueError("All matrices must have the same shape.")
    
    # Extract the upper triangular parts of all matrices (excluding the diagonal)
    upper_tri_indices = np.triu_indices_from(matrices[0], k=1)
    upper_tri_values = [matrix[upper_tri_indices] for matrix in matrices]
    
    # Combine the upper triangular values into a new matrix where each column is a variable
    combined_matrix = np.vstack(upper_tri_values).T

    # Compute VIF for each column in the combined matrix
    vif_values = [variance_inflation_factor(combined_matrix, i) for i in range(combined_matrix.shape[1])]

    return vif_values