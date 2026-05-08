import numpy as np

def computing_dice(pred, gt):
    channel = pred.shape[0]
    dices = []
    for i in range(channel):
        p = pred[i]
        l = gt[i]
        
        intersection = (p * l).sum()
        union = (p + l).sum()
        if intersection != 0:
            dice = float((2 * intersection) / union)
        else:
            dice = 0
            
        dices.append(dice)
            
    return dices

def computing_sensitivity(pred, gt):
    channel = pred.shape[0]
    sens = []
    for i in range(channel):
        p = pred[i]
        l = gt[i]
    
        TP = (p * l).sum()
        FN = ((1-p) * l).sum()
        sen = TP/(TP+FN)
        
        sens.append(sen)
    return sens

def computing_specificity(pred, gt):
    channel = pred.shape[0]
    specs = []
    for i in range(channel):
        p = pred[i]
        l = gt[i]
    
        TN = ((1-p) * (1-l)).sum()
        FP = (p * (1-l)).sum()
        spec = TN/(TN+FP)
        
        specs.append(spec)
    return specs

def computing_precision(pred, gt):
    channel = pred.shape[0]
    precs = []
    for i in range(channel):
        p = pred[i]
        l = gt[i]
    
        TP = (p * l).sum()
        FP = (p * (1-l)).sum()
        prec = TP/(TP+FP)
        
        precs.append(prec)
    return precs

def computing_accuracy(pred, gt):
    channel = pred.shape[0]
    accs = []
    for i in range(channel):
        p = pred[i]
        l = gt[i]
    
        TP = (p * l).sum()
        FP = (p * (1-l)).sum()
        TN = ((1-p) * (1-l)).sum()
        FN = ((1-p) * l).sum()
        
        acc = (TP+TN)/(TP+TN+FP+FN)
        accs.append(acc)
        
    return accs
    

def dice(pred, label, avg):
    channel = pred.shape[1]
    for i in range(channel):
        p = pred[:,i]
        l = label[:,i]
        
        intersection = (p * l).sum()
        union = (p + l).sum()
        if intersection != 0:
            dices = float((2 * intersection) / union)
        else:
            dices = 0
            avg[i+2] -= 1
        
        avg[i] += dices
            
    return avg

def age_to_norm(age):
    """Convert real age (200–3000) to normalized value (0–1) in log10 scale."""
    log_min, log_max = np.log10(100), np.log10(4000)
    log_age = np.log10(age)
    return (log_age - log_min) / (log_max - log_min)

def norm_to_age(norm_val):
    """Convert normalized value (0–1) back to real age (200–3000) in log10 scale."""
    log_min, log_max = np.log10(100), np.log10(4000)
    log_age = norm_val * (log_max - log_min) + log_min
    return 10 ** log_age
