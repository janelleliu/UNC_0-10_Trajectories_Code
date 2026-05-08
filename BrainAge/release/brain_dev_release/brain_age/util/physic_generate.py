import numpy as np
import torch

def prepare_para(para):
    new_para = para.unsqueeze(1).unsqueeze(2).unsqueeze(3)
    return new_para


def generate_mprage(T1,T2,PD,IMG_PARA):
    #IMG_PARA: imaging parameters - [TR,TI,TE,FA]
    
    #T1 = np.maximum(T1,1)  #TODO: max?
    #T2 = np.maximum(T2,1)

    # simple Mprage signal model
    mprage_generate = PD*(1-2*np.exp(-IMG_PARA[1]/T1)+np.exp(-IMG_PARA[0]/T1))/(1+np.cos(IMG_PARA[3])*np.exp(-IMG_PARA[0]/T1))*np.sin(IMG_PARA[3])*np.exp(-IMG_PARA[2]/T2)
    mprage_generate = np.abs(mprage_generate)
    
    return mprage_generate


def generate_tse(T1,T2,PD,IMG_PARA):
    #IMG_PARA: imaging parameters - [TR,TI,TE,FA]
    
    #T1 = np.maximum(T1,1)
    #T2 = np.maximum(T2,1)

    # simple se signal model
    se_generate = PD*(1-2*np.exp(-(IMG_PARA[0]-IMG_PARA[2]/2)/T1)+np.exp(-IMG_PARA[0]/T1))*np.exp(-IMG_PARA[2]/T2)
    
    return se_generate

def generate_mprage_tensor(T1,T2,PD,IMG_PARA):
    #IMG_PARA: imaging parameters - [TR,TI,TE,FA]

    TR = prepare_para(IMG_PARA[:,0])
    TR = TR.to(T1.device)
    
    TI = prepare_para(IMG_PARA[:,1])
    TI = TI.to(T1.device)
    
    TE = prepare_para(IMG_PARA[:,2])
    TE = TE.to(T1.device)
    
    FA = prepare_para(IMG_PARA[:,3]) /180*torch.pi
    FA = FA.to(T1.device)
    
    # remove zero points for calculation
    clip_min = torch.ones_like(T1)
    T1 = torch.maximum(T1,clip_min)
    T2 = torch.maximum(T2,clip_min)

    # simple Mprage signal model
    mprage_generate = PD*(1-2*torch.exp(-TI/T1)+torch.exp(-TR/T1))/(1+torch.cos(FA)*torch.exp(-TR/T1))*torch.sin(FA)*torch.exp(-TE/T2)
    mprage_generate = torch.abs(mprage_generate)
    
    mprage_generate = mprage_generate.to(torch.float32)
    
    return mprage_generate


def generate_tse_tensor(T1,T2,PD,IMG_PARA):
    #IMG_PARA: imaging parameters - [TR,TI,TE,FA]

    TR = prepare_para(IMG_PARA[:,0])
    TR = TR.to(T1.device)
    
    TI = prepare_para(IMG_PARA[:,1])
    TI = TI.to(T1.device)
    
    TE = prepare_para(IMG_PARA[:,2])
    TE = TE.to(T1.device)
    
    FA = prepare_para(IMG_PARA[:,3]) /180*torch.pi
    FA = FA.to(T1.device)
    
    # remove zero points for calculation
    clip_min = torch.ones_like(T1)
    T1 = torch.maximum(T1,clip_min)
    T2 = torch.maximum(T2,clip_min)
    
    # simple se signal model
    se_generate = PD*(1-2*torch.exp(-(TR-TE/2)/T1)+torch.exp(-TR/T1))*torch.exp(-TE/T2)
    se_generate = se_generate.to(torch.float32)
    
    return se_generate


