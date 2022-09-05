nextflow.enable.nextflow.enable.dsl=2
include { } from "todo_list.nf"

workflow {
  make_seq_seqbox_input()
//   add_raw_sequencing_batches()
//   add_readset_batches()
//   add_extractions()
//   add_covid_confirmatory_pcrs()
//   add_tiling_pcrs()
//   add_readsets()
//   add_readset_to_filestructure()
//   add_artic_consensus_to_filestructure()
//   add_artic_covid_results()
//   add_pangolin_results()
}

process make_seq_seqbox_input {
    tag "Make seqbox input"

    input:
    val infiles
    val inseq

    output:
    stdout 

    script:
    """
    python ${inseq} 
    """
}

process add_raw_sequencing_batches {
    tag "Add_raw_sequencing_batches"

    input:
    val csvs
    path seq_py

    output:
    stdout 

    script:
    """
    python ${seq_py} add_raw_sequencing_batches -i ${csvs}/raw_sequencing_batches.csv
    """
}

process add_readset_batches {
    tag "Add_readset_batches"

    input:
    val csvs
    path seq_py

    output:
    stdout 

    script:
    """
    python ${seq_py} add_readset_batches -i ${csvs}/readset_batches.csv
    """
}

process add_extractions {
    tag "add_extractions"

    input:
    val csvs
    path seq_py

    output:
    stdout 

    script:
    """
    python ${seq_py} add_extractions -i ${csvs}/sequencing.csv
    """
}

process add_covid_confirmatory_pcrs {
    tag "Add_covid_confirmatory_pcrs"

    input:
    val csvs
    path seq_py

    output:
    stdout 

    script:
    """
    python ${seq_py} add_covid_confirmatory_pcrs -i ${csvs}/sequencing.csv
    """
}

process add_tiling_pcrs {
    tag "Add_tiling_pcrs"

    input:
    val csvs
    path seq_py

    output:
    stdout 

    script:
    """
    python ${seq_py} add_tiling_pcrs -i ${csvs}/sequencing.csv
    """
}

process add_readsets {
    tag "Add_readsets"

    input:
    val csvs
    path seq_py

    output:
    stdout 

    script:
    """
    python ${seq_py} add_readsets -i ${csvs}/sequencing.csv
    """
}

process add_readset_to_filestructure {
    tag "Add_readset_to_filestructure"

    input:
    val csvs
    path file_inhandling_py
    path gpu2_config

    output:
    stdout 

    script:
    """
    python ${file_inhandling_py} add_readset_to_filestructure -i ${csvs}/sequencing.csv -c ${gpu2_config} -s -n
    """
}

process add_artic_consensus_to_filestructure {
    tag "Add_artic_consensus_to_filestructure"

    input:
    val csvs
    path file_inhandling_py
    path gpu2_config

    output:
    stdout 

    script:
    """
    python ${file_inhandling_py} add_artic_consensus_to_filestructure -b ${BATCH} -c ${gpu2_config} -d ${WORKDIR}
    """
}

process add_artic_covid_results {
    tag "Add_artic_covid_results"

    input:
    val csvs

    output:
    stdout 

    script:
    """
    python ${seq_py} add_artic_covid_results -i ${WORKDIR}/${BATCH}.qc.csv -b ${BATCH} -w ${WORKFLOW} -p ${PROFILE}
    """
}

process add_pangolin_results {
    tag "Add_pangolin_results"

    input:
    val csvs
    path seq_py

    output:
    stdout 

    script:
    """
    python ${seq_py} add_pangolin_results -i ${WORKDIR}/${BATCH}.pangolin.lineage_report.csv -w ${WORKFLOW} -p ${PROFILE} -n
    """
}