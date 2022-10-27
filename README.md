# Steps

1. Clone the github repository
2. Create the following bash environment variables that point to:

    a. `export SEQBOX_SCRIPTS="/path/to/seqbox/src/scripts"` to point to the scripts directory within the installation of seqbox on your machine e.g.  where the scripts directory corresponds to scripts from [this](https://github.com/flashton2003/seqbox/tree/master/src/scripts) link.
    
    b. `export COVID_SCRIPTS="/path/to/covid"` to point to the location of the covid analysis scripts e.g.  where covid corresponds to [this](https://github.com/flashton2003/covid) github repo. For the current test_data `export COVID_SCRIPTS="covid_scripts"`

3. Make a copy of `nextflow.config` file, and make the following changes to the new version:

    a. In the `params` scope change the values of `minknow` to `path/to/test_data` & create `${HOME}/test_data/minion_runs` directory so  that the `run` variable should point to valid parent directory path.Change the  `owner` variable to the correct file ownerships on the local machine.

    b. In the `env` scope ensure:

        * BATCH points to the current sequencing batch e.g test_20210701_1420_MN33881_FAO36609_5c3b1ea9.

        * SEQTRACKER points to the seqtracker file (in a csv format). For the test data  download [this](https://www.dropbox.com/s/70i0xewtnqdqe2f/20210701_1420_MN33881_FAO36609_5c3b1ea9.csv?dl=0) seqtracker file into the path that `run` variable points to. 

        * SEQ_OUTPUT_DIR points the iso-dated directory that has been made in the infiles directory which will contain the following files; raw_sequencing_batches.csv,readset_batches.csv and sequencing.csv e.g /home/bkutambe/data/seqbox/infiles/2022.09.22

        * gpu2_seqbox_config should point to the right seqbox config.yaml file e.g. [this](https://github.com/flashton2003/seqbox_configs/blob/main/mlw_gpu1_seqbox_config.yaml) link.

    c. In the process scope `seqbox`, `artic` and `pangolin` processes should have conda variables point to the correct paths as reflected on the local system. These are paths that are displayed by `conda env list` e.g /home/bkutambe/miniconda3/envs/artic_new10


4. Modify the following variables in the artic_covid_medaka.py in the covid_scripts directory as follows:

    a. `root_dir=/path/to/minion_run_directory/on_local_machine`

    b. `primer_scheme_directory=/path/to/primer_scheme_directory`


## Setting up the test_database

1. Install postgres
2. Make a conda env according to `seqbox_conda_env.yaml` in the git repo
3. Fork the code from [this] (https://github.com/flashton2003/seqbox)
4. Modify your python path `export PYTHONPATH="${PYTHONPATH}:/Users/flashton/Dropbox/scripts/seqbox/src"`
5. Set the DATABASE_URL env variable to be the url of the database, e.g. `export DATABASE_URL=postgresql:///test_seqbox`
6. Run `test/test_no_web.py`
7. Run test/run_test_0*.sh


## Running the pipeline in test mode

* Getting the todolist
`nextflow run main_pipeline.nf -entry GENERATE_TODO_LIST -c test_nextflow.config --mode test` 

* Processing the sequencing data
`nextflow run main_pipeline.nf -entry PROCESS_SEQ_DATA -c test_nextflow.config --mode test`

* Combine the sequencing data with the sample information 
`nextflow run main_pipeline.nf -entry ADD_SEQ_DATA -c test_nextflow.config --mode test`

