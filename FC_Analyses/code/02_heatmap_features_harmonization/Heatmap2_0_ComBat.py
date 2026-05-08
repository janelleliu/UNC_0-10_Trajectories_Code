from neuroCombat import neuroCombat
import pandas as pd
import numpy as np
import nibabel as nib
import os

def extract_indexed_mask_data(mask_data, data_data):
  """
  Loaded an index mask and data NIfTI file, and extracts the data vector
  of whole-brain voxels, keeping the order specified by the index mask.

  Args:
    mask_data: data of the index mask NIfTI file.
    data_data: data of the data NIfTI file.

  Returns:
    A 1D numpy array containing the masked data in the index order.
  """

  # Ensure the mask and data have the same dimensions
  if mask_data.shape!= data_data.shape:
    raise ValueError("Mask and data files have different dimensions.")

  # Find the unique indices in the mask (assuming they are 1 to 15450)
  unique_indices = np.unique(mask_data)
  unique_indices = unique_indices[unique_indices > 0]  # Exclude zero

  # Initialize an empty array to store the masked data
  masked_data_vector = np.zeros(len(unique_indices))

  # Extract data for each index
  for i, index in enumerate(unique_indices):
    masked_data_vector[i] = data_data[mask_data == index][0]

  # Return the masked data vector
  return masked_data_vector

voxelpar_file = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/templates/infant-2yr-4mm-mask-inds.nii.gz'
voxelpar_img = nib.load(voxelpar_file)
voxelpar_data = voxelpar_img.get_fdata()

