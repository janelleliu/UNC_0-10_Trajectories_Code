import os
from tqdm import tqdm
import torch
from dataloader2d import ConcatDataset, SSLDataset
from torch.utils.data import DataLoader
from util.utils import AverageMeter, save_configs
from util.loss import correlation_loss
from util.metrics import age_to_norm, norm_to_age
from models.ResNet import resnet50, resnet18
import pandas as pd
import argparse
import matplotlib.pyplot as plt
import numpy as np
import timm
from timm.scheduler import CosineLRScheduler
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from models.Extend3DModel import ConcatAgePredictionModel, HybridAgePredictionModel, FunctionAgePredictionModel, FunctionAgePredictionModel_SSL
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import time
from collections import Counter
import gc
from torch.cuda.amp import autocast, GradScaler

def print_memory_usage():
    allocated = torch.cuda.memory_allocated() / 1024**2
    reserved = torch.cuda.memory_reserved() / 1024**2
    print(f"Allocated: {allocated:.2f} MB, Reserved: {reserved:.2f} MB")

def calculate_metrics(record, output_dir):
    #calculate MAE, RMSE, R2, MAPE respectively for DX = 1, 2, 3
    MAE = {}
    RMSE = {}
    R2 = {}
    MAPE = {}
    for i in range(1,4):
        df = record[record['DX']==i]
        #'Age', 'PredictAge' *= 100
        df['Age'] = df['Age']*100
        df['PredictAge'] = df['PredictAge']*100
        MAE[i] = np.mean(np.abs(df['Age']-df['PredictAge']))
        RMSE[i] = np.sqrt(np.mean((df['Age']-df['PredictAge'])**2))
        R2[i] = np.corrcoef(df['Age'],df['PredictAge'])[0,1]
        MAPE[i] = np.mean(np.abs(df['Age']-df['PredictAge'])/df['Age'])
        with open(os.path.join(output_dir,'metrics.txt'),'a') as f:
            f.write(f'DX={i}: MAE={MAE[i]}, RMSE={RMSE[i]}, R2={R2[i]}, MAPE={MAPE[i]}\n')
    
    return

def count_parameters(model: nn.Module):
    """Returns the number of trainable parameters in a PyTorch model."""
    return sum(p.numel() for p in model.parameters() if p.requires_grad)

def data_loader(args, mode, img_list, rad_list):
    if args.model3D:
        cur_datasets = HybridDataset_3D(input_folder=args.weighted_path, map_folder=args.map_path, guide_path=args.guide_path, 
                                        mode = mode, radiomics_folder=args.radiomics_path,
                                        img_channels = img_list, rad_channels = rad_list, lim = args.lim)
    else:
        cur_datasets = HybridDataset(input_folder=args.weighted_path, map_folder=args.map_path, guide_path=args.guide_path, 
                                        mode = mode, radiomics_folder=args.radiomics_path,
                                        img_channels = img_list, rad_channels = rad_list, lim = args.lim)       

    cur_data_size = len(cur_datasets)
    # if mode = test batch_size = 1 else = args.batch_size
    if mode == 'test':
        batch_size = 1
    else:
        batch_size = 1
    shuffle = mode == "train" 

    cur_data = DataLoader(cur_datasets, batch_size=batch_size, shuffle=shuffle, num_workers=args.num_workers, pin_memory=True)
    return cur_datasets, cur_data_size, cur_data

def data_loader_concat(args, mode, img_list):
    cur_datasets = ConcatDataset(input_folder=args.weighted_path, map_folder=args.map_path, guide_path=args.guide_path, 
                                mode = mode, addxgb=args.addxgb, img_channels = img_list, lim = args.lim)       

    cur_data_size = len(cur_datasets)
    # if mode = test batch_size = 1 else = args.batch_size
    batch_size = args.batch_size
    shuffle = mode == "train" 

    cur_data = DataLoader(cur_datasets, batch_size=batch_size, shuffle=shuffle, num_workers=args.num_workers, pin_memory=True)
    return cur_datasets, cur_data_size, cur_data

