# Steps

1. Clone the github repository
2. Create the following bash environment variables that point to:

    a. `export SEQBOX_SCRIPTS="/path/to/seqbox/src/scripts"` to point to the scripts directory within the installation of seqbox on your machine e.g.  where the scripts directory corresponds to scripts from [this](https://github.com/flashton2003/seqbox/tree/master/src/scripts) link.
    
    b. `export COVID_SCRIPTS="/path/to/covid"` to point to the location of the covid analysis scripts e.g.  where covid corresponds to [this](https://github.com/flashton2003/covid) github repo.

3. Make a copy of `nextflow.config` file, and make the following changes to the new version:

    a. In the `params` scope change the values of `minknow` to reflect the latest run directory & `gpu2_seqbox_config` to the right name of the seqbox `config.yaml` file e.g. [this](https://github.com/flashton2003/seqbox_configs/blob/main/mlw_gpu1_seqbox_config.yaml) link.

    b. In the `env` scope ensure:

        * BATCH points to the current sequencing batch e.g 20210701_1420_MN33881_FAO36609_5c3b1ea9.

        * SEQTRACKER points to the seqtracker file (in a csv format). For now it set to be in the WORKDIR/BATCH director

        * SEQ_SEQBOX_INPUT_OUTDIR points the iso-dated directory that has been made in the infiles directory which will contain the following files; raw_sequencing_batches.csv,readset_batches.csv and sequencing.csv e.g /home/bkutambe/data/seqbox/infiles/2022.09.22

    c. In the process scope `seqbox`, `artic` and `pangolin` processes should have conda variables point to the correct paths as reflected on the local system. These are paths that are displayed by conda env list e.g /home/bkutambe/miniconda3/envs/artic_new10

**Note:** The artic_covid_medaka.py has code to get the barcodes from the seqtracker rather than entering them manually. This script should be used when running the artic pipeline.The seqtracker should be in a csv format and have an env variable refering to it in the nextflow.config file.


## Running the pipeline

* Getting the todolist
`nextflow run main_pipeline.nf -entry GENERATE_TODO_LIST`

* Processing the sequencing data
`nextflow run main_pipeline.nf -entry PROCESS_SEQ_DATA`

* Combine the sequencing data with the sample information 
`nextflow run main_pipeline.nf -entry ADD_SEQ_DATA`


NB:To run the pipeline using **test data** specify the run mode as test.Make sure the test data starts with test keyword and the DATABASE_URL points to the test database.

`nextflow run main_pipeline.nf -entry PROCESS_SEQ_DATA --mode test`
