import cv2
import numpy as np
import torch
import copy

class Resize(object):
    def __init__(self, output_size):
        self.output_size = output_size

    def __call__(self, X, Y):
        _X = cv2.resize(X, self.output_size)
        w, h = self.output_size
        c = Y.shape[-1]
        _Y = np.zeros((h, w, c))
        for i in range(Y.shape[-1]):
            _Y[..., i] = cv2.resize(Y[..., i], self.output_size)
        return _X, _Y

class Normalize(object):
    def __call__(self, X, dim=None):
        if not dim:
            mini = torch.min(X)
            maxi = torch.max(X)
        elif type(dim) == tuple or list:
            mini = copy.deepcopy(X)
            maxi = copy.deepcopy(X)
            for d in dim:
                mini = torch.min(mini, dim=d, keepdim=True).values
                maxi = torch.max(maxi, dim=d, keepdim=True).values
        elif type(dim) == int:
            mini = torch.min(X, dim)
            maxi = torch.max(X, dim)
            
        X = (X - mini) / (maxi - mini)    
        return X

class Standardize(object):
    def __init__(self, axis=None, value=None):
        self.axis = axis
        self.value = value

    def __call__(self, X):
        if self.value:
            X = (X-self.value[0])/self.value[1]
        else:
            mean =  np.mean(X, self.axis)
            std = np.std(X, self.axis)
            X = (X - mean) / std
        return X

class ToTensor(object):
    def __init__(self, X_type=None, Y_type=None):
        # must bu torch types
        self.X_type = X_type
        self.Y_type = Y_type

    def __call__(self, X, Y):

        # swap color axis because
        # numpy img_shape: H x W x C
        # torch img_shape: C X H X W
        X = X.transpose((2, 0, 1))
        Y = Y.transpose((2, 0, 1))

        # convert to tensor
        X = torch.from_numpy(X.copy())
        Y = torch.from_numpy(Y.copy())

        if self.X_type is not None:
            X = X.type(self.X_type)
        if self.Y_type is not None:
            Y = Y.type(self.Y_type)
        return X, Y

class Flip(object):
    def __call__(self, X, Y):
        for axis in [0, 1]:
            if np.random.rand(1) < 0.5:
                X = np.flip(X, axis)
                Y = np.flip(Y, axis)
        return X, Y

class Crop(object):
    def __init__(self, size):
        self.size= np.array(list(size))

    def __call__(self, X, Y):
        # random size
        h = self.size[0]
        w = self.size[1]
        # random place
        shift_h = np.random.randint(0, X.shape[0] - h)
        shift_w = np.random.randint(0, X.shape[1] - w)
        X = X[shift_h:shift_h+h, shift_w:shift_w+w]
        Y = Y[shift_h:shift_h+h, shift_w:shift_w+w]

        return X, Y

