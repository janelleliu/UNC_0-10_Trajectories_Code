import torch
import torch.nn as nn
import torch.nn.functional as F
from models.ResNet import resnet34, resnet18, SmallResNet, SmallResNet_SSL
from models.ResNet3D import resnet18_3d
from models.MDN_math import (
    mdn_nll,
    mdn_expectation,
    mdn_sample,
    stable_softplus,
)

# cnn slice-wise feature extractor
class CNNFeatureExtractor(nn.Module):
    def __init__(self, input_channel, num_classes, output_dim=512):
        super(CNNFeatureExtractor, self).__init__()
        self.feature_extractor = resnet18(input_channel=input_channel, num_classes=num_classes, return_feature=True)
        self.fc = nn.Linear(512, output_dim)

    def forward(self, x):
        batch_size, num_slices, c, h, w = x.shape  # x.shape = (subject, slices, 3, 224, 224)
        x = x.reshape(batch_size * num_slices, c, h, w)  # Flatten slices into batch
        x = self.feature_extractor(x)
        x = x.reshape(x.size(0), -1)  # Flatten
        x = self.fc(x)  # (batch * slices, 512)
        x = x.reshape(batch_size, num_slices, -1)  # Reshape back to (subject, slices, 512)
        return x  # Return slice-wise features

class CNNFeatureExtractor3D(nn.Module):
    def __init__(self, input_channel, num_classes, output_dim=512):
        super(CNNFeatureExtractor3D, self).__init__()
        self.feature_extractor = resnet18_3d(input_channel=input_channel, num_classes=num_classes, return_feature=True)
        self.fc = nn.Linear(512, output_dim)

    def forward(self, x):
        #print(x.shape)
        batch_size, c, d, h, w = x.shape  # x.shape = (subject, 3, 64, 128, 128)
        #reshape to batch_size, c, d, h, w
        x = self.feature_extractor(x)
        #print(x.shape)
        x = x.reshape(x.size(0), -1)  # Flatten
        x = self.fc(x)  # (batch * slices, 512)
        return x  # Return 3D features

# Slice Aggregation
class SliceAggregator(nn.Module):
    def __init__(self, method="mean", input_dim=512):
        super(SliceAggregator, self).__init__()
        self.method = method
        if method == "attention":
            self.attn_fc = nn.Linear(input_dim, 1)  # Compute attention scores
            self.softmax = nn.Softmax(dim=1)  # Normalize attention weights

    def forward(self, slice_features):
        if self.method == "mean":
            return slice_features.mean(dim=1)  # Mean pooling over slices (batch, 512)
        elif self.method == "attention":
            attn_scores = self.softmax(self.attn_fc(slice_features))  # Compute attention scores
            return (attn_scores * slice_features).sum(dim=1)  # Weighted sum over slices