# ---------------------------------------------------------------------
# SSL dataloader using SSLDataset (weak+strong views + gaussian age vec)
# ---------------------------------------------------------------------
def data_loader_ssl(args, mode, img_list, label_cols, label_ratio):
    """
    Returns: dataset, size, loader
    """
    dataset = SSLDataset(
        input_folder=args.weighted_path,
        map_folder=args.map_path,
        guide_path=args.guide_path,
        mode=mode,
        img_channels=img_list,
        lim=args.lim,
        label_name=label_cols,
        label_ratio=label_ratio
    )
    loader = DataLoader(
        dataset,
        batch_size=args.batch_size,
        shuffle=(mode == 'train'),
        num_workers=args.num_workers,
        pin_memory=True
    )
    return dataset, len(dataset), loader

# ---------------------------------------------------------------------
# Two-stage SSL training (age distribution + external labels)
# ---------------------------------------------------------------------
def train_val_test_ssl(args,
                       ext_label_cols,          # list[str], e.g. ['SB_ABIQ_ss_6','PR_BASC_ANX_T_6','PR_BASC_DEP_T_6']
                       label_ratio=0.125,       # probability of sampling a labelled sample
                       stage1_epochs=0):
    """
    Stage 1: KL(age_logits || gaussian_age_target) only.
    Stage 2: KL + λ_mae * MAE(ext_pred, ext_lbl) + λ_corr * Corr(pred_age_days, ext_lbl)  (avg across ext dims).

    Inputs from SSLDataset per batch:
        weak_img, strong_img, age_vec(1024), subj(str list), ageyear(tensor),
        ext_lbl(tensor [B,N_ext]), has_lbl(bool tensor [B])

    Only the weak view is used here; strong is reserved for future consistency.
    """
    import torch.nn.functional as F  # local import in case top-level missing

    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    stage1_epochs = stage1_epochs or (args.epochs // 2)
    stage1_epochs = 0

    # ----------------- Model -----------------
    img_mods = []
    if args.elocal_image:
        img_mods.append('Elocal')
    if args.enodal_image:
        img_mods.append('Enodal')
    if args.gradient1_image:
        img_mods.append('Gradient1')
    if args.gradient2_image:
        img_mods.append('Gradient2')
    if args.McosSim2_image:
        img_mods.append('McosSim2')
    if args.str_image:
        img_mods.append('Str')
    if args.T1w_image:
        img_mods.append('T1w')
    net = FunctionAgePredictionModel_SSL(
        input_channel=len(img_mods),
        n_ext_labels=len(ext_label_cols),
        drop_out_rate=args.dropout,
        add_xgb=None
    ).to(device)
    if torch.cuda.device_count() > 1:
        net = nn.DataParallel(net)

    # ----------------- Losses & Opt -----------------
    kl_crit  = nn.KLDivLoss(reduction='batchmean')
    mae_crit = nn.L1Loss(reduction='mean')
    lam_mae  = getattr(args, 'lam_mae', 0)
    lam_corr = getattr(args, 'lam_corr', 0)

    opt = optim.Adam(net.parameters(), lr=args.lr, betas=(0.9, 0.999))
    sched = CosineLRScheduler(opt, t_initial=args.epochs, lr_min=1e-6)
    scaler = GradScaler()

    # age centres (days) on device
    age_centres = (torch.arange(1024, dtype=torch.float32) * 4.0).to(device)

    # ----- checkpoint setup -----
    os.makedirs(args.output_dir, exist_ok=True)

    def _save_ssl_ckpt(tag):
        """Save model checkpoint with a tag (epoch number or 'stage1')."""
        if isinstance(net, nn.DataParallel):
            state = net.module.state_dict()
        else:
            state = net.state_dict()
        ckpt_path = os.path.join(args.output_dir, f'ssl_{tag}.pth')
        torch.save(state, ckpt_path)
        print(f'[SSL][CKPT] Saved checkpoint: {ckpt_path}')

    # ----------------- Data -----------------
    train_set,  _, train_loader  = data_loader_ssl(args, 'train', img_mods, ext_label_cols, label_ratio)
    valid_set,  _, valid_loader  = data_loader_ssl(args, 'valid', img_mods, ext_label_cols, label_ratio)
    test_loaders = {
        split: data_loader_ssl(args, split, img_mods, ext_label_cols, label_ratio)[2]
        for split in ['AD', 'AU', 'MPD']
    }

    # ----------------- Load checkpoint if available -----------------
    if getattr(args, 'load_model_path', None) and os.path.isfile(args.load_model_path):
        checkpoint = torch.load(args.load_model_path, map_location=device)
        if isinstance(net, nn.DataParallel):
            net.module.load_state_dict(checkpoint)
        else:
            net.load_state_dict(checkpoint)
        print(f"[SSL][CKPT] Loaded checkpoint from {args.load_model_path}")

    # ----------------- Training loop -----------------
    for epoch in range(args.epochs):
        net.train()
        pbar = tqdm(train_loader, desc=f'Epoch {epoch+1}/{args.epochs}')

        # --- loss meters for this epoch ---
        tr_kl_meter   = AverageMeter()
        tr_mae_meter  = AverageMeter()
        tr_corr_meter = AverageMeter()
        tr_tot_meter  = AverageMeter()

        va_kl_meter   = AverageMeter()
        va_mae_meter  = AverageMeter()
        va_corr_meter = AverageMeter()
        va_tot_meter  = AverageMeter()

        for weak, strong, age_vec, subj, ageyear, ext_lbl, has_lbl in pbar:
            weak     = weak.to(device)
            age_vec  = age_vec.to(device)                 # (B,1024)
            ext_lbl  = ext_lbl.to(device)                 # (B,N_ext)
            has_lbl  = has_lbl.to(device).bool().view(-1) # (B,)

            opt.zero_grad()
            with autocast():
                age_logits, ext_pred, _ = net(weak)       # logits: (B,1024); ext_pred: (B,N_ext)

                # KL loss (log_softmax vs age target)
                log_p   = F.log_softmax(age_logits, dim=1)
                kl_loss = kl_crit(log_p, age_vec)
                stage1_epochs = 0
                if epoch < stage1_epochs:
                    mae = torch.zeros(1, device=device)
                    corr = torch.zeros(1, device=device)
                    loss = kl_loss
                else:
                    # Expected age (days)
                    #print(12345)
                    p_age    = F.softmax(age_logits, dim=1)
                    pred_age = (p_age * age_centres).sum(dim=1)    # (B,)
                    #compute true age from age_vec
                    if age_vec.dim() == 3:
                        age_dist = age_vec.squeeze(0).to(p_age.device)  # shape (1024,)
                    else:
                        age_dist = age_vec.to(p_age.device)
                    true_age = (age_dist * age_centres).sum().item()
                        #put true_age into device
                    true_age = torch.tensor(true_age, device=device)
                    #print has_lbl for debugging
                    #print("has_lbl:", has_lbl)
                    if has_lbl.any():
                        ext_pred_sel = ext_pred[has_lbl]
                        ext_lbl_sel  = ext_lbl[has_lbl]

                        # MAE across all ext dims
                        mae = mae_crit(ext_pred_sel, ext_lbl_sel)

                        # correlation: average across dims, using new logic
                        pred_err = (pred_age - true_age).unsqueeze(1)
                        corr_terms = []
                        for d in range(ext_pred_sel.shape[1]):
                            corr_terms.append(
                                correlation_loss(
                                    pred_err,
                                    ext_pred.unsqueeze(1)
                                )
                            )
                        corr = torch.stack(corr_terms).mean()
                    else:
                        mae  = torch.zeros(1, device=device)
                        corr = torch.zeros(1, device=device)

                    loss = kl_loss + lam_mae * mae + lam_corr * corr

            # record per-batch (unreduced) losses into meters
            tr_kl_meter.update(kl_loss.item(),  weak.size(0))
            tr_mae_meter.update(mae.item(),     weak.size(0))
            tr_corr_meter.update(corr.item(),   weak.size(0))
            tr_tot_meter.update(loss.item(),    weak.size(0))

            scaler.scale(loss).backward()
            scaler.step(opt)
            scaler.update()

        # -------- validation (light) --------
        net.eval()
        with torch.no_grad():
            for weak, strong, age_vec, subj, ageyear, ext_lbl, has_lbl in valid_loader:
                weak     = weak.to(device)
                age_vec  = age_vec.to(device)
                ext_lbl  = ext_lbl.to(device)
                has_lbl  = has_lbl.to(device).bool().view(-1)

                with autocast():
                    age_logits, ext_pred, _ = net(weak)
                    log_p   = F.log_softmax(age_logits, dim=1)
                    kl_loss = kl_crit(log_p, age_vec)
                    if epoch < stage1_epochs:
                        mae  = torch.zeros(1, device=device)
                        corr = torch.zeros(1, device=device)
                        loss = kl_loss
                    else:
                        p_age    = F.softmax(age_logits, dim=1)
                        pred_age = (p_age * age_centres).sum(dim=1)
                        #compute true age from age_vec
                        if age_vec.dim() == 3:
                            age_dist = age_vec.squeeze(0).to(p_age.device)  # shape (1024,)
                        else:
                            age_dist = age_vec.to(p_age.device)
                        true_age = (age_dist * age_centres).sum().item()
                        #put true_age into device
                        true_age = torch.tensor(true_age, device=device)

                        if has_lbl.any():
                            ext_pred_sel = ext_pred[has_lbl]
                            ext_lbl_sel  = ext_lbl[has_lbl]
                            mae = mae_crit(ext_pred_sel, ext_lbl_sel)
                            pred_err = (pred_age - true_age).unsqueeze(1)
                            corr_terms = []
                            for d in range(ext_pred_sel.shape[1]):
                                corr_terms.append(
                                    correlation_loss(
                                        pred_err,
                                        ext_pred.unsqueeze(1)
                                    )
                                )
                            corr = torch.stack(corr_terms).mean()
                        else:
                            mae  = torch.zeros(1, device=device)
                            corr = torch.zeros(1, device=device)
                        loss = kl_loss + lam_mae * mae + lam_corr * corr

                va_kl_meter.update(kl_loss.item(),  weak.size(0))
                va_mae_meter.update(mae.item(),     weak.size(0))
                va_corr_meter.update(corr.item(),   weak.size(0))
                va_tot_meter.update(loss.item(),    weak.size(0))
        net.train()

        sched.step(epoch)

        # ----- checkpointing -----
        if (epoch + 1) == stage1_epochs:
            _save_ssl_ckpt('stage1')
        if (epoch + 1) % 20 == 0:
            _save_ssl_ckpt(epoch + 1)

        # ----- end-of-epoch loss print -----
        print(
            f"[Epoch {epoch+1:03d}] "
            f"Train  KL: {tr_kl_meter.avg:.4f}  "
            f"MAE: {tr_mae_meter.avg:.4f}  "
            f"Corr: {tr_corr_meter.avg:.4f}  "
            f"Tot: {tr_tot_meter.avg:.4f} | "
            f"Val  KL: {va_kl_meter.avg:.4f}  "
            f"MAE: {va_mae_meter.avg:.4f}  "
            f"Corr: {va_corr_meter.avg:.4f}  "
            f"Tot: {va_tot_meter.avg:.4f}"
        )

        with open(os.path.join(args.output_dir, 'ssl_epoch_losses.txt'), 'a') as f:
            f.write(
                f"{epoch+1},"
                f"{tr_kl_meter.avg:.6f},{tr_mae_meter.avg:.6f},{tr_corr_meter.avg:.6f},{tr_tot_meter.avg:.6f},"
                f"{va_kl_meter.avg:.6f},{va_mae_meter.avg:.6f},{va_corr_meter.avg:.6f},{va_tot_meter.avg:.6f}\n"
            )

        # ----------------- Periodic eval -----------------
        if (epoch + 1) % 10 == 0:
            print(f"--- Periodic testing after epoch {epoch+1} ---")
            test_list = ['train', 'valid', 'AD', 'AU', 'MPD']
            for mode in test_list:
                vote_list = {}
                age_list = {}
                ageyear_list = {}
                ext_vote_list = None  # will be set after ext_pred is available
                # Load test set (use correct mode and loader)
                _, test_data_size, test_loader  = data_loader_ssl(args, mode, img_mods, ext_label_cols, label_ratio)
                with torch.no_grad():
                    pbar_test = tqdm(total=int(test_data_size))
                    pbar_test.set_description(f'Testing {mode}')
                    for images, _, age_vec, name, ageyear, ext_lbl, has_lbl in test_loader:
                        images = images.to(device)
                        outputs = net(images)
                        # SSL-style expected age prediction
                        age_logits, ext_pred, _ = outputs
                        p_age = torch.softmax(age_logits, dim=1)
                        pred_age = (p_age * age_centres.to(p_age.device)).sum(dim=1).detach().cpu()
                        # Initialize ext_vote_list once ext_pred is available
                        if ext_vote_list is None:
                            ext_vote_list = {d: {} for d in range(ext_pred.shape[1])}
                        # Full block replacement: use true age from age_vec
                        for i, subj in enumerate(name):
                            pred = pred_age[i].item()
                            identifier = (subj, ageyear[i].item())
                            vote_list.setdefault(identifier, []).append(pred)

                            # Store external predictions for each dimension
                            for d in range(ext_pred.shape[1]):
                                pred_ext = ext_pred[i, d].item()
                                ext_vote_list[d].setdefault(identifier, []).append(pred_ext)

                            # true_age: expected value from age_vec
                            if age_vec.dim() == 3:
                                age_dist = age_vec[:, i, :].squeeze(0).to(p_age.device)  # shape (1024,)
                            else:
                                age_dist = age_vec[i].to(p_age.device)
                            true_age = (age_dist * age_centres.to(age_dist.device)).sum().item()
                            age_list[identifier] = true_age
                            ageyear_list[identifier] = ageyear[i].item()
                        pbar_test.update(1)
                # Compute average of the middle 10 predicted ages out of 20, or mean if less
                for key in vote_list.keys():
                    sorted_preds = sorted(vote_list[key])
                    if len(sorted_preds) >= 10:
                        mid = len(sorted_preds) // 2
                        half = 5
                        vote_list[key] = np.mean(sorted_preds[mid - half:mid + half])
                    else:
                        vote_list[key] = np.mean(sorted_preds)
                    vote_list[key] = max(0, vote_list[key])
                # Apply same voting reduction for external predictions
                if ext_vote_list is not None:
                    for d in ext_vote_list:
                        for key in ext_vote_list[d].keys():
                            sorted_ext_preds = sorted(ext_vote_list[d][key])
                            if len(sorted_ext_preds) >= 10:
                                mid = len(sorted_ext_preds) // 2
                                half = 5
                                ext_vote_list[d][key] = np.mean(sorted_ext_preds[mid - half:mid + half])
                            else:
                                ext_vote_list[d][key] = np.mean(sorted_ext_preds)
                # Build DataFrame with external predictions
                data_rows = []
                ext_pred_dim = len(ext_vote_list) if ext_vote_list is not None else 0
                for (subj, ageyear) in vote_list.keys():
                    row = [subj, ageyear, age_list[(subj, ageyear)], vote_list[(subj, ageyear)]]
                    for d in range(ext_pred_dim):
                        row.append(ext_vote_list[d].get((subj, ageyear), np.nan))
                    data_rows.append(row)
                col_names = ['Subject', 'AgeYear', 'Age', 'PredictAge'] + [f'ExtPred_{d}' for d in range(ext_pred_dim)]
                vote_df = pd.DataFrame(data_rows, columns=col_names)
                out_file = os.path.join(args.output_dir, f"{mode}_epoch{epoch+1}_vote.csv")
                vote_df.to_csv(out_file, index=False)
                print(f"[INFO] Saved periodic test results to {out_file}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--guide_path', default='/common/xup2/dataset/lists/adni3_flair_2d_r2u_dx_split.csv', help='')
    parser.add_argument('--weighted_path', default='/common/xup2/dataset/ADNI2_input', help='')
    parser.add_argument('--map_path', default='/common/xup2/dataset/maps_new_04032025/ADNI2/map_npy', help='')
    parser.add_argument('--subject_list', default='/common/xup2/dataset/lists/adni3_flair_2d_r2u_dx_split.csv', help='')

    parser.add_argument('--num_workers', default=4, type=int)
    parser.add_argument('--batch_size', default=1, type=int)
    parser.add_argument('--epochs', default=300, type=int)
    parser.add_argument('--epochs_hybrid', default=100, type=int)
    parser.add_argument('--lr', default=0.0001, type=float)
    parser.add_argument('--lr_rad', default=0.0001, type=float)
    parser.add_argument('--dropout', default=0, type=float)
    parser.add_argument('--dropout_hybrid', default=0, type=float)

    parser.add_argument('--radiomics_path', default='/common/lidxxlab/Yifan/BrainAge/data/ImgFeature')
    parser.add_argument('--combination_method', default='attention')
    parser.add_argument('--image_features_path', default='/mnt/LiDXXLab_Files/Peiran/features/adni2_t1w.pt')
           
    parser.add_argument('--elocal_image', action='store_true')
    parser.add_argument('--enodal_image', action='store_true')
    parser.add_argument('--gradient1_image', action='store_true')
    parser.add_argument('--gradient2_image', action='store_true')
    parser.add_argument('--McosSim2_image', action='store_true')
    parser.add_argument('--str_image', action='store_true')
    parser.add_argument('--T1w_image', action='store_true')

    parser.add_argument('--freeze_epoch', default=0, type=int)
    parser.add_argument('--corr_weight', default=0, type=float)
    parser.add_argument('--corr_cnn', default=0.2, type=float)
    parser.add_argument('--corr_radio', default=0.2, type=float)
    parser.add_argument('--model3D', default=False, type=bool)
    parser.add_argument('--addrad', action='store_true')
    parser.add_argument('--addxgb', default=None, type=str)

    parser.add_argument('--resume', action='store_true')
    parser.add_argument('--resume_hybrid', action='store_true')
    parser.add_argument('--load_model_path', default=None)

    # output settings
    parser.add_argument('--output_dir', default='/common/lidxxlab/Yifan/BrainAge/Results/DL/Attention_all')
    parser.add_argument('--save_model', default=True, type=bool)
    parser.add_argument('--lim', default=None, type=int)

    # external labels to supervise in SSL Stage-2
    # Accepts either a comma-separated string OR multiple space-separated values.
    parser.add_argument(
        '--ext_label_cols',
        default='DX',
        type=str,
        help='Comma-separated list of external label column names (e.g. "SB_ABIQ_ss_6,PR_BASC_ANX_T_6,PR_BASC_DEP_T_6"). '
             'If you prefer, you can pass multiple values separated by spaces by quoting, e.g., '
             '--ext_label_cols "SB_ABIQ_ss_6 PR_BASC_ANX_T_6 PR_BASC_DEP_T_6".'
    )
    
    args = parser.parse_args()

    '''
    #for debug
    args.weight_img_input = True
    args.T1only = True
    args.resume = True
    args.use_extend_model = True
    args.input_channel = True
    train_val_concat_model(args)
    '''

    # Parse external label columns argument into a list
    if isinstance(args.ext_label_cols, str):
        # allow comma OR space separated entries
        if ',' in args.ext_label_cols:
            ext_cols = [c.strip() for c in args.ext_label_cols.split(',') if c.strip()]
        else:
            ext_cols = [c.strip() for c in args.ext_label_cols.split() if c.strip()]
    else:
        # fallback (shouldn't trigger; ext_label_cols is str)
        ext_cols = list(args.ext_label_cols)

    print(f'[INFO] Using external label columns: {ext_cols}')

    train_val_test_ssl(args, ext_cols, label_ratio=0.5)

if __name__ == "__main__":
    main()