from torch.utils.data import Dataset
import numpy as np
import torchvision.transforms as transforms
import scipy.io as io
import os
from util.transform import *
import pandas as pd
import matplotlib.pyplot as plt
import torchio as tio
from util.xgboost import XGBRegressor
from util.metrics import age_to_norm, norm_to_age
import nibabel as nib
import random
from monai.transforms import Compose as MonaiCompose, RandBiasField, RandGaussianNoise, RandAdjustContrast
import torch
import scipy.stats

class DynamicNormalize:
    def __call__(self, img):
        c = img.shape[0]  # Get number of channels
        mean = [0.5] * c
        std = [0.5 + 1e-8] * c  # Add a small epsilon to avoid division by zero
        return transforms.functional.normalize(img, mean, std)

train_transforms = transforms.Compose([
    transforms.ToTensor(),
    transforms.CenterCrop((224,192)),
    transforms.Lambda(lambda x: x / (x.max() + 1e-8)),  # Normalize to [0, 1] with epsilon
    DynamicNormalize()  # Applies proper normalization based on channels
])

test_transforms = transforms.Compose([
    transforms.ToTensor(),
    transforms.CenterCrop((224,192)),
    transforms.Lambda(lambda x: x / (x.max() + 1e-8)),  # Normalize to [0, 1] with epsilon
    DynamicNormalize()  # Applies proper normalization based on channels
])

train_transforms_func = transforms.Compose([
    transforms.ToTensor(),
    #transforms.CenterCrop((224,192)),
    transforms.Lambda(lambda x: x / (x.max() + 1e-8)),  # Normalize to [0, 1] with epsilon
    DynamicNormalize()  # Applies proper normalization based on channels
])

test_transforms_func = transforms.Compose([
    transforms.ToTensor(),
    #transforms.CenterCrop((224,192)),
    transforms.Lambda(lambda x: x / (x.max() + 1e-8)),  # Normalize to [0, 1] with epsilon
    DynamicNormalize()  # Applies proper normalization based on channels
])

def age_to_gaussian_vec(age_days: float,
                        bins: int = 1024,
                        bin_width: int = 4,
                        sigma: float = 90.0) -> torch.Tensor:
    centres = torch.arange(bins, dtype=torch.float32) * bin_width        # 0, 4, 8, … , 4092
    vec = torch.exp(-0.5 * ((centres - age_days) / sigma) ** 2)
    vec /= vec.sum() + 1e-8                                              # normalise to sum = 1
    return vec                                                           # shape (1024,)

# ---------------- FixMatch strong augmentation --------------------
strong_intensity = MonaiCompose([
    RandBiasField(prob=0.5),
    RandGaussianNoise(prob=0.3, mean=0.0, std=0.05),
    RandAdjustContrast(prob=0.3)
])

strong_transforms_func = transforms.Compose([
    transforms.ToTensor(),
    transforms.Lambda(lambda x: x / (x.max() + 1e-8)),
    transforms.Lambda(lambda x: strong_intensity(x)),
    DynamicNormalize(),
])
# ------------------------------------------------------------------

def load_features(all_features, subject_id):
    features = []
    for modName in all_features.keys():
        #concat all_features[modName][subject_id]
        if subject_id is not None:
            #if key [modName][subject_id] does not exist, pad with 0
            if subject_id not in all_features[modName]:
                features.append(np.zeros((176,42)))
                print('Feature not found for subject_id:', subject_id)
            else:
                features.append(all_features[modName][subject_id])
        #print(features)
    features = np.array(features)  # shape:[name,176,42]
    features = torch.tensor(features, dtype=torch.float32)
    #print(features.shape)
    feature_dim = features.shape[0]*features.shape[1]*features.shape[2]
    return features, feature_dim

