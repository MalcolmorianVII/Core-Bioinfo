# Steps

* Clone the github repository
* Change the following settings in the nextflow.config file
* * Change the path of scripts  covid scripts to reflect the ones on local computer
* Change the path of infiles,minknow directories and gpu2_seqbox_config file 
* Change the following env variables:
* WORKDIR to point to the minion_runs directory
* SEQTRACKER to point to the seqtracker file (in a csv format).For now it set to be in the WORKDIR
* BATCH to point to the current sequencing batch
* SEQ_SEQBOX_INPUT_OUTDIR for the dated directory that has been made in the infiles directory which will contain the 


In the process scope we need to change the following:
seqbox,artic and pangolin processes should have conda variables point to the correct paths as reflected on the local system. These are paths that are displayed after by conda env list.Note this should be a complete path not just a name of the conda env otherwise nextflow will start downloading the packages


* Getting the todolist
`nextflow run covid_pipeline.nf -entry GENERATE_TODO_LIST`

* Processing the sequencing data
`nextflow run covid_pipeline.nf -entry PROCESS_SEQ_DATA`

* Combine the sequencing data with the sample information 
`nextflow run covid_pipeline.nf -entry ADD_SEQ_DATA`
