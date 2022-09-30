# Steps

* Clone the github repository
* Create the following env variables:
    ``` export SEQBOX_SCRIPTS="${HOME}/Documents/seqbox/seqbox/src/scripts"
        export COVID_SCRIPTS="${HOME}/Documents/seqbox/covid"
    ```
* Make the following changes in the nextflow.config file
## 1. In the **params scope** make sure you have correct:
    1. Paths of python scripts in covid and seqbox directories
    2. Paths of infiles,minknow directories and gpu2_seqbox_config file
## 2. For the env variables scope ensure that:
    1. WORKDIR points to the minion_runs directory e.g /home/bkutambe/data/minion_runs
    2. BATCH points to the current sequencing batch e.g 20210701_1420_MN33881_FAO36609_5c3b1ea9
    3. SEQTRACKER points to the seqtracker file (in a csv format).For now it set to be in the WORKDIR/BATCH director
    4. SEQ_SEQBOX_INPUT_OUTDIR points the iso-dated directory that has been made in the infiles directory which will contain the following files; raw_sequencing_batches.csv,readset_batches.csv and sequencing.csv e.g /home/bkutambe/data/seqbox/infiles/2022.09.22

## 3. In the **process scope**:
    seqbox,artic and pangolin processes should have conda variables point to the correct paths as reflected on the local system. These are paths that are displayed by conda env list e.g /home/bkutambe/miniconda3/envs/artic_new10

**Note:** The artic_covid_medaka.py has code to get the barcodes from the seqtracker rather than entering them manually.This script should be used when running the artic pipeline.The seqtracker should be in a csv format and have a an env variable refering to it in the nextflow.config file

## Running the pipeline

* Getting the todolist
`nextflow run main_pipeline.nf -entry GENERATE_TODO_LIST`

* Processing the sequencing data
`nextflow run main_pipeline.nf -entry PROCESS_SEQ_DATA`

* Combine the sequencing data with the sample information 
`nextflow run main_pipeline.nf -entry ADD_SEQ_DATA`