class ConcatDataset(Dataset):
    def __init__(self, input_folder, map_folder, guide_path = '', mode = '', subject_id=None, radiomics_folder=None, addxgb=None,
                 img_channels=['Elocal', 'Enodal', 'Gradient1', 'Gradient2', 'McosSim2', 'Str', 'T1w'], lim=None):
        self.mode = mode
        source_df = pd.read_csv(guide_path)

        data = []
        
        if mode:
            source_df = source_df[source_df['mode']==mode]
        if subject_id:
            source_df = source_df[(source_df['Subject ID']==subject_id['Subject']) & (source_df['Age']==subject_id['Age'])]
            
        grouped_df = source_df.groupby(['Subjects','AgeYear','GASDay'])
        dataset_type = os.path.basename(guide_path).split('_')[0]

        index = 0
        # Iterate over each group, no age
        for (id,ageyear,age), group in grouped_df: 
            index += 1
            if lim is not None and (index > lim):
                break

            img_list = []
            for mod in img_channels:
                img_list.append(os.path.join(input_folder, mod, id, str(age)))

            if addxgb is not None:
                pred = XGBRegressor(id, age, sex, addxgb)
            else:
                pred = 0
            #subject_features, feature_dim = load_features(all_features, id + '_' + str(age))
            #print(subject_features.shape)
            # Get a sorted list of slice filenames from the first image path
            slice_files = sorted(os.listdir(img_list[0]), key=lambda x: int(x.split('.')[0]))
            # Select only the middle 30 slices if there are more than 30
            if len(slice_files) > 20:
                start_index = (len(slice_files) - 20) // 2
                slice_files = slice_files[start_index : start_index + 20]

            for slice in slice_files:
                slice_list = []
                for cur_path in img_list:
                    slice_path = os.path.join(cur_path, slice)
                    slice_list.append(slice_path)
                
                slice_num = int(slice[:-4])

                info = {'Subject':id,
                        'Ageyear': ageyear,
                        'Age':age,
                        'Slice': slice_num,
                        'img_path':slice_list,
                        'xgb_age':pred
                        #'radiomics_features': subject_features
                        }
            
                data.append(info)

        self.data = data
        self.length=len(data)
        #print(self.length)
    
    def __getitem__(self,index):
        info = self.data[index]
        age = info['Age']
        ageyear = info['Ageyear']
        slice = info['Slice']
        name = info['Subject']
        xgb_age = info['xgb_age']

        all_channels = []
        for cur_path in info['img_path']:
            if cur_path is None:
                continue
    
            tmp = np.load(cur_path)
                #print [100:120][100:120] of tmp
            #print(tmp[100:120,100:120])
                #tmp size is (240, 211, 1), we need to remove the last dimension
            tmp = np.squeeze(tmp)
            tmp = tmp /tmp.max()
                #print(tmp[100:120,100:120])
            all_channels.append(tmp)
        
        all_channels = np.stack(all_channels, axis=2)
        all_channels = np.rot90(all_channels, axes=(0,1)).copy()

        if self.mode == 'test':
            cur_slice = test_transforms_func(all_channels)
        else:
            cur_slice = train_transforms_func(all_channels)

        cur_slice = torch.tensor(cur_slice, dtype=torch.float32)
        #if cur_slice has nan, fill with 0
        cur_slice = torch.nan_to_num(cur_slice, nan=0.0)
        #print(cur_slice)
        #print("Images Tensor Min:", cur_slice.min().item(), "Max:", cur_slice.max().item())
        #print("Images Tensor Mean:", cur_slice.mean().item())

        # Normalize age from range 200–3000 to 0–1 using log10, with helper functions

        norm_age = age_to_norm(age)
        value_age = torch.tensor([norm_age], dtype=torch.float32)
        return cur_slice, value_age, name, ageyear, xgb_age

    def __len__(self):
        return self.length

