import os
import sys
import glob



# Recent run of covid should have this format.... inside it has no_sample subdirectory and the batch run which is what we want

def get_recent_run():
    minknow_dir = "/var/lib/minknow/data/*"
    files = glob.glob(minknow_dir)
    latest_run = max(files,key=os.path.getctime)
    return ''.join(os.listdir(f"{latest_run}/no_sample"))

# Get recent run of covid seq
batch = get_recent_run()

print(batch)

