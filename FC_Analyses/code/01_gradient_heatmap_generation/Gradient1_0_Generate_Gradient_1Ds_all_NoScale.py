import numpy as np
from brainspace.gradient import GradientMaps
import matplotlib.pyplot as plt
import os

#ages_label = ['HCP', 'neonate_twinPick_32W_Healthy', 'oneyear_twinPick_32W_Healthy', 'twoyear_twinPick_32W_Healthy', 'fouryear_twinPick_32W_Healthy', 'sixyear_twinPick_32W_Healthy', 'eightyear_twinPick_32W_Healthy', 'tenyear_twinPick_32W_Healthy'];  ##!!    ##!!  
#ages = ['HCP', 'neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear', 'eightyear', 'tenyear'];  ##!!    ##!!  
#ages_str = ['HCP', '0', '1', '2', '4', '6', '8', '10'];  ##!!    ##!!  
ages_label = ['tenyear_twinPick_32W_Healthy']  ##!!    ##!!  each a time, in multiple cmd windows parallel!!!!    
ages = ['tenyear']  ##!!    ##!!  each a time, in multiple cmd windows parallel!!!!    
ages_str = ['10']  ##!!    ##!!  each a time, in multiple cmd windows parallel!!!!    

conn_matrix_ori = np.loadtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/FC_Matrices/fouryear_twinPick_32W_Healthy_mean_FC_M.1D')
np.fill_diagonal(conn_matrix_ori, 1.832)  ##!!  replace inf(r=1) with 1.832(r=0.95)
gori = GradientMaps(n_components=10, approach='dm', kernel='cosine', random_state=0)  ##!!    ##!!  dm  
gori.fit(conn_matrix_ori)

ref_age = 'HCP'  ##!!    ##!!  HCP as reference    (to avoid data leakage)
conn_matrix_ref = np.loadtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/FC_Matrices/' + ref_age + '_mean_FC_M.1D')
np.fill_diagonal(conn_matrix_ref, 1.832)  ##!!  replace inf(r=1) with 1.832(r=0.95)
gref = GradientMaps(n_components=10, approach='dm', kernel='cosine', random_state=0, alignment='procrustes')  ##!!    ##!!  dm  
gref.fit(conn_matrix_ref, reference=gori.gradients_)

