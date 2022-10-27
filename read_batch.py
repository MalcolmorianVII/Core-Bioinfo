# Assume you have got a text file that tracks batches already processed
# Before the pipeline runs i.e second subworkflow you need to read that text file
# And check if the current batch is in there if it is then proceed with step 3
# Step 2 will result in batch name being written to the processed_batch.txt

batch = ""
track_batch_file = ""
def write_batch():
    with open(track_batch_file,"a") as f:
        f.write(batch)

def search_batch(batch):
    with open(track_batch_file,"r") as f:
        batches = f.read()
        if batch in batches:
            return True
    return False