measures = ['Gradient2_AlignedToHCP']  ##!!  'Str', 'Enodal', 'Elocal', 'McosSim2', 'Gradient1_AlignedToHCP', 
for measure in measures:
  label = '_8mm2' if measure in ['Str', 'BC', 'Enodal', 'Elocal'] else ''
  if measure in ['Gradient1_AlignedToHCP', 'Gradient2_AlignedToHCP']:
    datapath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Gradient1_Gradients_results_AlignedToHCP/'  ##!!  
  else:
    datapath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/New_heatmaps_results/' + measure + label + '/'  ##!!  
  outputpath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/0NewCompleteAnalyses/Heatmap2_New_heatmaps_results/0_ComBat/'
  outputdir = outputpath + measure + label + '/'
  os.makedirs(outputdir, exist_ok=True)


  ## 0 1 2 4 6 separately

  ages = ['neonate', 'oneyear', 'twoyear', 'fouryear', 'sixyear']  ##!!  
  ages_s = ['0', '1', '2', '4', '6']  ##!!  
  for aa in range(len(ages)):
      age = ages[aa]
      age_s = ages_s[aa]
      listpath = '/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/'  ##!!  
      subjects = np.loadtxt(listpath + age_s + '_full_subject_updated_final_twinPick.txt', dtype=str)  ##!!  
      masked_data_vectors = []
      for subj in subjects:
          #print(subj)
          in_file = datapath + age + '/' + subj + '_' + measure + '_Heatmap_' + age + '.nii.gz'
          in_img = nib.load(in_file)
          in_data = in_img.get_fdata()
          masked_data_vector = extract_indexed_mask_data(voxelpar_data, in_data)
          masked_data_vectors.append(masked_data_vector)
      data_matrix = np.column_stack(masked_data_vectors)
      print(data_matrix.shape)  # Output the shape of the extracted data matrix
      Covs = np.genfromtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/M_FC_Z_Covs_twinPick_All/M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_'+age+'.csv', delimiter=",", skip_header=1)
      GAS = Covs[:, 2]
      Sex = Covs[:, 4]
      Scanner = Covs[:, 5]
      Scanner[Scanner == 5] = 4 ## Combine Scanner 4/5 to 4  
      print(Scanner.shape)  # Output the shape of the extracted vector

      # Specifying the batch (Scanner variable) as well as a biological covariate (GAS, Sex variables) to preserve:
      covars = {'Scanner':Scanner,
              'GAS':GAS,
              'Sex':Sex} 
      covars = pd.DataFrame(covars)  

      # To specify names of the variables that are categorical/continuous:
      categorical_cols = ['Sex']
      continuous_cols = ['GAS']

      # To specify the name of the variable that encodes for the scanner/batch covariate:
      batch_col = 'Scanner'

      #Harmonization step:
      data_combat = neuroCombat(dat=data_matrix,
          covars=covars,
          batch_col=batch_col,
          categorical_cols=categorical_cols,
          continuous_cols=continuous_cols,
          ref_batch=2)["data"] ## Scanner 2 as the reference  
      df = pd.DataFrame(data_combat)
      df.to_csv(outputdir + 'data_combat_' + measure + label + '_' + age_s + '.csv', index=False)  # index=False prevents saving the row index


  ## 8 10 HCP together

  age = 'eightyear'  ##!!  
  age_s = '8'  ##!!  
  listpath = '/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/'  ##!!  
  subjects_8 = np.loadtxt(listpath + age_s + '_full_subject_updated_final_twinPick.txt', dtype=str)  ##!!  
  masked_data_vectors = []
  for subj in subjects_8:
      #print(subj)
      in_file = datapath + age + '/' + subj + '_' + measure + '_Heatmap_' + age + '.nii.gz'
      in_img = nib.load(in_file)
      in_data = in_img.get_fdata()
      masked_data_vector = extract_indexed_mask_data(voxelpar_data, in_data)
      masked_data_vectors.append(masked_data_vector)
  data_matrix_8 = np.column_stack(masked_data_vectors)
  print(data_matrix_8.shape)  # Output the shape of the extracted data matrix
  Covs = np.genfromtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/M_FC_Z_Covs_twinPick_All/M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_'+age+'.csv', delimiter=",", skip_header=1)
  GAS_8 = Covs[:, 2]
  Sex_8 = Covs[:, 4]
  Scanner_8 = Covs[:, 5]
  Scanner_8[Scanner_8 == 5] = 4 ## Combine Scanner 4/5 to 4  
  print(Scanner_8.shape)  # Output the shape of the extracted vector

  age = 'tenyear'  ##!!  
  age_s = '10'  ##!!  
  listpath = '/media/zhark2/glab6/Project_Replication/Preprocessed_Data/UNC/lists_0.3mm/'  ##!!  
  subjects_10 = np.loadtxt(listpath + age_s + '_full_subject_updated_final_twinPick.txt', dtype=str)  ##!!  
  masked_data_vectors = []
  for subj in subjects_10:
      #print(subj)
      in_file = datapath + age + '/' + subj + '_' + measure + '_Heatmap_' + age + '.nii.gz'
      in_img = nib.load(in_file)
      in_data = in_img.get_fdata()
      masked_data_vector = extract_indexed_mask_data(voxelpar_data, in_data)
      masked_data_vectors.append(masked_data_vector)
  data_matrix_10 = np.column_stack(masked_data_vectors)
  print(data_matrix_10.shape)  # Output the shape of the extracted data matrix
  Covs = np.genfromtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/M_FC_Z_Covs_twinPick_All/M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_'+age+'.csv', delimiter=",", skip_header=1)
  GAS_10 = Covs[:, 2]
  Sex_10 = Covs[:, 4]
  Scanner_10 = Covs[:, 5]
  Scanner_10[Scanner_10 == 5] = 4 ## Combine Scanner 4/5 to 4  
  print(Scanner_10.shape)  # Output the shape of the extracted vector

  age = 'HCP'  ##!!  
  age_s = 'HCP'  ##!!  
  listpath = '/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/lists_0.3mm/'  ##!!  
  subjects_HCP = np.loadtxt(listpath + age_s + '_full_subject_updated_final.txt', dtype=str)  ##!!  
  masked_data_vectors = []
  for subj in subjects_HCP:
      #print(subj)
      in_file = datapath + age + '/' + subj + '_' + measure + '_Heatmap_' + age + '.nii.gz'
      in_img = nib.load(in_file)
      in_data = in_img.get_fdata()
      masked_data_vector = extract_indexed_mask_data(voxelpar_data, in_data)
      masked_data_vectors.append(masked_data_vector)
  data_matrix_HCP = np.column_stack(masked_data_vectors)
  print(data_matrix_HCP.shape)  # Output the shape of the extracted data matrix
  Covs = np.genfromtxt('/media/zhark2/glab7/Haitao/UNC_Trajectory_heatmaps/M_FC_Z_Covs_twinPick_All/M_FC_Z_Covs_twinPick_All_0.3mm_notr90_UNC_'+age+'.csv', delimiter=",", skip_header=1)
  GAS_HCP = Covs[:, 2]
  Sex_HCP = Covs[:, 4]
  Scanner_HCP = Covs[:, 5]
  Scanner_HCP[Scanner_HCP == 5] = 4 ## Combine Scanner 4/5 to 4  
  print(Scanner_HCP.shape)  # Output the shape of the extracted vector

  data_matrix = np.hstack((data_matrix_8, data_matrix_10, data_matrix_HCP))
  print(data_matrix.shape)  # Output the shape of the extracted data matrix
  GAS = np.concatenate((GAS_8, GAS_10, GAS_HCP))
  Sex = np.concatenate((Sex_8, Sex_10, Sex_HCP))
  Scanner = np.concatenate((Scanner_8, Scanner_10, Scanner_HCP))
  print(Scanner.shape)  # Output the shape of the extracted vector

  # Specifying the batch (Scanner variable) as well as a biological covariate (GAS, Sex variables) to preserve:
  covars = {'Scanner':Scanner,
            'GAS':GAS,
            'Sex':Sex} 
  covars = pd.DataFrame(covars)  

  # To specify names of the variables that are categorical/continuous:
  categorical_cols = ['Sex']
  continuous_cols = ['GAS']

  # To specify the name of the variable that encodes for the scanner/batch covariate:
  batch_col = 'Scanner'

  #Harmonization step:
  data_combat = neuroCombat(dat=data_matrix,
      covars=covars,
      batch_col=batch_col,
      categorical_cols=categorical_cols,
      continuous_cols=continuous_cols,
      ref_batch=2)["data"] ## Scanner 2 as the reference  

  data_combat_8 = data_combat[:, :len(subjects_8)]
  data_combat_10 = data_combat[:, len(subjects_8):len(subjects_8)+len(subjects_10)]
  data_combat_HCP = data_combat[:, len(subjects_8)+len(subjects_10):]

  df_8 = pd.DataFrame(data_combat_8)
  df_8.to_csv(outputdir + 'data_combat_' + measure + label + '_8.csv', index=False)  # index=False prevents saving the row index
  df_10 = pd.DataFrame(data_combat_10)
  df_10.to_csv(outputdir + 'data_combat_' + measure + label + '_10.csv', index=False)  # index=False prevents saving the row index
  df_HCP = pd.DataFrame(data_combat_HCP)
  df_HCP.to_csv(outputdir + 'data_combat_' + measure + label + '_HCP.csv', index=False)  # index=False prevents saving the row index