class SSLDataset(Dataset):
    """
    Semi-supervised dataset that mimics FixMatch sampling.

    * Weak  view  → `train_transforms_func`
    * Strong view → `strong_transforms_func`

    The CSV in `guide_path` **must** have at least the columns:
        ['Subjects', 'AgeYear', 'GASDay'] + any names in `label_name`.

    Parameters
    ----------
    label_name   : list[str]
        Extra column names treated as external labels.
    label_ratio  : float | None
        Desired fraction of *labelled* samples drawn in each `__getitem__`.
        e.g. 0.125 for a 1:7 label:unlabel ratio.  If None → purely random.
    """

    def __init__(self,
                 input_folder: str,
                 map_folder:   str,          # kept for API consistency
                 guide_path:   str,
                 mode:         str = '',
                 subject_id:   dict | None = None,
                 img_channels: list = ['Elocal', 'Enodal',
                                       'Gradient1', 'Gradient2',
                                       'McosSim2', 'Str', 'T1w'],
                 lim:          int | None = None,
                 label_name:   list | None = None,
                 label_ratio:  float | None = None):

        super().__init__()
        self.mode         = mode
        self.img_channels = img_channels
        self.label_cols   = label_name or []
        self.label_ratio  = label_ratio            # e.g. 0.125  (None → random)
        self.weak_tf      = train_transforms_func if mode != 'test' else test_transforms_func
        self.strong_tf    = strong_transforms_func
        self.gamma        = 5.0  # for skewed Gaussian

        # ------------------------------------------------------------------
        # 1. Read guide CSV and (optionally) filter rows
        # ------------------------------------------------------------------
        df = pd.read_csv(guide_path)

        if mode:
            df = df[df['mode'] == mode]
        if subject_id:
            df = df[(df['Subject ID'] == subject_id['Subject']) &
                    (df['Age']        == subject_id['Age'])]

        # Compute mean and std of the first label column if present
        if self.label_cols and self.label_cols[0] in df.columns:
            label_vals = df[self.label_cols[0]].dropna().astype(float)
            self.label_mu = label_vals.mean()
            self.label_std = label_vals.std() if label_vals.std() > 0 else 1.0
        else:
            self.label_mu = 0.0
            self.label_std = 1.0

        # ------------------------------------------------------------------
        # 2. Build two pools: labelled vs. unlabelled
        # ------------------------------------------------------------------
        self.labelled_data, self.unlabelled_data = [], []
        grouped = df.groupby(['Subjects', 'AgeYear', 'GASDay'])

        for (sid, ageyear, age), grp in grouped:

            # Sampling duplication by AgeYear
            dup = 1
            if ageyear in [6, 8]:
                dup = 2
            elif ageyear == 10:
                dup = 3

            # Paths to modal folders
            slice_dirs = [os.path.join(input_folder, m, sid, str(age))
                          for m in img_channels]
            if not os.path.isdir(slice_dirs[0]):
                continue  # skip subject if first modality missing

            # Slice list (take median 20 if >20 slices)
            slice_files = sorted(os.listdir(slice_dirs[0]),
                                 key=lambda x: int(x.split('.')[0]))
            if len(slice_files) > 20:
                mid = (len(slice_files) - 20) // 2
                slice_files = slice_files[mid: mid + 20]

            # Does this subject have ALL requested external labels?
            row0       = grp.iloc[0]
            ext_labels = {c: row0.get(c, np.nan) for c in self.label_cols}
            has_labels = all(not pd.isna(v) for v in ext_labels.values())
            #print(ext_labels, has_labels)

            target_pool = self.labelled_data if has_labels else self.unlabelled_data

            for _ in range(dup):
                for sfile in slice_files:
                    sample = dict(
                        Subject=sid,
                        Ageyear=ageyear,
                        Age=age,
                        Slice=int(sfile[:-4]),
                        img_paths=[os.path.join(d, sfile) for d in slice_dirs],
                        ext_labels=ext_labels,
                        is_labelled=has_labels
                    )
                    target_pool.append(sample)

            if lim and (len(self.labelled_data) + len(self.unlabelled_data) >= lim):
                break

        # Fallback to avoid empty pools
        if not self.labelled_data:
            self.labelled_data = self.unlabelled_data.copy()
        if not self.unlabelled_data:
            self.unlabelled_data = self.labelled_data.copy()

        self.all_data = self.labelled_data + self.unlabelled_data

    # ------------------------------------------------------------------
    # Helper: load numpy slices and produce weak + strong tensors
    # ------------------------------------------------------------------
    def _load_views(self, img_paths: list[str]) -> tuple[torch.Tensor, torch.Tensor]:
        chans = [np.squeeze(np.load(p)) for p in img_paths]
        chans = [c / (c.max() + 1e-8) for c in chans]
        arr   = np.stack(chans, axis=2)          # (H, W, C)
        arr   = np.rot90(arr, axes=(0, 1)).copy()

        weak   = torch.tensor(self.weak_tf(arr),   dtype=torch.float32)
        strong = torch.tensor(self.strong_tf(arr), dtype=torch.float32)

        weak   = torch.nan_to_num(weak,   nan=0.0)
        strong = torch.nan_to_num(strong, nan=0.0)
        return weak, strong

    # ------------------------------------------------------------------
    # PyTorch required methods
    # ------------------------------------------------------------------
    def __len__(self):            # noqa: D401
        """Dataset length (labelled + unlabelled)."""
        return len(self.all_data)

    def __getitem__(self, idx):
        # ---------- choose sample respecting label_ratio ----------
        if self.label_ratio is None or not self.labelled_data or not self.unlabelled_data:
            info = random.choice(self.all_data)
        else:
            info = (random.choice(self.labelled_data)
                    if random.random() < self.label_ratio
                    else random.choice(self.unlabelled_data))

        # ---------- load weak & strong views ----------
        weak_img, strong_img = self._load_views(info['img_paths'])

        # ---------- Gaussian-coded or skewed-coded age label ----------
        if info['is_labelled'] and self.label_cols:
            # Use the first label column for skew
            label = float(info['ext_labels'][self.label_cols[0]])
            b = (label - self.label_mu) / (self.label_std + 1e-8)
            age_vec = self._skewed_age_distribution(float(info['Age']), b)
        else:
            age_vec = age_to_gaussian_vec(float(info['Age']))

        # ---------- external labels tensor ----------
        if info['is_labelled']:
            lbl_vals = [float(info['ext_labels'][c]) / 100.0 for c in self.label_cols]
        else:
            lbl_vals = [0.0] * len(self.label_cols)
        lbl_tensor = torch.tensor(lbl_vals, dtype=torch.float32)

        # ---------- return tuple (matches ConcatDataset ordering) ----------
        return (
            weak_img,          # weakly augmented slice    – Tensor [C,H,W]
            strong_img,        # strongly augmented slice – Tensor [C,H,W]
            age_vec,           # Gaussian-encoded age      – Tensor [1024]
            info['Subject'],   # subject ID (name)
            info['Ageyear'],   # AgeYear integer
            lbl_tensor,        # external labels tensor (zeros if unlabelled)
            info['is_labelled']# bool: True if sample has external labels
        )

    def _skewed_age_distribution(self, age, b, bins=1024, bin_width=4, sigma=90.0):
        """
        Generate a skewed Gaussian PDF over age bins, using scipy.stats.skewnorm.
        - age: center of distribution (in days)
        - b: skewness scaling factor (from label)
        """
        gamma = self.gamma
        alpha = gamma * b
        # Convert alpha to delta for location shift, if needed
        # delta = alpha / np.sqrt(1 + alpha**2)
        centres = torch.arange(bins, dtype=torch.float32) * bin_width
        # Shift mean to keep mean at age
        # scipy.stats.skewnorm loc parameter is the mean of the underlying normal
        # For a symmetric normal, mean = loc. For skewnorm, the mean is shifted.
        # The mean of skewnorm(a, loc, scale) is:
        #   mean = loc + scale * delta * sqrt(2/pi), where delta = alpha / sqrt(1+alpha^2)
        delta = alpha / np.sqrt(1 + alpha**2) if alpha != 0 else 0.0
        mean_shift = sigma * delta * np.sqrt(2 / np.pi)
        loc = age - mean_shift
        pdf = scipy.stats.skewnorm.pdf(centres.numpy(), alpha, loc=loc, scale=sigma)
        pdf = torch.from_numpy(pdf.astype(np.float32))
        pdf /= pdf.sum() + 1e-8
        return pdf

