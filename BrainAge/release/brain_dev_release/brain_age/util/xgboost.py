#kpiimport radiomics
import six
import os 
import sklearn
import pandas as pd
import mrmr
import torch
from sklearn.feature_selection import SelectKBest, f_classif
from sklearn.linear_model import Lasso
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.svm import SVC
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import learning_curve
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import KFold
from sklearn.model_selection import cross_val_score
from sklearn.metrics import confusion_matrix, classification_report, accuracy_score
#from radiomics import featureextractor
import xgboost as xgb
import numpy as np
import SimpleITK as sitk
#from radiomics import getTestCase
from mrmr import mrmr_classif, mrmr_regression
import ast
from collections import OrderedDict
import re
import yaml
import seaborn as sns
import matplotlib.pyplot as plt
from imblearn.over_sampling import SMOTE
from supervised.automl import AutoML
import sys
import shap

source_folder = "/common/lidxxlab/Yifan/Radiomics/Radiomics"
data_folder = "/common/lidxxlab/Yifan/BrainAge/data"
#get file_yaml path from input
file_yaml = "/common/lidxxlab/Yifan/BrainAge/classifier/exp10_t1w.yaml"

def str_to_ordered_dict():
    return OrderedDict(eval(s[12:-1]))

def get_yaml():
    rf = open(file=file_yaml, mode='r', encoding='utf-8')
    crf = rf.read()
    rf.close()  # 关闭文件
    yaml_data = yaml.load(stream=crf, Loader=yaml.FullLoader)
    return yaml_data

def XGBRegressor(patient_id, age, sex, modality):
    # change all elements in features to float
    current_row = {}
    yaml_data = get_yaml()
    
    Region_List = yaml_data['region_regression']
    dataset = yaml_data['dataset']
    Type_List = yaml_data['type']
    print(patient_id, age)
    source_path = source_folder + '_' + str(dataset[0]) + '/' + patient_id + '/' + str(age) + '/'
    if modality == 't1w':
        cur_path = source_path + 'T1w/'
        source = 'T1w'
    elif modality == 't1map':
        cur_path = source_path + 'T1map_new/'
        source = 'T1map_new'
    elif modality == 't2map':
        cur_path = source_path + 'T2map_new/'   
        source = 'T2map_new'
    for region in Region_List:
        region_path = cur_path + str(region) + '.csv'
        #print(region_path)
        if os.path.exists(region_path):
            #print(region_path)
            tmp = pd.read_csv(region_path)
            #add tmp to current_row
            for column in tmp.columns:
                if column == 'Unnamed: 0':
                    continue
                #if Type_List is not empty, only add the columns in Type_List
                if Type_List:
                    #if the prefix of the column is in Type_List, add to current_row
                    if any([column.startswith(prefix) for prefix in Type_List]):
                        #print(column)
                        current_row[source + '_' + str(region) + '_' + column] = tmp[column].values[0]
                else:
                    #get the first value of the column and add to current_row
                    current_row[source + '_' + str(region) + '_' + column] = tmp[column].values[0]
        
    #print(current_row)
    #change current_row to pd.Dataframe and concat to features
    current_row = pd.DataFrame.from_dict(current_row, orient='index')
    current_row = current_row.transpose()
    current_row.astype(float)
    current_row['Sex'] = sex

    #if current_row is empty, return None
    if current_row.empty:
        print("current_row is empty")
        return float(75)
    model = AutoML(results_path='/common/lidxxlab/Yifan/BrainAge/Results/exp_comp/non_cross/' + modality + '/model')
    pred = model.predict(current_row)
    print(pred)
    return float(pred[0])