for aa in range(len(ages_label)):
    age_label = ages_label[aa]
    age = ages[aa]
    age_str = ages_str[aa]
    datapath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/FC_Matrices/'
    datadir = datapath + age + '/'
    outputpath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient1_Gradients_results_AlignedToHCP/'  ##!!    ##!!  
    outputdir = outputpath + age + '/'
    os.makedirs(outputdir, exist_ok=True)
    outputpath1 = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient1_Original_all10Gradients/'  ##!!    ##!!  
    outputdir1 = outputpath1 + age + '/'
    os.makedirs(outputdir1, exist_ok=True)
    outputpath2 = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient1_AlignedToHCP_all10Gradients/'  ##!!    ##!!  
    outputdir2 = outputpath2 + age + '/'
    os.makedirs(outputdir2, exist_ok=True)
    subjects = np.loadtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/lists_0.3mm/' + age_str + '_full_subject_updated_final.txt', dtype=str)  ##!!  

    # conn_matrix_ref = np.loadtxt(datapath + age_label + '_mean_FC_M.1D') ## align to aligned mean twinPick Normal
    # np.fill_diagonal(conn_matrix_ref, 1.832)  ##!!  replace inf(r=1) with 1.832(r=0.95)
    # gref = GradientMaps(n_components=10, approach='dm', kernel='cosine', random_state=0, alignment='procrustes')  ##!!    ##!!  
    # gref.fit(conn_matrix_ref, reference=gref_fouryear.gradients_)

    for subj in subjects:
        conn_matrix = np.loadtxt(datadir + subj + '_voxelpar_2yrspace_ROI_FC_Z_matrix.1D')
        np.fill_diagonal(conn_matrix, 1.832)  ##!!  replace inf(r=1) with 1.832(r=0.95)
        galign = GradientMaps(n_components=10, approach='dm', kernel='cosine', random_state=0, alignment='procrustes')  ##!!    ##!!  
        galign.fit(conn_matrix, reference=gref.aligned_)  ##!!  ##!!  

        np.savetxt(outputdir1 + subj + '_all10Gradients_Heatmap_' + age + '.1D', galign.gradients_)  ##!!    ##!!  Save original unaligned all 10 Gradients    
        np.savetxt(outputdir2 + subj + '_all10Gradients_AlignedToHCP_Heatmap_' + age + '.1D', galign.aligned_)  ##!!    ##!!  Save aligned all 10 Gradients    

        np.savetxt(outputdir + subj + '_Gradients_Lambdas_' + age + '.1D', galign.lambdas_)

        np.savetxt(outputdir + subj + '_Gradient1_Heatmap_' + age + '.1D', galign.gradients_[:, 0])
        np.savetxt(outputdir + subj + '_Gradient2_Heatmap_' + age + '.1D', galign.gradients_[:, 1])
        np.savetxt(outputdir + subj + '_Gradient3_Heatmap_' + age + '.1D', galign.gradients_[:, 2])  ##!!  this is still not aglined! 

        fig, ax = plt.subplots(1, figsize=(5, 4))
        ax.scatter(range(galign.lambdas_.size), galign.lambdas_)
        ax.set_xlabel('Component Nb')
        ax.set_ylabel('Eigenvalue')
        plt.savefig(outputdir + subj + '_Gradients_Lambdas_' + age + '.png') ## this is the original lambdas - no lambdas for aligned gradients from brainspace, may use gradient variance/gradient range to estimate
        plt.close()  ##!!  

        unaligned_var = np.var(galign.gradients_, axis=0)
        np.savetxt(outputdir + subj + '_Gradients_GradVars_' + age + '.1D', unaligned_var)
        fig, ax = plt.subplots(1, figsize=(5, 4))
        ax.scatter(range(unaligned_var.size), unaligned_var)
        ax.set_xlabel('Component Nb')
        ax.set_ylabel('Gradient Variance')
        plt.savefig(outputdir + subj + '_Gradients_GradVars_' + age + '.png') ## this is the original unaligned gradient variance, to estimate lambdas
        plt.close()  ##!!  

        unaligned_ran = np.ptp(galign.gradients_, axis=0)
        np.savetxt(outputdir + subj + '_Gradients_GradRans_' + age + '.1D', unaligned_ran)
        fig, ax = plt.subplots(1, figsize=(5, 4))
        ax.scatter(range(unaligned_ran.size), unaligned_ran)
        ax.set_xlabel('Component Nb')
        ax.set_ylabel('Gradient Range')
        plt.savefig(outputdir + subj + '_Gradients_GradRans_' + age + '.png') ## this is the original unaligned gradient range, to estimate lambdas
        plt.close()  ##!!  

        np.savetxt(outputdir + subj + '_Gradient1_AlignedToHCP_Heatmap_' + age + '.1D', galign.aligned_[:, 0])
        np.savetxt(outputdir + subj + '_Gradient2_AlignedToHCP_Heatmap_' + age + '.1D', galign.aligned_[:, 1])
        np.savetxt(outputdir + subj + '_Gradient3_AlignedToHCP_Heatmap_' + age + '.1D', galign.aligned_[:, 2])  ##!!  this is aglined! 

        aligned_var = np.var(galign.aligned_, axis=0)
        np.savetxt(outputdir + subj + '_Gradients_GradVars_AlignedToHCP_' + age + '.1D', aligned_var)
        fig, ax = plt.subplots(1, figsize=(5, 4))
        ax.scatter(range(aligned_var.size), aligned_var)
        ax.set_xlabel('Component Nb')
        ax.set_ylabel('Gradient Variance')
        plt.savefig(outputdir + subj + '_Gradients_GradVars_AlignedToHCP_' + age + '.png') ## this is the post aligned gradient variance, to estimate lambdas
        plt.close()  ##!!  

        aligned_ran = np.ptp(galign.aligned_, axis=0)
        np.savetxt(outputdir + subj + '_Gradients_GradRans_AlignedToHCP_' + age + '.1D', aligned_ran)
        fig, ax = plt.subplots(1, figsize=(5, 4))
        ax.scatter(range(aligned_ran.size), aligned_ran)
        ax.set_xlabel('Component Nb')
        ax.set_ylabel('Gradient Range')
        plt.savefig(outputdir + subj + '_Gradients_GradRans_AlignedToHCP_' + age + '.png') ## this is the post aligned gradient range, to estimate lambdas
        plt.close()  ##!!  