class SSLDatasetFilled(Dataset):
    """
    Semi-supervised dataset variant where *all* samples have ext labels:
    - Missing external labels are imputed with the TRAIN-SET MEAN (per column).
    - No 'has_label' flag is returned (always labeled).
    - Skewed age distribution uses the (possibly imputed) external label.

    The CSV in `guide_path` must have at least:
        ['Subjects', 'AgeYear', 'GASDay'] + any names in `label_name`.
    """

    def __init__(self,
                 input_folder: str,
                 map_folder:   str,          # kept for API consistency
                 guide_path:   str,
                 mode:         str = '',
                 subject_id:   dict | None = None,
                 img_channels: list = ('Elocal','Enodal','Gradient1','Gradient2','McosSim2','Str','T1w'),
                 lim:          int | None = None,
                 label_name:   list | None = None,
                 label_ratio:  float | None = None):

        super().__init__()
        self.mode         = mode
        self.img_channels = list(img_channels)
        self.label_cols   = label_name or []
        self.weak_tf      = train_transforms_func if mode != 'test' else test_transforms_func
        self.strong_tf    = strong_transforms_func
        self.gamma        = 5.0   # for skewed Gaussian

        # -------------------- 1) Load & filter CSV --------------------
        df = pd.read_csv(guide_path)
        if mode:
            df = df[df['mode'] == mode]
        if subject_id:
            df = df[(df['Subject ID'] == subject_id['Subject']) &
                    (df['Age']        == subject_id['Age'])]

        # -------------------- 2) Impute label means (per column) --------------------
        # Compute per-column means over available values
        self.col_means = {}
        for c in self.label_cols:
            if c in df.columns:
                vals = pd.to_numeric(df[c], errors='coerce')
                m = float(vals.mean(skipna=True)) if np.isfinite(vals.mean(skipna=True)) else 0.0
                self.col_means[c] = m
            else:
                self.col_means[c] = 0.0

        # For convenience: also compute mean & std of the *first* label column
        if self.label_cols and self.label_cols[0] in df.columns:
            col0_vals = pd.to_numeric(df[self.label_cols[0]], errors='coerce')
            self.label_mu = float(col0_vals.mean(skipna=True)) if np.isfinite(col0_vals.mean(skipna=True)) else 0.0
            st = float(col0_vals.std(skipna=True))
            self.label_std = st if st and st > 0 else 1.0
        else:
            self.label_mu = 0.0
            self.label_std = 1.0

        # -------------------- 3) Build sample list --------------------
        self.samples = []
        grouped = df.groupby(['Subjects', 'AgeYear', 'GASDay'])

        for (sid, ageyear, age), grp in grouped:
            # duplicate factor by AgeYear (kept from your code)
            dup = 1
            if ageyear in [6, 8]:
                dup = 2
            elif ageyear == 10:
                dup = 3

            # check modality dirs
            slice_dirs = [os.path.join(input_folder, m, sid, str(age))
                          for m in self.img_channels]
            if not os.path.isdir(slice_dirs[0]):
                continue

            # median-20 slices
            slice_files = sorted(os.listdir(slice_dirs[0]),
                                 key=lambda x: int(x.split('.')[0]))
            if len(slice_files) > 20:
                mid = (len(slice_files) - 20) // 2
                slice_files = slice_files[mid: mid + 20]

            row0 = grp.iloc[0]

            # Build ext label dict, imputing missing with column mean
            ext_labels = {}
            for c in self.label_cols:
                v = row0.get(c, np.nan)
                if pd.isna(v):
                    v = self.col_means.get(c, 0.0)
                ext_labels[c] = float(v)

            for _ in range(dup):
                for sfile in slice_files:
                    self.samples.append(dict(
                        Subject=sid,
                        Ageyear=ageyear,
                        Age=age,
                        Slice=int(sfile[:-4]),
                        img_paths=[os.path.join(d, sfile) for d in slice_dirs],
                        ext_labels=ext_labels
                    ))
            if lim and len(self.samples) >= lim:
                break

        if not self.samples:
            raise RuntimeError("No samples found. Please check paths and CSV.")

    # -------------------- transforms --------------------
    def _load_views(self, img_paths: list[str]) -> tuple[torch.Tensor, torch.Tensor]:
        chans = [np.squeeze(np.load(p)) for p in img_paths]
        chans = [c / (c.max() + 1e-8) for c in chans]
        arr   = np.stack(chans, axis=2)          # (H, W, C)
        arr   = np.rot90(arr, axes=(0, 1)).copy()

        weak   = torch.tensor(self.weak_tf(arr),   dtype=torch.float32)
        strong = torch.tensor(self.strong_tf(arr), dtype=torch.float32)

        weak   = torch.nan_to_num(weak,   nan=0.0)
        strong = torch.nan_to_num(strong, nan=0.0)
        return weak, strong

    # -------------------- skewed age pdf --------------------
    def _skewed_age_distribution(self, age, b, bins=1024, bin_width=4, sigma=90.0):
        gamma = self.gamma
        alpha = gamma * b
        centres = torch.arange(bins, dtype=torch.float32) * bin_width

        delta = alpha / np.sqrt(1 + alpha**2) if alpha != 0 else 0.0
        mean_shift = sigma * delta * np.sqrt(2 / np.pi)
        loc = age - mean_shift

        pdf = scipy.stats.skewnorm.pdf(centres.numpy(), alpha, loc=loc, scale=sigma)
        pdf = torch.from_numpy(pdf.astype(np.float32))
        pdf /= pdf.sum() + 1e-8
        return pdf

    # -------------------- required methods --------------------
    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        info = self.samples[idx]
        weak_img, strong_img = self._load_views(info['img_paths'])

        # use first label col to control skew (now always present, imputed if missing)
        if self.label_cols:
            label0 = info['ext_labels'][self.label_cols[0]]
            b = (label0 - self.label_mu) / (self.label_std + 1e-8)
            age_vec = self._skewed_age_distribution(float(info['Age']), b)
        else:
            age_vec = age_to_gaussian_vec(float(info['Age']))

        # ext labels tensor (normalize scale if needed; here keep raw or /100.0 as before)
        lbl_vals = [float(info['ext_labels'][c]) / 100.0 for c in self.label_cols]
        lbl_tensor = torch.tensor(lbl_vals, dtype=torch.float32)

        return (
            weak_img,          # (C,H,W)
            strong_img,        # (C,H,W)
            age_vec,           # (1024,)
            info['Subject'],   # str
            info['Ageyear'],   # int
            lbl_tensor         # (N_ext,)   # NOTE: no has_label returned
        )

