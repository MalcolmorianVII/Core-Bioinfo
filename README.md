# Steps

* Getting the todolist
Use the following command:
NXF_VER="22.05.0-edge" nextflow run covid_pipeline.nf --choice 1

* Processing the sequencing data
Use the following command:
NXF_VER="22.05.0-edge" nextflow run covid_pipeline.nf --choice 2

* Combine the sequencing data with the sample information 
Use the following command:
NXF_VER="22.05.0-edge" nextflow run covid_pipeline.nf --choice 3

**Note**
NXF_VER="22.08.1-edge" nextflow run todo_list.nf causing a conda bug
**Plugin** id 'nf-sqldb@0.5.0'

**Successful run**
test with NXF_VER="22.05.0-edge" nextflow run todo_list.nf
plugins {
    id 'nf-sqldb@0.4.1'
}