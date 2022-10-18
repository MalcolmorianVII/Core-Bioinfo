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


def write_to_configs():
    batch = move_recent_batch()
    with open("nextflow.config",'r+') as config_file:
        configs = config_file.read()
        configs = configs.replace("current_batch",batch)
        config_file.write(configs)
    
write_to_configs()