class CentralSliceDataset(Dataset):
    def __init__(self, input_folder, map_folder, guide_path='', mode='', subject_id=None, addxgb=None,
                 img_channels=['T1w', 'T2w', 'T1map', 'T2map'], lim=None):
        self.mode = mode
        source_df = pd.read_csv(guide_path)

        data = []
        
        if mode:
            source_df = source_df[source_df['mode']==mode]
        if subject_id:
            source_df = source_df[(source_df['Subject ID']==subject_id['Subject']) & (source_df['Age']==subject_id['Age'])]
            
        grouped_df = source_df.groupby(['Subject ID','Age','Sex','Diagnosis Result'])
        dataset_type = os.path.basename(guide_path).split('_')[0]

        index = 0
        # Iterate over each group, no age
        for (id,age,sex,dx), group in grouped_df: 
            index += 1
            if lim is not None and (index > lim):
                break

            t1w_folder = os.path.join(input_folder, id, str(age), 'T1w')
            t1map_folder = os.path.join(map_folder, id, str(age), 'T1map')
            t2w_folder = t1w_folder.replace('T1', 'T2')
            t2map_folder = t2w_folder.replace('T1', 'T2')
            
            img_list = []
            if 'T1w' in img_channels:
                img_list.append(t1w_folder)
            if 'T2w' in img_channels:
                img_list.append(t2w_folder)
            if 'T1map' in img_channels:
                img_list.append(t1map_folder)
            if 'T2map' in img_channels:
                img_list.append(t2map_folder)

            # Get a sorted list of slice filenames from the first image path
            slice_files = sorted(os.listdir(img_list[0]), key=lambda x: int(x.split('.')[0]))
            
            # Extract only the central slice
            middle_idx = len(slice_files) // 2
            central_slice = slice_files[middle_idx]
            
            # Create a list of paths for the central slice across all modalities
            slice_list = []
            for cur_path in img_list:
                slice_path = os.path.join(cur_path, central_slice)
                slice_list.append(slice_path)
            
            slice_num = int(central_slice[:-4])

            info = {'Subject': id,
                    'Age': age,
                    'Slice': slice_num,
                    'Diagnosis': int(dx),
                    'img_path': slice_list,
                   }
        
            data.append(info)

        self.data = data
        self.length = len(data)
    
    def __getitem__(self, index):
        info = self.data[index]
        age = info['Age']
        slice = info['Slice']
        name = info['Subject']
        dx = info['Diagnosis']

        all_channels = []
        for cur_path in info['img_path']:
            if cur_path is None:
                continue
    
            tmp = np.load(cur_path)
            tmp = np.squeeze(tmp)
            tmp = tmp / tmp.max()
            all_channels.append(tmp)
        
        all_channels = np.stack(all_channels, axis=2)
        all_channels = np.rot90(all_channels, axes=(0,1)).copy()

        if self.mode == 'test':
            cur_slice = test_transforms(all_channels)
        else:
            cur_slice = train_transforms(all_channels)
        
        cur_slice = torch.tensor(cur_slice, dtype=torch.float32)

        value_age = torch.tensor([age/100], dtype=torch.float32)
        return cur_slice

    def __len__(self):
        return self.length

