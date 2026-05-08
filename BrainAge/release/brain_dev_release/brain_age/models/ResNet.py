import torch
import torch.nn as nn
import torch.nn.functional as F

# ---------------- Standard ResNet Components and Variants ----------------

class BasicBlock(nn.Module):
    expansion = 1
    def __init__(self, in_planes, planes, stride=1):
        super(BasicBlock, self).__init__()
        self.conv1 = nn.Conv2d(in_planes, planes, kernel_size=3, stride=stride, padding=1, bias=False)
        self.bn1 = nn.BatchNorm2d(planes)
        self.conv2 = nn.Conv2d(planes, planes, kernel_size=3, stride=1, padding=1, bias=False)
        self.bn2 = nn.BatchNorm2d(planes)
        self.shortcut = nn.Sequential()
        if stride != 1 or in_planes != self.expansion*planes:
            self.shortcut = nn.Sequential(
                nn.Conv2d(in_planes, self.expansion*planes, kernel_size=1, stride=stride, bias=False),
                nn.BatchNorm2d(self.expansion*planes)
            )
    def forward(self, x):
        out = F.relu(self.bn1(self.conv1(x)))
        out = self.bn2(self.conv2(out))
        out += self.shortcut(x)
        out = F.relu(out)
        return out

class Bottleneck(nn.Module):
    expansion = 4
    def __init__(self, in_planes, planes, stride=1):
        super(Bottleneck, self).__init__()
        self.conv1 = nn.Conv2d(in_planes, planes, kernel_size=1, bias=False)
        self.bn1 = nn.BatchNorm2d(planes)
        self.conv2 = nn.Conv2d(planes, planes, kernel_size=3, stride=stride, padding=1, bias=False)
        self.bn2 = nn.BatchNorm2d(planes)
        self.conv3 = nn.Conv2d(planes, self.expansion*planes, kernel_size=1, bias=False)
        self.bn3 = nn.BatchNorm2d(self.expansion*planes)
        self.shortcut = nn.Sequential()
        if stride != 1 or in_planes != self.expansion*planes:
            self.shortcut = nn.Sequential(
                nn.Conv2d(in_planes, self.expansion*planes, kernel_size=1, stride=stride, bias=False),
                nn.BatchNorm2d(self.expansion*planes)
            )
    def forward(self, x):
        out = F.relu(self.bn1(self.conv1(x)))
        out = F.relu(self.bn2(self.conv2(out)))
        out = self.bn3(self.conv3(out))
        out += self.shortcut(x)
        out = F.relu(out)
        return out

