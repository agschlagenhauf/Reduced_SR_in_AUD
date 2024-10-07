from utilities import *
import numpy as np
import pandas as pd
plt.close()

### Set parameters

## beta determines whether choices are highly deterministic on values (beta = 1) or random (beta = 0)
betas = [0.0]
## gamma determines how much visits of successor states are discounted the further they are in the future
gamma = 0.5
## condition
condition = "transition" # transition or goal
## pre or post re-learning
timepoint = "post" # pre or post
## replace zeros in redM neuro with random small values?
replace_zeros = False

### Create labels
sa_labels = ["S1A1", "S1A2", "S2A1", "S2A2", "S3A1", "S3A2", "S4A1", "S5A1", "S6A1", "S7A1", "S8A1", "S9A1", "S10A1"]            
s_labels = ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10"]      
red_sa_labels = ["S8A1", "S9A1"]    

### Loop over beta values
for beta in betas:

    ### Define paths
    df_sr = pd.read_csv(f"/Users/milenamusial/Library/CloudStorage/OneDrive-Charité-UniversitätsmedizinBerlin/PhD/04_B01/WP3/Reduced_SR_in_AUD/simulations/results/full_sr_nsimulations1_alpha0.9_beta0.7_gamma0.5.csv")
    df_sr = df_sr.loc[df_sr['condition'] == condition].reset_index(drop=True)
    
    df_red_sr = pd.read_csv(f"/Users/milenamusial/Library/CloudStorage/OneDrive-Charité-UniversitätsmedizinBerlin/PhD/04_B01/WP3/Reduced_SR_in_AUD/simulations/results/reduced_sr_nsimulations1_alpha0.9_beta0.7_gamma0.5.csv")
    df_red_sr = df_red_sr.loc[df_red_sr['condition'] == condition].reset_index(drop=True)
    
    df_mb = pd.read_csv(f"/Users/milenamusial/Library/CloudStorage/OneDrive-Charité-UniversitätsmedizinBerlin/PhD/04_B01/WP3/Reduced_SR_in_AUD/simulations/results/model_based_nsimulations1_alpha0.9_beta0.7_gamma0.5.csv")
    df_mb = df_mb.loc[df_mb['condition'] == condition].reset_index(drop=True)

    if timepoint == 'pre':
    
        ### Define matrices after Learning in Transition Revaluation

        ## Successor Matrix M
        M = df_sr.loc[119, 'OS1A1-S1A1':'OS10A1-S10A1'].to_numpy().reshape(13,13).astype(float)

        ## Predicted neural similarity matrix based on M
        M_neuro = calculate_row_correlations(M)

        ## One-step Transition Matrix T sa to s
        T_sa_s = df_mb.loc[119, 'TS1A1-S1':'TS10A1-S10'].to_numpy().reshape(13,10).astype(float)

        ## One-step Transition Matrix T sa to sa
        Q_raw = df_mb.loc[119, 'VS1A1':'VS10A1'].to_numpy()
        Q = []
        for i in range(3):
            Q.append(Q_raw[i*2:(i*2)+2].tolist())
        for i in range(6, Q_raw.size):
            Q.append([Q_raw[i]])
        T_sa_sa = transform_sa_s_to_sa_sa(T_sa_s, Q, beta)

        ## Predicted neural similarity matrix based on T sa sa
        T_sa_sa_neuro = calculate_row_correlations(T_sa_sa)

        ## M derived from T sa sa
        M_derived = compute_t_based_sr_matrix(T_sa_sa, gamma)

        ## Predicted neural similarity matrix based on T-derived M
        M_derived_neuro = calculate_row_correlations(M_derived)

        ## Reduced successor matrix redM
        M_red = np.zeros((13,13))
        if condition == 'transition':
            M_red[:, 10:12] = M[:, 10:12]
        elif condition == 'goal':
            M_red[:, [9, 11]] = M[:, [9, 11]]

        ## Predicted neural similarity matrix based on redM
        if replace_zeros:
            # Replace zeros with random small values (e.g., between 1e-10 and 1e-5)
            M_red = np.where(M_red == 0, np.random.uniform(1e-10, 1e-5, M_red.shape), M_red)
        if condition == 'transition':
            M_red_neuro = calculate_row_correlations(M_red[:, 10:12])
        elif condition == 'goal':
            M_red_neuro = calculate_row_correlations(M_red[:, [9,11]])
        
        ## Transform all matrices to pd df
        M = pd.DataFrame(M, index=sa_labels, columns=sa_labels)
        M_neuro = pd.DataFrame(M_neuro, index=sa_labels, columns=sa_labels)
        M_red = pd.DataFrame(M_red, index=sa_labels, columns=sa_labels)
        M_red_neuro = pd.DataFrame(M_red_neuro, index=sa_labels, columns=sa_labels)
        T_sa_sa = pd.DataFrame(T_sa_sa, index=sa_labels, columns=sa_labels)
        T_sa_sa_neuro = pd.DataFrame(T_sa_sa_neuro, index=sa_labels, columns=sa_labels)
        M_derived = pd.DataFrame(M_derived, index=sa_labels, columns=sa_labels)
        M_derived_neuro = pd.DataFrame(M_derived_neuro, index=sa_labels, columns=sa_labels)
    
    elif timepoint == 'post':

        ### Define matrices after Re-Learning in transition revaluation condition

        ## Successor Matrix M
        M = df_sr.loc[147, 'OS1A1-S1A1':'OS10A1-S10A1'].to_numpy().reshape(13,13).astype(float)

        ## Predicted neural similarity matrix based on M
        M_neuro = calculate_row_correlations(M)

        ## Eigenvector Matrix for M
        M_eigenvalues, M_eigenvectors = np.linalg.eig(M)

        # Previously, each state was represented by e1 by M (e1 being a vector with 1 in the state's position)
        # Now, we have to write e in eigenspace space to know how states are represented in eigenspace
        M_eigenvectors_inv = np.linalg.inv(M_eigenvectors)
        v1 = M_eigenvectors[:,0].T
        v2 = M_eigenvectors[:,1].T
        e1 = np.dot(M_eigenvectors_inv,v1)
        e2 = np.dot(M_eigenvectors_inv,v2)

        ## If each state can be represented by each row of the SR (base vectors e weighted by that row)
        ## it can also be represented by eigenvectors weigthed by a different form of that row

        ## Predicted neural similarity matrix based on Eigenvector Matrix for M
        M_eigenvectors_neuro = calculate_row_correlations(M_eigenvectors)

        ## One-step Transition Matrix T sa to s
        T_sa_s = df_mb.loc[147, 'TS1A1-S1':'TS10A1-S10'].to_numpy().reshape(13,10).astype(float)

        ## One-step Transition Matrix T sa to sa
        Q_raw = df_mb.loc[147, 'VS1A1':'VS10A1'].to_numpy()
        Q = []
        for i in range(3):
            Q.append(Q_raw[i*2:(i*2)+2].tolist())
        for i in range(6, Q_raw.size):
            Q.append([Q_raw[i]])
        T_sa_sa = transform_sa_s_to_sa_sa(T_sa_s, Q, beta)
        T_eigenvalues, T_eigenvectors = np.linalg.eig(T_sa_sa)

        ## Predicted neural similarity matrix based on T sa sa
        T_sa_sa_neuro = calculate_row_correlations(T_sa_sa)

        ## M derived from T sa sa
        M_derived = compute_t_based_sr_matrix(T_sa_sa, gamma)
        M_der_eigenvalues, M_der_eigenvectors = np.linalg.eig(M_derived)

        ## Predicted neural similarity matrix based on T-derived M
        M_derived_neuro = calculate_row_correlations(M_derived)

        ## Reduced successor matrix redM
        M_red = np.zeros((13,13))
        M_red_cols = df_red_sr.loc[147, 'WS2A1':'OS1A2-S1A2'].to_numpy().reshape(13,2).astype(float)
        if condition == 'transition':
            M_red[:, 10:12] = M_red_cols
            #M_red_eigenvalues, M_red_eigenvectors = np.linalg.eig(M_red[:, 10:12])
        elif condition == 'goal':
            M_red[:, [9, 11]] = M_red_cols
            #M_red_eigenvalues, M_red_eigenvectors = np.linalg.eig(M_red[:, [9, 11]])
        M_red_eigenvalues, M_red_eigenvectors = np.linalg.eig(M_red)

        ## Predicted neural similarity matrix based on redM
        if replace_zeros:
            # Replace zeros with random small values (e.g., between 1e-10 and 1e-5)
            M_red = np.where(M_red == 0, np.random.uniform(1e-10, 1e-5, M_red.shape), M_red)
        if condition == 'transition':
            M_red_neuro = calculate_row_correlations(M_red[:, 10:12])
        elif condition == 'goal':
            M_red_neuro = calculate_row_correlations(M_red[:, [9,11]])

        ## Transform all matrices to pd df
        M = pd.DataFrame(M, index=sa_labels, columns=sa_labels)
        M_neuro = pd.DataFrame(M_neuro, index=sa_labels, columns=sa_labels)
        M_eigenvectors = pd.DataFrame(M_eigenvectors, index=sa_labels, columns=sa_labels)
        M_eigenvectors_neuro = pd.DataFrame(M_eigenvectors_neuro, index=sa_labels, columns=sa_labels)
        M_neuro = pd.DataFrame(M_neuro, index=sa_labels, columns=sa_labels)
        M_red = pd.DataFrame(M_red, index=sa_labels, columns=sa_labels)
        M_red_neuro = pd.DataFrame(M_red_neuro, index=sa_labels, columns=sa_labels)
        T_sa_sa = pd.DataFrame(T_sa_sa, index=sa_labels, columns=sa_labels)
        T_sa_sa_neuro = pd.DataFrame(T_sa_sa_neuro, index=sa_labels, columns=sa_labels)
        M_derived = pd.DataFrame(M_derived, index=sa_labels, columns=sa_labels)
        M_derived_neuro = pd.DataFrame(M_derived_neuro, index=sa_labels, columns=sa_labels)
        
    ### Plotting and result logging  

    ## Correlation between all matrices
    pairwise_upper_tri_correlation_heatmap(condition, beta, timepoint, ['M', 'reduced M', 'T', 'T-derived M', 'M neuro', 'reduced M neuro', 'T neuro', 'T-derived M neuro'], M, M_red, T_sa_sa, M_derived, M_neuro, M_red_neuro, T_sa_sa_neuro, M_derived_neuro)

    ## create plot
    plot_matrices(condition, timepoint, beta, M, M_eigenvectors, T_sa_sa, M_derived, M_neuro, M_eigenvectors_neuro, T_sa_sa_neuro, M_derived_neuro)

    