class BAGDataset_3D(Dataset):
    def __init__(
        self,
        input_folder,
        guide_path,
        mode='',                # 'train' or 'val'
        img_channels=['T1w','T2w','T1map','T2map'],
        lim=None
    ):
        self.mode = mode
        df = pd.read_csv(guide_path)

        # only keep the split we want
        if mode:
            df = df[df['split'] == mode]

        # group by subject & the two ages
        grouped = df.groupby(['subject_ID','age_visit_1','age_visit_2'])

        data = []
        for (sid, age1, age2), grp in grouped:
            if lim is not None and len(data) >= lim:
                break

            img_folder_1 = os.path.join(input_folder, sid, str(age1))
            img_folder_2 = os.path.join(input_folder, sid, str(age2))

            data.append({
                'subject_ID': sid,
                'age_gap': float(age2) - float(age1),
                'img_path_1': img_folder_1,
                'img_path_2': img_folder_2,
                'mod_list': img_channels
            })

        self.data = data
        self.length = len(data)

    def __len__(self):
        return self.length

    def __getitem__(self, idx):
        info = self.data[idx]
        sid   = info['subject_ID']
        gap   = info['age_gap']
        mods  = info['mod_list']

        def load_scan(folder):
            """Load all modalities from one visit folder into one tensor."""
            mod_vols = []
            for m in mods:
                try:
                    nii_path = os.path.join(folder, m.lower() + '.nii.gz')
                    if not os.path.exists(nii_path):
                        print(f"Warning: {nii_path} does not exist")
                        # Create an empty volume of appropriate size as placeholder
                        placeholder = np.zeros((64, 128, 128), dtype=np.float32)
                        mod_vols.append(placeholder)
                        continue
                    
                    # Load the NIfTI file
                    nii_img = nib.load(nii_path)
                    vol = nii_img.get_fdata().astype(np.float32)
                    
                    # Check for NaN values and replace them
                    if np.isnan(vol).any():
                        print(f"Warning: NaN values found in {nii_path}, replacing with zeros")
                        vol = np.nan_to_num(vol, nan=0.0)
                    
                    # Check if volume is empty or contains only zeros
                    if np.all(vol == 0) or vol.size == 0:
                        print(f"Warning: Volume in {nii_path} is empty or contains only zeros")
                    
                    # Print stats only if volume is valid
                    if vol.size > 0 and not np.all(vol == 0):
                        mean_val = np.mean(vol)
                        std_val = np.std(vol)
                        print(f"Volume {m} stats - Mean: {mean_val:.4f}, Std: {std_val:.4f}, Shape: {vol.shape}")
                    
                    # reorder to (Z, H, W)
                    vol = np.transpose(vol, (2, 0, 1))
                    
                    # optional rotate to match orientation
                    vol = np.rot90(vol, axes=(1, 2)).copy()
                    vol = np.expand_dims(vol, 0)
                    
                    # Apply 3D transforms
                    if self.mode == 'test':
                        vol = test_transforms_3d(vol)
                    else:
                        vol = train_transforms_3d(vol)
                    
                    mod_vols.append(vol)
                    
                except Exception as e:
                    print(f"Error loading {nii_path}: {str(e)}")
                    # Create an empty volume as placeholder
                    placeholder = np.zeros((64, 128, 128), dtype=np.float32)
                    mod_vols.append(placeholder)
        
            # Ensure we have data for all modalities
            if len(mod_vols) == 0:
                raise ValueError(f"No valid volumes loaded from {folder}")
        
            # concatenate across channels → (n_mods, Z, H, W)
            scan = np.concatenate(mod_vols, axis=0)
            scan = torch.from_numpy(scan).float()
        
            # Replace any remaining NaNs with zeros
            scan = torch.nan_to_num(scan, nan=0.0)
        
            # Print overall scan stats
            print(f"Complete scan stats - Mean: {scan.mean().item():.4f}, Std: {scan.std().item():.4f}, Shape: {scan.shape}")
        
            return scan

        # Load both scans
        scan1 = load_scan(info['img_path_1'])
        scan2 = load_scan(info['img_path_2'])
        
        age_gap = torch.tensor([gap/10.0], dtype=torch.float32)
        print(f"Age Gap: {age_gap.item():.2f}")

        return scan1, scan2, age_gap, sid