from utilities import *
import numpy as np
import pandas as pd
plt.close()

### Set parameters

## beta determines whether choices are highly deterministic on values (beta = 1) or random (beta = 0)
betas = [0.0, 1.0]
## gamma determines how much visits of successor states are discounted the further they are in the future
gamma = 0.5
## condition
condition = "goal" # transition or goal
## pre or post re-learning
timepoint = "post" # pre or post

### Initialize results df
# Create an empty DataFrame with specific columns
results_df = pd.DataFrame(columns=['beta', 'corr_M_Mred', 'corr_M_Mder', 'corr_M_T', 'corr_Mred_Mder', 'corr_Mred_T', 'corr_Mder_T'])

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

        ## M derived from T sa sa
        M_derived = compute_t_based_sr_matrix(T_sa_sa, gamma)

        ## Reduced successor matrix redM
        M_red = np.zeros((13,13))
        if condition == 'transition':
            M_red[:, 10:12] = M[:, [10, 11]]
        elif condition == 'goal':
            M_red[:, [9, 11]] = M[:, [9, 11]]

        ## Transform all matrices to pd df
        M = pd.DataFrame(M, index=sa_labels, columns=sa_labels)
        T_sa_s = pd.DataFrame(T_sa_s, index=sa_labels, columns=s_labels)
        T_sa_sa = pd.DataFrame(T_sa_sa, index=sa_labels, columns=sa_labels)
        M_derived = pd.DataFrame(M_derived, index=sa_labels, columns=sa_labels)
        M_red = pd.DataFrame(M_red, index=sa_labels, columns=sa_labels)
    
    elif timepoint == 'post':

        ### Define matrices after Re-Learning in transition revaluation condition

        ## Successor Matrix M
        M = df_sr.loc[147, 'OS1A1-S1A1':'OS10A1-S10A1'].to_numpy().reshape(13,13).astype(float)

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

        ## M derived from T sa sa
        M_derived = compute_t_based_sr_matrix(T_sa_sa, gamma)

        ## Reduced successor matrix redM
        M_red = np.zeros((13,13))
        M_red_cols = df_red_sr.loc[147, 'WS2A1':'OS1A2-S1A2'].to_numpy().reshape(13,2).astype(float)
        if condition == 'transition':
            M_red[:, 10:12] = M_red_cols
        elif condition == 'goal':
            M_red[:, [9, 11]] = M_red_cols


        ## Transform all matrices to pd df
        M = pd.DataFrame(M, index=sa_labels, columns=sa_labels)
        T_sa_s = pd.DataFrame(T_sa_s, index=sa_labels, columns=s_labels)
        T_sa_sa = pd.DataFrame(T_sa_sa, index=sa_labels, columns=sa_labels)
        M_derived = pd.DataFrame(M_derived, index=sa_labels, columns=sa_labels)
        M_red = pd.DataFrame(M_red, index=sa_labels, columns=sa_labels)

    ### Plotting and result logging  

    ## Correlation between SR and M-derived SR matrix
    corr_M_Mred = upper_triangular_correlation(M, M_red)
    corr_M_Mder = upper_triangular_correlation(M, M_derived)
    corr_M_T = upper_triangular_correlation(M, T_sa_sa)
    corr_Mred_Mder = upper_triangular_correlation(M_red, M_derived)
    corr_Mred_T = upper_triangular_correlation(M_red, T_sa_sa)
    corr_Mder_T = upper_triangular_correlation(M_derived, T_sa_sa)

    ## create plot
    plot_matrices(condition, timepoint, beta, M, M_red, T_sa_s, M_derived)

    ## append to results df
    results_df.loc[len(results_df)] = {'beta': beta, 'corr_M_Mred': corr_M_Mred, 'corr_M_Mder': corr_M_Mder, 'corr_M_T': corr_M_T, 'corr_Mred_Mder': corr_Mred_Mder, 'corr_Mred_T': corr_Mred_T, 'corr_Mder_T': corr_Mder_T}

# save correlation table
results_df.to_csv(f"results/correlations_{condition}_{timepoint}.txt", sep='\t', index=False)

    
