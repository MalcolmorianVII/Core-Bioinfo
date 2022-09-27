# Steps

* Getting the todolist
`nextflow run covid_pipeline.nf -entry GENERATE_TODO_LIST`

* Processing the sequencing data
`nextflow run covid_pipeline.nf -entry PROCESS_SEQ_DATA`

* Combine the sequencing data with the sample information 
`nextflow run covid_pipeline.nf -entry ADD_SEQ_DATA`
