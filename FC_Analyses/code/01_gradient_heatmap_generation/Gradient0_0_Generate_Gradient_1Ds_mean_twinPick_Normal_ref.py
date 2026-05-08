import numpy as np
from brainspace.gradient import GradientMaps
import matplotlib.pyplot as plt
import os

ages_label = ['HCP', 'neonate_twinPick_32W_Healthy', 'oneyear_twinPick_32W_Healthy', 'twoyear_twinPick_32W_Healthy', 'fouryear_twinPick_32W_Healthy', 'sixyear_twinPick_32W_Healthy', 'eightyear_twinPick_32W_Healthy', 'tenyear_twinPick_32W_Healthy'];  ##!!    ##!!  

#for ref_age in ages_label:

conn_matrix_ori = np.loadtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/FC_Matrices/fouryear_twinPick_32W_Healthy_mean_FC_M.1D')
np.fill_diagonal(conn_matrix_ori, 1.832)  ##!!  replace inf(r=1) with 1.832(r=0.95)
gori = GradientMaps(n_components=10, approach='dm', kernel='cosine', random_state=0)  ##!!    ##!!  dm  
gori.fit(conn_matrix_ori)

ref_age = 'HCP'  ##!!    ##!!  HCP as reference    (to avoid data leakage)
conn_matrix_ref = np.loadtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/FC_Matrices/' + ref_age + '_mean_FC_M.1D')
np.fill_diagonal(conn_matrix_ref, 1.832)  ##!!  replace inf(r=1) with 1.832(r=0.95)
gref = GradientMaps(n_components=10, approach='dm', kernel='cosine', random_state=0, alignment='procrustes')  ##!!    ##!!  dm  
gref.fit(conn_matrix_ref, reference=gori.gradients_)


outputpath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient0_Gradients_results_ref_dm/'  ##!!    ##!!  
os.makedirs(outputpath, exist_ok=True)
np.savetxt(outputpath + ref_age + '_mean_FC_M_Lambdas.1D', gref.lambdas_)

np.savetxt(outputpath + ref_age + '_mean_FC_M_Gradient1.1D', gref.aligned_[:, 0])
np.savetxt(outputpath + ref_age + '_mean_FC_M_Gradient2.1D', gref.aligned_[:, 1])
np.savetxt(outputpath + ref_age + '_mean_FC_M_Gradient3.1D', gref.aligned_[:, 2])  ##!!  this is aglined! 


for age_label in ages_label:
    conn_matrix = np.loadtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/FC_Matrices/' + age_label + '_mean_FC_M.1D')
    np.fill_diagonal(conn_matrix, 1.832)  ##!!  replace inf(r=1) with 1.832(r=0.95)
    galign = GradientMaps(n_components=10, approach='dm', kernel='cosine', random_state=0, alignment='procrustes')  ##!!  ##!!  
    galign.fit(conn_matrix, reference=gref.aligned_)  ##!!  ##!!  
    
    outputpath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient0_Gradients_results_ref_dm/Gradients_results_AlignedToHCP/'  ##!!    ##!!  
    os.makedirs(outputpath, exist_ok=True)
    np.savetxt(outputpath + age_label + '_mean_FC_M_Lambdas.1D', galign.lambdas_)

    np.savetxt(outputpath + age_label + '_mean_FC_M_Gradient1.1D', galign.gradients_[:, 0])
    np.savetxt(outputpath + age_label + '_mean_FC_M_Gradient2.1D', galign.gradients_[:, 1])
    np.savetxt(outputpath + age_label + '_mean_FC_M_Gradient3.1D', galign.gradients_[:, 2])  ##!!  this is still not aglined! 

    fig, ax = plt.subplots(1, figsize=(5, 4))
    ax.scatter(range(galign.lambdas_.size), galign.lambdas_)
    ax.set_xlabel('Component Nb')
    ax.set_ylabel('Eigenvalue')
    plt.savefig(outputpath + age_label + '_mean_FC_M_Lambdas.png') ## this is the original lambdas - no lambdas for aligned gradients from brainspace, may use gradient variance/gradient range to estimate
    plt.close()  ##!!  

    unaligned_var = np.var(galign.gradients_, axis=0)
    np.savetxt(outputpath + age_label + '_mean_FC_M_GradVars.1D', unaligned_var)
    fig, ax = plt.subplots(1, figsize=(5, 4))
    ax.scatter(range(unaligned_var.size), unaligned_var)
    ax.set_xlabel('Component Nb')
    ax.set_ylabel('Gradient Variance')
    plt.savefig(outputpath + age_label + '_mean_FC_M_GradVars.png') ## this is the original unaligned gradient variance, to estimate lambdas
    plt.close()  ##!!  

    unaligned_ran = np.ptp(galign.gradients_, axis=0)
    np.savetxt(outputpath + age_label + '_mean_FC_M_GradRans.1D', unaligned_ran)
    fig, ax = plt.subplots(1, figsize=(5, 4))
    ax.scatter(range(unaligned_ran.size), unaligned_ran)
    ax.set_xlabel('Component Nb')
    ax.set_ylabel('Gradient Range')
    plt.savefig(outputpath + age_label + '_mean_FC_M_GradRans.png') ## this is the original unaligned gradient range, to estimate lambdas
    plt.close()  ##!!  

    np.savetxt(outputpath + age_label + '_mean_FC_M_Gradient1_AlignedToHCP.1D', galign.aligned_[:, 0])
    np.savetxt(outputpath + age_label + '_mean_FC_M_Gradient2_AlignedToHCP.1D', galign.aligned_[:, 1])
    np.savetxt(outputpath + age_label + '_mean_FC_M_Gradient3_AlignedToHCP.1D', galign.aligned_[:, 2])  ##!!  this is aglined! 

    aligned_var = np.var(galign.aligned_, axis=0)
    np.savetxt(outputpath + age_label + '_mean_FC_M_GradVars_AlignedToHCP.1D', aligned_var)
    fig, ax = plt.subplots(1, figsize=(5, 4))
    ax.scatter(range(aligned_var.size), aligned_var)
    ax.set_xlabel('Component Nb')
    ax.set_ylabel('Gradient Variance')
    plt.savefig(outputpath + age_label + '_mean_FC_M_GradVars_AlignedToHCP.png') ## this is the post aligned gradient variance, to estimate lambdas
    plt.close()  ##!!  

    aligned_ran = np.ptp(galign.aligned_, axis=0)
    np.savetxt(outputpath + age_label + '_mean_FC_M_GradRans_AlignedToHCP.1D', aligned_ran)
    fig, ax = plt.subplots(1, figsize=(5, 4))
    ax.scatter(range(aligned_ran.size), aligned_ran)
    ax.set_xlabel('Component Nb')
    ax.set_ylabel('Gradient Range')
    plt.savefig(outputpath + age_label + '_mean_FC_M_GradRans_AlignedToHCP.png') ## this is the post aligned gradient range, to estimate lambdas
    plt.close()  ##!!  