# Radiomics Feature Encoder (MLP)
class RadiomicsFeatureEncoder(nn.Module):
    def __init__(self, input_channel=3, out_dim=512):
        super(RadiomicsFeatureEncoder, self).__init__()
        
        # 1D CNN to reduce feature size
        self.conv1d = nn.Sequential(
            nn.Conv1d(in_channels=input_channel, out_channels=64, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            nn.Conv1d(in_channels=64, out_channels=256, kernel_size=3, stride=1, padding=1),
            nn.ReLU(),
            nn.AdaptiveAvgPool1d(1)  # Pool over spatial dimension
        )

        # MLP for final projection
        self.fc = nn.Sequential(
            nn.Linear(256, out_dim),
            nn.ReLU()
        )

    def forward(self, x):
        x = x.permute(0, 3, 2, 1)  # Reshape to (batch, 3, 42, 176)
        x = x.reshape(x.size(0), x.size(1) * x.size(2), x.size(3))  # Merge channels (batch, 126, 176)
        x = x.permute(0, 2, 1)
        #normalize x
        
        x = self.conv1d(x)  # Apply 1D CNN (batch, 256, 1)
        x = x.squeeze(2)  # Remove last dimension (batch, 256)
        x = self.fc(x)  # Apply MLP (batch, 512)
        return x

# Attention-Based Fusion Module
class AttentionFusion(nn.Module):
    def __init__(self, input_dim=512):
        super(AttentionFusion, self).__init__()
        self.attn_fc = nn.Linear(input_dim * 2, 2)  # Output attention scores for both modalities
        self.softmax = nn.Softmax(dim=1)  # Normalize attention weights

    def forward(self, cnn_features, radiomics_features):
        combined = torch.cat((cnn_features, radiomics_features), dim=1)  # Concatenate features
        attn_weights = self.softmax(self.attn_fc(combined))  # Compute attention scores

        # Weighted sum of CNN & Radiomics features
        fused_features = attn_weights[:, 0].unsqueeze(1) * cnn_features + \
                         attn_weights[:, 1].unsqueeze(1) * radiomics_features
        return fused_features

class WeightedFusion(nn.Module):
    def __init__(self, input_dim=512, num_classes=1, drop_out_rate=0):
        super(WeightedFusion, self).__init__()
        self.alpha = nn.Parameter(torch.tensor(0.5))  # 可学习的融合权重
        self.dropout = nn.Dropout(drop_out_rate)
        self.fc1 = nn.Linear(input_dim, 256)
        self.fc2 = nn.Linear(256, num_classes)

    def forward(self, cnn_features, radiomics_features):
        fused = self.alpha * cnn_features + (1 - self.alpha) * radiomics_features  # 加权求和
        fused = self.dropout(fused)
        fused = torch.relu(self.fc1(fused))
        output = self.fc2(fused)
        return output

class CrossAttentionFusion(nn.Module):
    def __init__(self, input_dim=512, hidden_dim=256):
        super(CrossAttentionFusion, self).__init__()
        # Non-linear projection for CNN features (query)
        self.query_fc = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim)
        )
        # Non-linear projection for Radiomics features (key and value)
        self.key_fc = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim)
        )
        self.value_fc = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim)
        )
        # Output non-linear mapping
        self.out_fc = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, input_dim)
        )
        self.softmax = nn.Softmax(dim=-1)

    def forward(self, cnn_features, radiomics_features):
        # cnn_features and radiomics_features: (batch, input_dim)
        # Compute projections
        Q = self.query_fc(cnn_features)          # (batch, hidden_dim)
        K = self.key_fc(radiomics_features)        # (batch, hidden_dim)
        V = self.value_fc(radiomics_features)      # (batch, hidden_dim)

        # Reshape for attention computation
        Q = Q.unsqueeze(1)   # (batch, 1, hidden_dim)
        K = K.unsqueeze(2)   # (batch, hidden_dim, 1)
        # Dot-product attention score
        attn_score = torch.bmm(Q, K)  # (batch, 1, 1)
        attn_weight = self.softmax(attn_score)  # (batch, 1, 1)

        V = V.unsqueeze(1)   # (batch, 1, hidden_dim)
        attn_output = attn_weight * V  # (batch, 1, hidden_dim)
        attn_output = attn_output.squeeze(1)  # (batch, hidden_dim)

        fusion = self.out_fc(attn_output)  # (batch, input_dim)
        # Combine the fusion output with the original cnn_features (skip connection)
        fused_features = cnn_features + fusion
        return fused_features

# Final Classifier
class Classifier(nn.Module):
    def __init__(self, input_dim=512):
        super(Classifier, self).__init__()
        self.fc = nn.Sequential(
            nn.Linear(input_dim, 256),
            nn.ReLU(),
            nn.Linear(256, 1)
        )

    def forward(self, x):
        return self.fc(x)

# Full End-to-End Model
class FusedAgePredictionModel(nn.Module):
    def __init__(self, input_channel=4, radio_channel=3, output_channel=1, model3D=False):
        super(FusedAgePredictionModel, self).__init__()
        self.model3D = model3D
        if self.model3D:
            self.cnn_encoder_3D = CNNFeatureExtractor3D(input_channel, output_channel)
        else:
            self.cnn_encoder = CNNFeatureExtractor(input_channel, output_channel)
            self.slice_aggregator = SliceAggregator(method="attention")
        self.radiomics_encoder = RadiomicsFeatureEncoder(radio_channel)
        self.attention_fusion = AttentionFusion()
        self.classifier = Classifier()

        self._init_weights()

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear) or isinstance(m, nn.Conv2d):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.zeros_(m.bias)

    def forward(self, image, radiomics):
        if self.model3D:
            cnn_features = self.cnn_encoder_3D(image)
        else:
            cnn_slices_features = self.cnn_encoder(image)  # Extract CNN features
            cnn_features = self.slice_aggregator(cnn_slices_features)
        radiomics_features = self.radiomics_encoder(radiomics)  # Encode Radiomics features

        fused_features = self.attention_fusion(cnn_features, radiomics_features)  # Fuse via attention
        output = self.classifier(fused_features)  # Classification
        return cnn_features, radiomics_features, output
            
