import torch
import torch.nn as nn
from .ResNet import resnet50, resnet18
from .ResNet3D import resnet18_3d


class MultiInputModel(nn.Module):
    def __init__(self, input_channel=3, num_classes=3):
        super(MultiInputModel, self).__init__()
        # Use a pretrained ResNet for image processing
        self.resnet = resnet18(input_channel=input_channel, num_classes=num_classes)
        self.resnet.fc = nn.Linear(self.resnet.fc.in_features, 128)
        
        # A fully connected layer for age and predicted age
        self.age_fc = nn.Sequential(
            nn.Linear(2, 32),
            nn.ReLU()
        )
        
        # Combined layers
        self.classifier = nn.Sequential(
            nn.Linear(128 + 32, 64),
            nn.ReLU(),
            nn.Linear(64, 3)  # 3 output classes: NC, MCI, AD
        )
        
    def forward(self, image, age, predicted_age):
        image_features = self.resnet(image)
        age_features = self.age_fc(torch.cat((age, predicted_age), dim=1))
        combined = torch.cat((image_features, age_features), dim=1)
        output = self.classifier(combined)
        return output


class MultiInputModel3D(nn.Module):
    def __init__(self, input_channel=3, num_classes=3):
        super(MultiInputModel3D, self).__init__()
        # Use a pretrained ResNet for image processing
        self.resnet = resnet18_3d(input_channel=input_channel, num_classes=num_classes)
        self.resnet.fc = nn.Linear(self.resnet.fc.in_features, 128)
        
        # A fully connected layer for age and predicted age
        self.age_fc = nn.Sequential(
            nn.Linear(2, 32),
            nn.ReLU()
        )
        
        # Combined layers
        self.classifier = nn.Sequential(
            nn.Linear(128 + 32, 64),
            nn.ReLU(),
            nn.Linear(64, 3)  # 3 output classes: NC, MCI, AD
        )
        
    def forward(self, image, age, predicted_age):
        image_features = self.resnet(image)
        age_features = self.age_fc(torch.cat((age, predicted_age), dim=1))
        combined = torch.cat((image_features, age_features), dim=1)
        output = self.classifier(combined)
        return output