class ResNet(nn.Module):
    def __init__(self, block, num_blocks, num_classes=1, input_channel=3, drop_out_rate=0., return_feature=False):
        super(ResNet, self).__init__()
        self.in_planes = 64
        self.drop_out_rate = drop_out_rate
        self.return_feature = return_feature
        if self.drop_out_rate > 0:
            self.dropout = nn.Dropout(p=drop_out_rate)
        self.conv1 = nn.Conv2d(input_channel, 64, kernel_size=7, stride=2, padding=3, bias=False)
        self.bn1 = nn.BatchNorm2d(64)
        self.relu = nn.ReLU(inplace=True)
        self.maxpool = nn.MaxPool2d(kernel_size=3, stride=2, padding=1)
        self.layer1 = self._make_layer(block, 64, num_blocks[0], stride=1)
        self.layer2 = self._make_layer(block, 128, num_blocks[1], stride=2)
        self.layer3 = self._make_layer(block, 256, num_blocks[2], stride=2)
        self.layer4 = self._make_layer(block, 512, num_blocks[3], stride=2)
        self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
        self.fc = nn.Linear(512 * block.expansion, num_classes)
    def _make_layer(self, block, planes, num_blocks, stride):
        strides = [stride] + [1]*(num_blocks-1)
        layers = []
        for stride in strides:
            layers.append(block(self.in_planes, planes, stride))
            self.in_planes = planes * block.expansion
        return nn.Sequential(*layers)
    def forward(self, x):
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.maxpool(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        if self.drop_out_rate > 0:
            x = self.dropout(x)
        if self.return_feature:
            return x
        return self.fc(x)

# Example: ResNet18, ResNet34, ResNet50, etc.
def resnet18(num_classes=1, input_channel=3, drop_out_rate=0., return_feature=False):
    return ResNet(BasicBlock, [2,2,2,2], num_classes=num_classes, input_channel=input_channel, drop_out_rate=drop_out_rate, return_feature=return_feature)
def resnet34(num_classes=1, input_channel=3, drop_out_rate=0., return_feature=False):
    return ResNet(BasicBlock, [3,4,6,3], num_classes=num_classes, input_channel=input_channel, drop_out_rate=drop_out_rate, return_feature=return_feature)
def resnet50(num_classes=1, input_channel=3, drop_out_rate=0., return_feature=False):
    return ResNet(Bottleneck, [3,4,6,3], num_classes=num_classes, input_channel=input_channel, drop_out_rate=drop_out_rate, return_feature=return_feature)
def resnet101(num_classes=1, input_channel=3, drop_out_rate=0., return_feature=False):
    return ResNet(Bottleneck, [3,4,23,3], num_classes=num_classes, input_channel=input_channel, drop_out_rate=drop_out_rate, return_feature=return_feature)
def resnet152(num_classes=1, input_channel=3, drop_out_rate=0., return_feature=False):
    return ResNet(Bottleneck, [3,8,36,3], num_classes=num_classes, input_channel=input_channel, drop_out_rate=drop_out_rate, return_feature=return_feature)

# ---------------- ResNet with Radiomics ----------------

class ResNet_with_Radiomics(nn.Module):
    def __init__(self, block, num_blocks, num_classes=1, input_channel=3, radiomics_dim=0, drop_out_rate=0., return_feature=False):
        super(ResNet_with_Radiomics, self).__init__()
        self.in_planes = 64
        self.radiomics_dim = radiomics_dim
        self.drop_out_rate = drop_out_rate
        self.return_feature = return_feature
        if self.drop_out_rate > 0:
            self.dropout = nn.Dropout(p=drop_out_rate)
        self.conv1 = nn.Conv2d(input_channel, 64, kernel_size=7, stride=2, padding=3, bias=False)
        self.bn1 = nn.BatchNorm2d(64)
        self.relu = nn.ReLU(inplace=True)
        self.maxpool = nn.MaxPool2d(kernel_size=3, stride=2, padding=1)
        self.layer1 = self._make_layer(block, 64, num_blocks[0], stride=1)
        self.layer2 = self._make_layer(block, 128, num_blocks[1], stride=2)
        self.layer3 = self._make_layer(block, 256, num_blocks[2], stride=2)
        self.layer4 = self._make_layer(block, 512, num_blocks[3], stride=2)
        self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
        self.fc = nn.Linear(512 * block.expansion + radiomics_dim, num_classes)
    def _make_layer(self, block, planes, num_blocks, stride):
        strides = [stride] + [1]*(num_blocks-1)
        layers = []
        for stride in strides:
            layers.append(block(self.in_planes, planes, stride))
            self.in_planes = planes * block.expansion
        return nn.Sequential(*layers)
    def forward(self, x, radiomics=None):
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.maxpool(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        if self.radiomics_dim > 0 and radiomics is not None:
            x = torch.cat([x, radiomics], dim=1)
        if self.drop_out_rate > 0:
            x = self.dropout(x)
        if self.return_feature:
            return x
        return self.fc(x)

def ResNet18_with_Radiomics(num_classes=1, input_channel=3, radiomics_dim=0, drop_out_rate=0., return_feature=False):
    return ResNet_with_Radiomics(BasicBlock, [2,2,2,2], num_classes=num_classes, input_channel=input_channel, radiomics_dim=radiomics_dim, drop_out_rate=drop_out_rate, return_feature=return_feature)

def ResNet50_with_Radiomics(num_classes=1, input_channel=3, radiomics_dim=0, drop_out_rate=0., return_feature=False):
    return ResNet_with_Radiomics(Bottleneck, [3,4,6,3], num_classes=num_classes, input_channel=input_channel, radiomics_dim=radiomics_dim, drop_out_rate=drop_out_rate, return_feature=return_feature)

# ---------------- Cross Attention Block ----------------

class CrossAttentionBlock(nn.Module):
    def __init__(self, feature_dim, radiomics_dim, hidden_dim=128):
        super(CrossAttentionBlock, self).__init__()
        # Project both image features and radiomics features to hidden_dim
        self.image_proj = nn.Linear(feature_dim, hidden_dim)
        self.radiomics_proj = nn.Linear(radiomics_dim, hidden_dim)
        self.attn = nn.MultiheadAttention(hidden_dim, num_heads=4, batch_first=True)
        self.out_proj = nn.Linear(hidden_dim, feature_dim)
    def forward(self, img_feat, radiomics_feat):
        # img_feat: (B, F), radiomics_feat: (B, R)
        img_proj = self.image_proj(img_feat).unsqueeze(1)  # (B, 1, H)
        rad_proj = self.radiomics_proj(radiomics_feat).unsqueeze(1)  # (B, 1, H)
        # Concatenate as sequence: [img, rad]
        seq = torch.cat([img_proj, rad_proj], dim=1)  # (B, 2, H)
        attn_out, _ = self.attn(seq, seq, seq)  # (B, 2, H)
        img_out = attn_out[:,0,:]  # (B, H)
        img_out = self.out_proj(img_out)  # (B, F)
        return img_out

# ---------------- ResNet with Radiomics Attention ----------------

class ResNet_Radiomics_Attn(nn.Module):
    def __init__(self, block, num_blocks, num_classes=1, input_channel=3, radiomics_dim=0, drop_out_rate=0., return_feature=False, attn_hidden_dim=128):
        super(ResNet_Radiomics_Attn, self).__init__()
        self.in_planes = 64
        self.radiomics_dim = radiomics_dim
        self.drop_out_rate = drop_out_rate
        self.return_feature = return_feature
        self.attn_hidden_dim = attn_hidden_dim
        if self.drop_out_rate > 0:
            self.dropout = nn.Dropout(p=drop_out_rate)
        self.conv1 = nn.Conv2d(input_channel, 64, kernel_size=7, stride=2, padding=3, bias=False)
        self.bn1 = nn.BatchNorm2d(64)
        self.relu = nn.ReLU(inplace=True)
        self.maxpool = nn.MaxPool2d(kernel_size=3, stride=2, padding=1)
        self.layer1 = self._make_layer(block, 64, num_blocks[0], stride=1)
        self.layer2 = self._make_layer(block, 128, num_blocks[1], stride=2)
        self.layer3 = self._make_layer(block, 256, num_blocks[2], stride=2)
        self.layer4 = self._make_layer(block, 512, num_blocks[3], stride=2)
        self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
        self.cross_attn = CrossAttentionBlock(512 * block.expansion, radiomics_dim, hidden_dim=attn_hidden_dim)
        self.fc = nn.Linear(512 * block.expansion, num_classes)
    def _make_layer(self, block, planes, num_blocks, stride):
        strides = [stride] + [1]*(num_blocks-1)
        layers = []
        for stride in strides:
            layers.append(block(self.in_planes, planes, stride))
            self.in_planes = planes * block.expansion
        return nn.Sequential(*layers)
    def forward(self, x, radiomics=None):
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.maxpool(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        if self.radiomics_dim > 0 and radiomics is not None:
            x = self.cross_attn(x, radiomics)
        if self.drop_out_rate > 0:
            x = self.dropout(x)
        if self.return_feature:
            return x
        return self.fc(x)

def ResNet18_Radiomics_Attn(num_classes=1, input_channel=3, radiomics_dim=0, drop_out_rate=0., return_feature=False, attn_hidden_dim=128):
    return ResNet_Radiomics_Attn(BasicBlock, [2,2,2,2], num_classes=num_classes, input_channel=input_channel, radiomics_dim=radiomics_dim, drop_out_rate=drop_out_rate, return_feature=return_feature, attn_hidden_dim=attn_hidden_dim)

def ResNet50_Radiomics_Attn(num_classes=1, input_channel=3, radiomics_dim=0, drop_out_rate=0., return_feature=False, attn_hidden_dim=128):
    return ResNet_Radiomics_Attn(Bottleneck, [3,4,6,3], num_classes=num_classes, input_channel=input_channel, radiomics_dim=radiomics_dim, drop_out_rate=drop_out_rate, return_feature=return_feature, attn_hidden_dim=attn_hidden_dim)

class SmallResNet(nn.Module):
    def __init__(self, num_classes=1, input_channel=3, drop_out_rate=0., return_feature=False):
        super().__init__()
        self.in_channels = 32
        self.drop_out_rate = drop_out_rate
        self.return_feature = return_feature
        if self.drop_out_rate > 0:
            self.dropout = nn.Dropout(p=drop_out_rate)

        self.conv1 = nn.Sequential(
            nn.Conv2d(input_channel, 32, kernel_size=3, stride=1, padding=1, bias=False),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True)
        )

        self.layer1 = self._make_layer(BasicBlock, 32, 2, stride=2)  # → ~23×27
        self.layer2 = self._make_layer(BasicBlock, 64, 2, stride=2)  # → ~12×14
        self.layer3 = self._make_layer(BasicBlock, 128, 2, stride=1) # → 12×14

        self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
        self.fc = nn.Linear(128, num_classes)

    def _make_layer(self, block, out_channels, num_blocks, stride):
        layers = []
        layers.append(block(self.in_channels, out_channels, stride))
        self.in_channels = out_channels * block.expansion
        for _ in range(1, num_blocks):
            layers.append(block(self.in_channels, out_channels, stride=1))
        return nn.Sequential(*layers)

    def forward(self, x):
        x = self.conv1(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        if self.drop_out_rate > 0:
            x = self.dropout(x)
        if self.return_feature:
            return x
        return self.fc(x)

class SmallResNet_SSL(nn.Module):
    def __init__(self, num_classes=512, input_channel=3, drop_out_rate=0., return_feature=False):
        super().__init__()
        self.in_channels = 32
        self.drop_out_rate = drop_out_rate
        self.return_feature = return_feature
        if self.drop_out_rate > 0:
            self.dropout = nn.Dropout(p=drop_out_rate)

        self.conv1 = nn.Sequential(
            nn.Conv2d(input_channel, 32, kernel_size=3, stride=1, padding=1, bias=False),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True)
        )

        self.layer1 = self._make_layer(BasicBlock, 32, 2, stride=2)  # → ~23×27
        self.layer2 = self._make_layer(BasicBlock, 64, 2, stride=2)  # → ~12×14
        self.layer3 = self._make_layer(BasicBlock, 128, 2, stride=1) # → 12×14
        self.layer4 = self._make_layer(BasicBlock, 256, 2, stride=1) # → 12×14

        self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
        self.fc = nn.Linear(256, num_classes)

    def _make_layer(self, block, out_channels, num_blocks, stride):
        layers = []
        layers.append(block(self.in_channels, out_channels, stride))
        self.in_channels = out_channels * block.expansion
        for _ in range(1, num_blocks):
            layers.append(block(self.in_channels, out_channels, stride=1))
        return nn.Sequential(*layers)

    def forward(self, x):
        x = self.conv1(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)
        if self.drop_out_rate > 0:
            x = self.dropout(x)
        if self.return_feature:
            return x
        return self.fc(x)