class HybridAgePredictionModel(nn.Module):
    def __init__(self, input_channel=4, radio_channel=4, output_channel=1, pretrained_model=None, drop_out_rate=0):
        super(HybridAgePredictionModel, self).__init__()
        if pretrained_model is None:
            print("No pretrained model!")
        self.pretrained = pretrained_model
        self.slice_aggregator = SliceAggregator(method="attention")
        self.radiomics_encoder = RadiomicsFeatureEncoder(radio_channel)
        
        # Replace static weighted fusion with cross-attention based fusion
        self.cross_attention_fusion = CrossAttentionFusion(input_dim=512, hidden_dim=256)
        
        # Add auxiliary predictors for each branch
        self.aux_cnn_predictor = nn.Linear(512, 1)
        self.aux_radio_predictor = nn.Linear(512, 1)
        
        # Final classifier for the fused features
        self.classifier = Classifier()
        
        # Use GroupNorm for feature alignment
        self.cnn_bn = nn.GroupNorm(num_groups=16, num_channels=512)       
        self.radiomics_bn = nn.GroupNorm(num_groups=16, num_channels=512)
        
        # Optionally add dropout in the fusion block if needed
        self.dropout = nn.Dropout(drop_out_rate)

    def forward(self, image, radiomics):
        batch_size, num_slices, c, h, w = image.shape  # e.g., (subject, slices, 3, 224, 224)
        image = image.reshape(batch_size * num_slices, c, h, w)
        cnn_slices_features = self.pretrained(image)  # Extract CNN features, shape: (batch*slices, 512)
        cnn_slices_features = cnn_slices_features.reshape(batch_size, num_slices, -1)
        cnn_features = self.slice_aggregator(cnn_slices_features)  # (batch, 512)

        # Apply normalization to align scales
        cnn_features = self.cnn_bn(cnn_features)
        radiomics_features = self.radiomics_encoder(radiomics)      # (batch, 512)
        radiomics_features = self.radiomics_bn(radiomics_features)

        # Compute auxiliary predictions
        aux_cnn = self.aux_cnn_predictor(cnn_features)
        aux_radio = self.aux_radio_predictor(radiomics_features)

        # Fuse features using cross-attention
        fused_features = self.cross_attention_fusion(cnn_features, radiomics_features)
        fused_features = self.dropout(fused_features)  # Optional dropout

        # Main prediction
        output = self.classifier(fused_features)

        # Return main output and auxiliary outputs
        return cnn_features, radiomics_features, output, aux_cnn, aux_radio

# Full End-to-End Model
class ConcatAgePredictionModel(nn.Module):
    def __init__(self, input_channel, output_dim=1, add_xgb=None, drop_out_rate=0):
        self.use_xgb = add_xgb is not None
        super(ConcatAgePredictionModel, self).__init__()
        self.feature_extractor = resnet18(input_channel=input_channel, num_classes=512, drop_out_rate=drop_out_rate, return_feature=True)
        if self.use_xgb:
            self.prompt_fc = nn.Linear(1, 512)
            self.fc = nn.Sequential(
                nn.Linear(512 + 512, 256),
                nn.ReLU(),
                nn.Dropout(drop_out_rate),
                nn.Linear(256, output_dim)
            )
        else:
            self.fc = nn.Linear(512, output_dim)

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear) or isinstance(m, nn.Conv2d):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.zeros_(m.bias)

    def forward(self, x, prompt=None):
        #prompt is 1 * batch_size, reshape to batch_size * 1
        x = self.feature_extractor(x)
        x = x.reshape(x.size(0), -1)  # Flatten
        if self.use_xgb:
            prompt = prompt.view(-1, 1)
            # If xgb_age is provided, concatenate it with the feature
            xgb_age = F.relu(self.prompt_fc(prompt))
            x = torch.cat((x, xgb_age), dim=1)
        x = self.fc(x)  # (batch, output_dim)
        return x  # Return slice-wise features

