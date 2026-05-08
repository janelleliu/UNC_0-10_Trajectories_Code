import numpy as np
import matplotlib.pyplot as plt
import os
import pandas as pd

class AverageMeter(object):
    """Computes and stores the average and current value"""
    def __init__(self):
        self.reset()

    def reset(self):
        self.val = 0
        self.avg = 0
        self.sum = 0
        self.count = 0

    def update(self, val, n=1):
        self.val = val
        self.sum += val * n
        self.count += n
        self.avg = self.sum / self.count


def save_configs(args):
    message = ''

    message += '++++++++++++++++ Train related parameters ++++++++++++++++ \n'

    for k, v in sorted(vars(args).items()):
        comment = ''
        message += '{:>25}: {:<30}{}\n'.format(str(k), str(v), comment)
    message += '++++++++++++++++  End of show parameters ++++++++++++++++ '

    args.file_name = os.path.join(args.output_dir, 'log_file.txt')

    with open(args.file_name, 'wt') as args_file:
        args_file.write(message)
        args_file.write('\n')


def calculate_class_weights(csv_file, age_column='AgeInt'):
    df = pd.read_csv(csv_file)
    df = df[df['mode']=='train']
    df['AgeInt'] = df['Age'].astype(int)
    
    # Calculate frequency of each age
    age_counts = df[age_column].value_counts().sort_index()
    
    # Calculate inverse frequency (class weights)
    total_samples = len(df)
    class_weights = {age: total_samples / count *0.1 for age, count in age_counts.items()}
    
    return class_weights
