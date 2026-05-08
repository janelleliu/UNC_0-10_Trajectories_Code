import torch.nn as nn
import torch.nn.functional as F
import torch

def contrast_similarity_loss(t1, pd, mask):
    selected_mask = (mask > 0) & (pd > 0.2)
    clip_mask = torch.where(selected_mask, mask, torch.tensor(0.).to(mask.device))
    clip_low = torch.ones_like(t1)/10   #0.1
    
    t1_inv = 1/torch.maximum(t1,clip_low)
    #t1_inv_eff = t1_inv[clip_mask==1]
    mean_t1, std_t1 = cal_masked_mean_std_torch(img=t1_inv,mask=clip_mask,dim=[2,3])
    #t1_inv_norm = (t1_inv-mean_t1)/std_t1
    
    pd_inv = 1/torch.maximum(pd,clip_low)
    #pd_inv_eff = pd_inv[clip_mask==1]
    mean_pd, std_pd = cal_masked_mean_std_torch(img=pd_inv,mask=clip_mask,dim=[2,3])
    #pd_inv_norm = (pd_inv-mean_pd)/std_pd
    
    
    # select non-zero imgs from batch. pay attention to zero value
    mask_counts = selected_mask.sum(dim=(2, 3), keepdim=True)
    non_zero_mask_indices = (mask_counts > 0) & (std_t1 > 0) & (std_pd > 0)
    non_zero_mask_indices = non_zero_mask_indices.squeeze()
    if non_zero_mask_indices.sum() == 0:
        return 0
    
    t1_inv_norm =  (t1_inv[non_zero_mask_indices] - mean_t1[non_zero_mask_indices]) / std_t1[non_zero_mask_indices]
    pd_inv_norm =  (pd_inv[non_zero_mask_indices] - mean_pd[non_zero_mask_indices]) / std_pd[non_zero_mask_indices]
    
    loss = nn.MSELoss()
    
    return loss(t1_inv_norm*clip_mask[non_zero_mask_indices], pd_inv_norm*clip_mask[non_zero_mask_indices])


def positive_loss(output, mask):
    """
    Custom loss function.
    ! NEED check before use
    
    Args:
        output (torch.Tensor): The output tensor from the network.
        mask (torch.Tensor): The mask tensor, where we want output > 0 when mask == 1, and output == 0 when mask == 0.
        
    Returns:
        torch.Tensor: The computed loss value.
    """
    # Ensure mask is boolean
    mask = mask.bool()
    
    # Loss where mask is 1 (output should be > 0)
    # Use ReLU to penalize negative values (ReLu(-x) = 0 for x > 0, which is what we want)
    masked_output = output * mask  # Apply mask where mask is 1
    loss_positive = F.relu(-masked_output)  # We want this part to be greater than 0
    
    # Loss where mask is 0 (output should be = 0)
    # No activation needed, penalize all non-zero values
    inverse_mask = ~mask  # Inverse mask (where original mask is 0)
    masked_output_zero = output * inverse_mask  # Apply inverse mask
    loss_zero = masked_output_zero.abs()  # We want this part to be equal to 0
    
    # Combine losses
    total_loss = loss_positive.mean() + loss_zero.mean()  # Mean for average loss per batch
    
    return total_loss


def pd_ventricle_loss(img, mask, ref_val=1.0):
    '''
    from shihan's val_loss
    constraint mean PD value in ventricle equals 1
    '''
    
    #value = tfp.stats.percentile(tf.boolean_mask(img,mask_img>0),95)
    #value = torch.mean(img[mask==1], dim=[2,3])
    mean_vent, _ = cal_masked_mean_std_torch(img=img, mask=mask, dim=[2,3])
    loss = torch.abs(mean_vent-ref_val).mean()
    return loss


def pd_wm_loss(img, mask, vmin=0.5):
    '''
    from shihan's val_relu_loss
    constraint mean PD value in WM more than 0.5
    attention to some images with no wm region
    '''
    
    mask_counts = mask.sum(dim=(2,3))
    if mask_counts.sum() == 0:
        return 0
    non_zero_mask_indices = mask_counts > 0
    selected_imgs = img[non_zero_mask_indices,:]
    
    #value = tfp.stats.percentile(tf.boolean_mask(img,mask_img>0),95)
    #mean_value = torch.mean(img[mask==1], dim=[2,3])
    mean_wm, _ = cal_masked_mean_std_torch(img=selected_imgs, mask=mask, dim=[2,3])
    #clip_low = torch.zeros_like(value)
    
    loss = torch.relu(vmin-mean_wm).mean()
    return loss

def correlation_loss(image_features, radiomics_features):
    """
    Compute correlation loss between image_features and radiomics_features
    when batch_size = 1, by computing correlation across feature dimension.
    """
    # Flatten to (512,)
    img_features = image_features.view(-1)
    rad_features = radiomics_features.view(-1)

    # Compute means
    mean_img = img_features.mean()
    mean_rad = rad_features.mean()

    # Compute deviations
    img_deviation = img_features - mean_img
    rad_deviation = rad_features - mean_rad

    # Compute covariance
    covariance = (img_deviation * rad_deviation).mean()

    # Compute standard deviations
    img_std = img_features.std(unbiased=False)  # Prevents DoF warning
    rad_std = rad_features.std(unbiased=False)

    # Compute Pearson correlation
    correlation = covariance / (img_std * rad_std + 1e-6)  # Add small value to avoid division by zero

    # Loss: 1 - correlation
    loss_corr = 1 - correlation
    
    # Ensure loss is non-negative
    loss_corr = torch.clamp(loss_corr, min=0.0)

    return loss_corr