# Full End-to-End Model
class FunctionAgePredictionModel(nn.Module):
    def __init__(self, input_channel, output_dim=1, add_xgb=None, drop_out_rate=0):
        self.use_xgb = add_xgb is not None
        super(FunctionAgePredictionModel, self).__init__()
        self.feature_extractor = SmallResNet(input_channel=input_channel, num_classes=128, drop_out_rate=drop_out_rate, return_feature=True)
        if self.use_xgb:
            self.prompt_fc = nn.Linear(1, 512)
            self.fc = nn.Sequential(
                nn.Linear(512 + 512, 256),
                nn.ReLU(),
                nn.Dropout(drop_out_rate),
                nn.Linear(256, output_dim)
            )
        else:
            self.fc = nn.Sequential(
                nn.BatchNorm1d(128),
                nn.Linear(128, 1)
            )
        self._init_weights()

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear) or isinstance(m, nn.Conv2d):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.zeros_(m.bias)

    def forward(self, x, prompt=None):
        #prompt is 1 * batch_size, reshape to batch_size * 1
        #x = x.permute(0, 3, 1, 2)
        x = self.feature_extractor(x)
        print(x)
        x = x.reshape(x.size(0), -1)  # Flatten
        if self.use_xgb:
            prompt = prompt.view(-1, 1)
            # If xgb_age is provided, concatenate it with the feature
            xgb_age = F.relu(self.prompt_fc(prompt))
            x = torch.cat((x, xgb_age), dim=1)
        x = self.fc(x)  # (batch, output_dim)
        print(x)
        return x  # Return slice-wise features

class FunctionAgePredictionModel_SSL(nn.Module):
    """
    SSL model for age *distribution* (1024 bins) with an auxiliary
    external-label prediction head used in Stage 2.

    Architecture
    ------------
    backbone        : SmallResNet_SSL (..., return_feature=True) → 256-D feats
    age_head        : Linear → 1024 logits (age distribution)
    prompt_block    : MLP applied in parallel to backbone features
    ext_head        : Linear → N_ext outputs (external labels regression)

    Forward returns:
        age_logits, ext_pred, feats
    """
    def __init__(self,
                 input_channel,
                 n_ext_labels=3,          # number of external label targets
                 drop_out_rate=0.,
                 add_xgb=None):           # kept for API symmetry; unused
        super().__init__()
        self.n_ext_labels = n_ext_labels

        # CNN feature backbone (returns 256-D features)
        # NOTE: return_feature=True so we can attach multiple heads.
        self.backbone = SmallResNet_SSL(
            input_channel=input_channel,
            num_classes=1024,            # classifier not used because we take features
            drop_out_rate=drop_out_rate,
            return_feature=True
        )

        feat_dim = 256   # matches SmallResNet_SSL final feature dim

        # Age distribution head (used in both Stage 1 & Stage 2)
        self.age_head = nn.Sequential(
            nn.BatchNorm1d(feat_dim),
            nn.Dropout(drop_out_rate),
            nn.Linear(feat_dim, 1024)   # logits over 1024 age bins
        )

        # Prompt block (parallel MLP) to transform features for external-label prediction
        self.prompt_block = nn.Sequential(
            nn.LayerNorm(feat_dim),
            nn.Linear(feat_dim, feat_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(drop_out_rate)
        )

        # External label regression head
        self.ext_head = nn.Linear(feat_dim, n_ext_labels)

        self._init_weights()

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, (nn.Linear, nn.Conv2d)):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if getattr(m, 'bias', None) is not None:
                    nn.init.zeros_(m.bias)

    def forward(self, x):
        """
        Parameters
        ----------
        x : (B, C, H, W) tensor

        Returns
        -------
        age_logits : (B, 1024)
        ext_pred   : (B, n_ext_labels)
        feats      : (B, 256) backbone features (useful for consistency losses)
        """
        feats = self.backbone(x)         # (B,256) because return_feature=True
        if feats.dim() > 2:
            feats = feats.reshape(feats.size(0), -1)

        age_logits = self.age_head(feats)          # -> (B,1024)

        # prompt branch for external labels
        prompt_feats = self.prompt_block(feats)    # (B,256)
        ext_pred = self.ext_head(prompt_feats)     # (B,n_ext_labels)

        return age_logits, ext_pred, feats

class BrainAgeGapModel(nn.Module):
    """
    Siamese network: embed two scans, then regress the age gap between them.
    """
    def __init__(self, input_channel=1, drop_out_rate=0, hidden_dim=256):
        super().__init__()
        self.embedding_net = resnet18_3d(input_channel=input_channel, num_classes=512, return_feature=True)

        # Regression head: input is the absolute difference of embeddings
        self.regressor = nn.Sequential(
            nn.Linear(512, hidden_dim),
            nn.ReLU(inplace=True),
            #nn.Dropout(0.5),
            nn.Linear(hidden_dim, 1)
        )

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear) or isinstance(m, nn.Conv2d):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.zeros_(m.bias)

    def forward(self, scan1, scan2):
        """
        scan1, scan2: each (B, C, D, H, W)
        returns: (B, 1) predicted age gap (scan2_age - scan1_age)
        """
        e1 = self.embedding_net(scan1)            # (B, E)
        e2 = self.embedding_net(scan2)            # (B, E)
        diff = e2 - e1                 # (B, E)
        gap = self.regressor(diff)                # (B, 1)
        return gap

