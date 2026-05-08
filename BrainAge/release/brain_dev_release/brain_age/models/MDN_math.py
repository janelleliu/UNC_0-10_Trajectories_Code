# MDN_math.py
import math
import torch
import torch.nn.functional as F

__all__ = [
    "mdn_nll",
    "mdn_nll_with_obs_noise",
    "mdn_expectation",
    "mdn_sample",
    "mdn_responsibilities",
    "stable_softplus",
]

def stable_softplus(x):
    # numerically stable softplus
    return torch.log1p(torch.exp(-x.abs())) + x.clamp_min(0)

def _logsumexp(x, dim=-1, keepdim=False):
    m, _ = torch.max(x, dim=dim, keepdim=True)
    out = m + torch.log(torch.sum(torch.exp(x - m), dim=dim, keepdim=True))
    return out if keepdim else out.squeeze(dim)

def _log_norm_1d(y, mu, sigma):
    """
    log N(y | mu, sigma^2)
    y:    (B,) or (B,1)
    mu:   (B,M)
    sigma:(B,M)  (must be > 0)
    return: (B,M)
    """
    if y.dim() == 1:
        y = y.unsqueeze(1)       # (B,1)
    y = y.expand_as(mu)          # (B,M)
    return -0.5 * (
        math.log(2.0 * math.pi) +
        2.0 * torch.log(sigma) +
        ((y - mu) ** 2) / (sigma ** 2)
    )

def mdn_nll(y, pi, mu, sigma, eps: float = 1e-8):
    """
    MDN negative log-likelihood for 1D Gaussian mixture.
    y:    (B,) or (B,1)
    pi:   (B,M)   mixture weights (sum to 1 over M)
    mu:   (B,M)   means
    sigma:(B,M)   std (>0)
    return: scalar (mean over batch)
    """
    log_probs = _log_norm_1d(y, mu, sigma)     # (B,M)
    log_mix   = torch.log(pi.clamp_min(eps)) + log_probs
    log_like  = _logsumexp(log_mix, dim=1)     # (B,)
    return -(log_like.mean())

def mdn_nll_with_obs_noise(y, pi, mu, sigma, tau, eps: float = 1e-8):
    """
    NLL with known observation noise tau (std).
    tau can be scalar (), (B,), or (B,M).
    Effective sigma = sqrt(sigma^2 + tau^2).
    """
    if not torch.is_tensor(tau):
        tau = torch.tensor(tau, dtype=sigma.dtype, device=sigma.device)
    while tau.dim() < sigma.dim():
        tau = tau.unsqueeze(-1)
    tau = tau.expand_as(sigma)
    sigma_eff = torch.sqrt(sigma**2 + tau**2)
    return mdn_nll(y, pi, mu, sigma_eff, eps=eps)

@torch.no_grad()
def mdn_expectation(pi, mu):
    """E[y|x] under the mixture."""
    return torch.sum(pi * mu, dim=1)  # (B,)

@torch.no_grad()
def mdn_sample(pi, mu, sigma, n_samples: int = 50):
    """
    Sample from mixture per batch element.
    Returns: samples (S,B), comp_idx (S,B)
    """
    B, M = pi.shape
    cat = torch.distributions.Categorical(probs=pi)
    comp = cat.sample((n_samples,))  # (S,B)

    mu_s    = torch.gather(mu.expand(n_samples, -1, -1),    2, comp.unsqueeze(-1)).squeeze(-1)    # (S,B)
    sigma_s = torch.gather(sigma.expand(n_samples, -1, -1), 2, comp.unsqueeze(-1)).squeeze(-1)    # (S,B)

    eps = torch.randn_like(mu_s)
    return mu_s + sigma_s * eps, comp

@torch.no_grad()
def mdn_responsibilities(y, pi, mu, sigma, eps: float = 1e-8):
    """
    Posterior responsibilities gamma_{ik} = p(k | y_i, x_i).
    Returns: (B,M)
    """
    if y.dim() == 1:
        y = y.unsqueeze(1)
    y = y.expand_as(mu)  # (B,M)
    logp = -0.5*(torch.log(2*torch.pi*sigma**2) + (y - mu)**2 / (sigma**2))  # (B,M)
    logw = torch.log(pi.clamp_min(eps)) + logp
    logZ = torch.logsumexp(logw, dim=1, keepdim=True)
    gamma = torch.exp(logw - logZ)  # (B,M)
    return gamma