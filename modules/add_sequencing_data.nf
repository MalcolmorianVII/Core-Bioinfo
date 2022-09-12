workflow {
//   make_seq_seqbox_input(params.seq_in_py) | view
//   add_raw_sequencing_batches(params.seq_py) | view
//   add_readset_batches(params.seq_py) | view
//   add_extractions(params.seq_py) | view
//   add_covid_confirmatory_pcrs(params.seq_py) | view
//   add_tiling_pcrs(params.seq_py)| view
//   add_readsets(params.seq_py) | view
//   add_readset_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config) | view
//   add_artic_consensus_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config) | view
//   add_artic_covid_results(params.seq_py) | view
//   add_pangolin_results(params.seq_py) | view
}

process make_seq_seqbox_input {
    tag "Make seqbox input"

    input:
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
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${seq_py} add_raw_sequencing_batches -i ${SEQ_SEQBOX_INPUT_OUTDIR}/raw_sequencing_batches.csv
    """
}

process add_readset_batches {
    tag "Add_readset_batches"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${seq_py} add_readset_batches -i ${SEQ_SEQBOX_INPUT_OUTDIR}/readset_batches.csv
    """
}

process add_extractions {
    tag "add_extractions"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${seq_py} add_extractions -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv
    """
}

process add_covid_confirmatory_pcrs {
    tag "Add_covid_confirmatory_pcrs"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${seq_py} add_covid_confirmatory_pcrs -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv
    """
}

process add_tiling_pcrs {
    tag "Add_tiling_pcrs"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${seq_py} add_tiling_pcrs -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv
    """
}

process add_readsets {
    tag "Add_readsets"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${seq_py} add_readsets -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv -s -n
    """
}

process add_readset_to_filestructure {
    tag "Add_readset_to_filestructure"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path file_inhandling_py
    path gpu2_config
    val make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${file_inhandling_py} add_readset_to_filestructure -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv -c ${gpu2_config} -s -n
    """
}

process add_artic_consensus_to_filestructure {
    tag "Add_artic_consensus_to_filestructure"
    conda "/home/bkutambe/miniconda3/envs/seqbox"
    
    input:
    path file_inhandling_py
    path gpu2_config
    val add_readset_to_filestructure

    output:
    stdout 

    script:
    """
    python ${file_inhandling_py} add_artic_consensus_to_filestructure -b ${BATCH} -c ${gpu2_config} -d ${WORKDIR}/${BATCH}/work
    """
}

process add_artic_covid_results {
    tag "Add_artic_covid_results"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val add_artic_consensus_to_filestructure 

    output:
    stdout 

    script:
    """
    python ${seq_py} add_artic_covid_results -i ${WORKDIR}/${BATCH}/work/${BATCH}.qc.csv -b ${BATCH} -w ${WORKFLOW} -p ${PROFILE}
    """
}

process add_pangolin_results {
    tag "Add_pangolin_results"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    path seq_py
    val add_artic_covid_results

    output:
    stdout 

    script:
    """
    python ${seq_py} add_pangolin_results -i ${WORKDIR}/${BATCH}/work/${BATCH}.pangolin.lineage_report.csv -w ${WORKFLOW} -p ${PROFILE} -n
    """
}