class MDNHead(nn.Module):
    """
    Mixture head over a 1D target (age).
    Inputs:  h (B,H)
    Outputs: pi (B,M), mu (B,M), sigma (B,M)
    """
    def __init__(self, in_dim: int, n_components: int = 5, hidden: int = 256, drop: float = 0.0):
        super().__init__()
        self.n_components = n_components
        self.trunk = nn.Sequential(
            nn.Linear(in_dim, hidden),
            nn.ReLU(inplace=True),
            nn.Dropout(drop),
            nn.Linear(hidden, hidden),
            nn.ReLU(inplace=True),
            nn.Dropout(drop),
        )
        self.pi_fc    = nn.Linear(hidden, n_components)
        self.mu_fc    = nn.Linear(hidden, n_components)
        self.sigma_fc = nn.Linear(hidden, n_components)

    def forward(self, h, temperature: float = 1.0):
        z = self.trunk(h)
        logits = self.pi_fc(z)
        if temperature != 1.0:
            logits = logits / temperature
        pi = F.softmax(logits, dim=-1)                        # (B,M), sum=1
        mu = self.mu_fc(z)                                    # (B,M)
        sigma = F.softplus(self.sigma_fc(z)) + 1e-3           # (B,M) > 0
        return pi, mu, sigma

class FunctionAgePredictionModel_MDN_SSL(nn.Module):
    """
    SSL model with an MDN age head and external-label head.
    Uses only image features from SmallResNet_SSL (return_feature=True).

    Forward returns:
        pi, mu, sigma, ext_pred, feats
    """
    def __init__(self,
                 input_channel,
                 n_ext_labels=3,
                 n_components=5,
                 drop_out_rate=0.,
                 add_xgb=None):   # kept for API symmetry; unused
        super().__init__()
        self.n_ext_labels = n_ext_labels
        self.n_components = n_components

        # Backbone -> 256-D features (assumes you have SmallResNet_SSL defined elsewhere)
        self.backbone = SmallResNet_SSL(
            input_channel=input_channel,
            num_classes=1024,            # classifier not used because we take features
            drop_out_rate=drop_out_rate,
            return_feature=True
        )
        feat_dim = 256

        # MDN age head (replaces 1024-bin distribution head)
        self.age_mdn = MDNHead(in_dim=feat_dim, n_components=n_components,
                               hidden=256, drop=drop_out_rate)

        # Prompt block (parallel MLP) to transform features for external-label prediction
        self.prompt_block = nn.Sequential(
            nn.LayerNorm(feat_dim),
            nn.Linear(feat_dim, feat_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(drop_out_rate)
        )

        # External label regression head
        self.ext_head = nn.Linear(feat_dim, n_ext_labels)

        self._init_weights()

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, (nn.Linear, nn.Conv2d)):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if getattr(m, 'bias', None) is not None:
                    nn.init.zeros_(m.bias)

    def forward(self, x, temperature: float = 1.0):
        """
        x : (B, C, H, W)

        Returns
        -------
        pi      : (B, M)
        mu      : (B, M)
        sigma   : (B, M)
        ext_pred: (B, n_ext_labels)
        feats   : (B, 256)
        """
        feats = self.backbone(x)         # (B,256) because return_feature=True
        if feats.dim() > 2:
            feats = feats.reshape(feats.size(0), -1)

        pi, mu, sigma = self.age_mdn(feats, temperature=temperature)

        # external labels
        prompt_feats = self.prompt_block(feats)
        ext_pred     = self.ext_head(prompt_feats)

        return pi, mu, sigma, ext_pred, feats

    # ---- helpers ----
    @torch.no_grad()
    def predict_expectation(self, x, temperature: float = 1.0):
        pi, mu, sigma, _, _ = self.forward(x, temperature=temperature)
        return mdn_expectation(pi, mu)

    @torch.no_grad()
    def sample_ages(self, x, n_samples: int = 50, temperature: float = 1.0):
        pi, mu, sigma, _, _ = self.forward(x, temperature=temperature)
        samples, _ = mdn_sample(pi, mu, sigma, n_samples=n_samples)
        return samples  # (S,B)