def generate_star_tensor(T1,T2,PD,IMG_PARA):
    #IMG_PARA: imaging parameters - [TR,TI,TE,FA]

    TR = prepare_para(IMG_PARA[:,0])
    TR = TR.to(T1.device)
    
    TI = prepare_para(IMG_PARA[:,1])
    TI = TI.to(T1.device)
    
    TE = prepare_para(IMG_PARA[:,2])
    TE = TE.to(T1.device)
    
    FA = prepare_para(IMG_PARA[:,3]) /180*torch.pi
    FA = FA.to(T1.device)
    
    # remove zero points for calculation
    clip_min = torch.ones_like(T1)
    T1 = torch.maximum(T1,clip_min)
    T2 = torch.maximum(T2,clip_min)
    
    # simple se signal model
    star_generate = PD*(1-torch.exp(-TR/T1))/(1-torch.cos(FA)*torch.exp(-TR/T1))*torch.sin(FA)*torch.exp(-TE/T2)
    star_generate = star_generate.to(torch.float32)
    
    return star_generate


def generate_flair_tensor(T1,T2,PD,IMG_PARA):
    #IMG_PARA: imaging parameters - [TR,TI,TE,FA]

    TR = prepare_para(IMG_PARA[:,0])
    TR = TR.to(T1.device)
    
    TI = prepare_para(IMG_PARA[:,1])
    TI = TI.to(T1.device)
    
    TE = prepare_para(IMG_PARA[:,2])
    TE = TE.to(T1.device)
    
    FA = prepare_para(IMG_PARA[:,3]) /180*torch.pi
    FA = FA.to(T1.device)
    
    # remove zero points for calculation
    clip_min = torch.ones_like(T1)
    T1 = torch.maximum(T1,clip_min)
    T2 = torch.maximum(T2,clip_min)
    
    # simple se signal model
    flair_generate = PD*(1-2*torch.exp(-TI/T1)+torch.exp(-TR/T1))*torch.exp(-TE/T2)
    flair_generate = flair_generate.to(torch.float32)
    
    return flair_generate


class Generate_Weighted:
    def generate_weighted_MSF(self, T1,T2,PD,paras,mask):
        '''
        Input size: [b,c,h,w]  Format: torch.tensor
        For weight image combination: MPRAGE, T2 Star, Flair
        '''
        
        mprage = generate_mprage_tensor(T1,T2,PD,paras[:,0])
        mprage = mprage*mask
        
        t2_star = generate_star_tensor(T1,T2,PD,paras[:,1])
        t2_star = t2_star*mask
        
        flair = generate_flair_tensor(T1,T2,PD,paras[:,2])
        flair = flair*mask
        
        weighted_image = torch.cat([mprage,t2_star,flair],dim=1)
        
        return weighted_image

    def generate_weighted_MSS(self, T1,T2,PD,paras,mask):
        '''
        Input size: [b,c,h,w]  Format: torch.tensor
        For weight image combination: MPRAGE, T2 TSE, PD TSE
        '''
        
        mprage = generate_mprage_tensor(T1,T2,PD,paras[:,0])
        mprage = mprage*mask
        
        t2_tse = generate_tse_tensor(T1,T2,PD,paras[:,1])
        t2_tse = t2_tse*mask
        
        pd_tse = generate_tse_tensor(T1,T2,PD,paras[:,2])
        pd_tse = pd_tse*mask
        
        weighted_image = torch.cat([mprage,t2_tse,pd_tse],dim=1)
        
        return weighted_image

'''
class Generate_Weighted_Batch:
    def __init__(self):
        self.weights = Generate_Weighted()

    def process_batch(self, t1map,t2map,pdmap,paras,bmask, image_types):
        processed_images = []
        for i, image_type in enumerate(image_types):
            weight_func = getattr(self.weights, f'generate_weighted_{image_type}')
            weighted_outputs = weight_func(t1map[i:i+1],t2map[i:i+1],pdmap[i:i+1],paras[i],bmask[i:i+1])
            processed_images.append(weighted_outputs[0])
        return torch.stack(processed_images)
'''