import pandas as pd
import numpy as np
df = pd.read_excel("/home/bkutambe/data/minion_runs/20220618_1327_MN33881_FAQ93003_eb27fdc5.xlsx")
barcodes = df[ df['ID'] != 'neg']['barcode'].dropna(axis=0).astype('int64').to_list()
barcodes = [ f"barcode{i}" for i in barcodes]
print(barcodes)





