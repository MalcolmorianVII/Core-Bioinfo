import os
import glob
import pandas as pd
from pathlib import Path
import sys

class DuplicationError(Exception):
    pass

def guppyplex(input_dir, batch_name, max_min):
    fastq = glob.glob(f'{input_dir}/*fastq*')
    basename = fastq[0].split('/')[-1].split('.')[0]
    guppyplex_fastq = f'{input_dir}/{basename}.guppyplex.fastq'
    
    if os.path.isfile(guppyplex_fastq):
        return guppyplex_fastq
    
    if len(fastq) == 0:
        os.system(f"touch error_no_fastq_in_{input_dir.replace('/', '_')}")
        return False
    os.system(f"artic guppyplex --min-length {max_min[0]} --max-length {max_min[1]} --directory {input_dir} --prefix {batch_name} --out {guppyplex_fastq}")
    return guppyplex_fastq

def artic_minion_medaka(primer_scheme_directory, scheme, barcode, medaka_model, guppyplex_fastq, batch_name):
    os.system(f'artic minion --medaka --scheme-directory {primer_scheme_directory} --medaka-model {medaka_model} --normalise 200 --threads 4 --read-file {guppyplex_fastq} {scheme} {batch_name}_{barcode}')

def run_qc(barcode, batch_name):
    os.system(f'python ~/programs/ncov2019-artic-nf/bin/qc.py --nanopore --outfile {batch_name}_{barcode}.qc.csv --sample {batch_name}_{barcode} --ref ~/programs/Path_nCoV/reference/primer-schemes/SARS-CoV-2/V3/SARS-CoV-2.reference.fasta --bam {batch_name}_{barcode}.primertrimmed.rg.sorted.bam --fasta {batch_name}_{barcode}.consensus.fasta')

def run_amplicov(bed_file, barcode, scheme):
    print(f'amplicov --bed {bed_file} --bam {barcode}.primertrimmed.rg.sorted.bam -o amplicov-{scheme} -p {barcode}')

def run_samtools_depth(barcode, batch_name):
    os.system(f'samtools depth -aa -o {batch_name}_{barcode}.primertrimmed.rg.sorted.bam.depth {batch_name}_{barcode}.trimmed.rg.sorted.bam')

def gather_consensus_fastas(batch_name):
    os.system(f'cat {batch_name}*.consensus.fasta > tmp')
    os.system(f'mv tmp {batch_name}.consensus.fasta')

def gather_qc_csvs(batch_name):
    os.system(f'cat {batch_name}*.csv > tmp')
    os.system(f'awk \'!seen[$0]++\' tmp > {batch_name}.qc.csv')



def get_barcodes():
    df = pd.read_csv(os.environ.get('SEQTRACKER'))
    barcodes =  df[ df['Sample ID'] != 'neg']['Barcode'].dropna(axis=0).astype('int64').tolist() # Get all the non-null barcodes whose ID is not neg & convert from float to int to str & Add words "barcode" to each row 
    return [ "barcode0" + str(i) if i < 10 else "barcode" + str(i) for i in barcodes ]

def run_with_different_schemes_and_models():
    root_dir = sys.argv[1]
    primer_scheme = sys.argv[2] 
    primer_scheme_directory = f'{os.environ.get("PRIMER_SCHEME_DIRECTORY")}'
    # v1 is UNZA, v2 is Midnight, v3 is artic v3, v4 is artic v4
    # {batch:{scheme:[barcodes, etc]}} this way, we can handle multiple schemes and multiple batches in one function.
    barcodes = get_barcodes()
    batches_schemes_barcodes = {os.environ.get('BATCH'):{f'SARS-CoV-2/{primer_scheme}':barcodes}} 
    batches_basecallers = {os.environ.get('BATCH'):'r941_min_sup_g507'}

    scheme_cutoffs = {'SARS-CoV-2/V1': [750, 1250], 'SARS-CoV-2/V2':[950, 1450], 'SARS-CoV-2/V3':[400, 700], 'SARS-CoV-2/V4':[400, 700]}
    for batch in batches_schemes_barcodes:
        for scheme in batches_schemes_barcodes[batch]:
            for barcode in batches_schemes_barcodes[batch][scheme]:
                if os.path.exists(f'{batch}_{barcode}.primertrimmed.rg.sorted.bam'):
                    continue
                input_dir = f'{root_dir}/fastq_pass/{barcode}'
                # todo - need to add something here to check that the fastq exists, and if not continue
                # todo - i'm pretty sure this try except loop isn't doing anything, so should remove it.
                try:
                    guppyplex_fastq = guppyplex(input_dir, batch, scheme_cutoffs[scheme])
                except DuplicationError:
                    pass
                if guppyplex_fastq is False:
                    print(f'Guppyplex is false for barcode{barcode}')
                    continue
                artic_minion_medaka(primer_scheme_directory, scheme, barcode, batches_basecallers[batch], guppyplex_fastq, batch)
                if os.path.exists(f'{batch}_{barcode}.consensus.fasta'):
                    run_qc(barcode, batch)
                else:
                    continue
                run_samtools_depth(barcode, batch)
        gather_consensus_fastas(batch)
        gather_qc_csvs(batch)


if __name__ == '__main__':
    run_with_different_schemes_and_models()
