import os
import sys
import glob
import shutil


# Recent run of covid should have this format.... inside it has no_sample subdirectory and the batch run which is what we want

def move_recent_batch(destiny):
    minknow_dir = "/var/lib/minknow/data/SARS*"
    files = glob.glob(minknow_dir)
    latest_run = max(files,key=os.path.getctime)
    batch = ''.join(os.listdir(f"{latest_run}/no_sample"))
    shutil.move(f"{latest_run}/no_sample/{batch}",destiny)
    return batch

def get_recent_batch():
    minion_runs = f"{os.environ['HOME']}/data/minion_runs/*"
    dirs = glob.glob(minion_runs)
    latest_run = max(dirs,key=os.path.getctime)
    batch = latest_run.split('/')[-1]
    
# Get batch recent run of covid seq
# batch = move_recent_batch()
# os.environ['BATCH'] = batch
# print(batch)
# minknow_dir = "/var/lib/minknow/data/SARS*"
# files = glob.glob(minknow_dir)
# latest_run = max(files,key=os.path.getctime)
# print(os.listdir(f"{latest_run}/no_sample"))

get_recent_batch()