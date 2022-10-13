nextflow.enable.dsl=2
include  { mk_today} from './todo_list'
workflow {
    make_ch = Channel.fromPath(params.make_seqbox_input_py)
    run_ch = Channel.fromPath(params.run)
    mk_today()
    make_seq_seqbox_input(mk_today.out,SEQ_OUTPUT_DIR,make_ch)
    add_raw_sequencing_batches(params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_batch) | view
    add_readset_batches(add_raw_sequencing_batches.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.read_batch) | view
    add_extractions(add_readset_batches.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv) | view
    add_covid_confirmatory_pcrs(add_extractions.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv) | view
    add_tiling_pcrs(add_covid_confirmatory_pcrs.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv)| view
    add_readsets(add_tiling_pcrs.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv) | view
    add_readset_to_filestructure(add_readsets.out.params.file_inhandling_py,make_seq_seqbox_input.out.seq_csv) | view
    add_artic_consensus_to_filestructure(add_readset_to_filestructure.out,run_ch,params.file_inhandling_py) | view
    add_artic_covid_results(add_artic_consensus_to_filestructure.out,run_ch,params.seqbox_cmd_py) | view
    add_pangolin_results(add_artic_covid_results.out,run_ch,params.seqbox_cmd_py) | view
    get_sequence_run_info(add_pangolin_results.out) | view
}


process make_seq_seqbox_input {
    debug true

    input:
    val ready
    path "${SEQ_OUTPUT_DIR}"
    file inseq

    output:
    path "${SEQ_OUTPUT_DIR}/raw_sequencing_batches.csv",emit:seq_batch
    path "${SEQ_OUTPUT_DIR}/readset_batches.csv",emit:read_batch
    path "${SEQ_OUTPUT_DIR}/sequencing.csv",emit:seq_csv

    script:
    """
    python ${inseq} 
    """
}

process add_raw_sequencing_batches {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file seq_batch

    output:
    val true 

    script:
    """
    python ${seqbox_cmd_py} add_raw_sequencing_batches -i ${seq_batch}
    """
}

process add_readset_batches {
    label "seqbox"

    input:
    val ready
    path seqbox_cmd_py
    file read_batch

    output:
    val true

    script:
    """
    python ${seqbox_cmd_py} add_readset_batches -i ${read_batch}
    """
}

process add_extractions {
    label "seqbox"

    input:
    val ready
    path seqbox_cmd_py
    file seq_csv

    output:
    val true 

    script:
    """
    python ${seqbox_cmd_py} add_extractions -i ${seq_csv}
    """
}

process add_covid_confirmatory_pcrs {
    label "seqbox"

    input:
    val ready
    path seqbox_cmd_py
    file seq_csv

    output:
    val true

    script:
    """
    python ${seqbox_cmd_py} add_covid_confirmatory_pcrs -i ${seq_csv}
    """
}

process add_tiling_pcrs {
    label "seqbox"

    input:
    val ready
    path seqbox_cmd_py
    file seq_csv

    output:
    val true 

    script:
    """
    python ${seqbox_cmd_py} add_tiling_pcrs -i ${seq_csv}
    """
}

process add_readsets {
    label "seqbox"

    input:
    val ready
    path seqbox_cmd_py
    file seq_csv

    output:
    val true

    script:
    """
    python ${seqbox_cmd_py} add_readsets -i ${seq_csv} -s -n
    """
}

process add_readset_to_filestructure {
    label "seqbox"

    input:
    val ready
    path file_inhandling_py
    file seq_csv

    output:
    val true 

    script:
    """
    python ${file_inhandling_py} add_readset_to_filestructure -i ${seq_csv} -c ${gpu2_seqbox_config} -s -n
    """
}

process add_artic_consensus_to_filestructure {
    label "seqbox"
    
    input:
    val ready
    path run_ch
    path file_inhandling_py

    output:
    val true

    script:
    """
    python ${file_inhandling_py} add_artic_consensus_to_filestructure -b ${BATCH} -c ${gpu2_seqbox_config} -d ${run_ch}/work
    """
}

process add_artic_covid_results {
    label "seqbox"

    input:
    val ready
    path run_ch
    path seqbox_cmd_py

    output:
    val true 

    script:
    """
    python ${seqbox_cmd_py} add_artic_covid_results -i ${run_ch}/work/${BATCH}.qc.csv -b ${BATCH} -w ${WORKFLOW} -p ${PROFILE}
    """
}

process add_pangolin_results {
    label "seqbox"

    input:
    val ready
    path run_ch
    path seqbox_cmd_py

    output:
    val true 

    script:
    """
    python ${seqbox_cmd_py} add_pangolin_results -i ${run_ch}/work/${BATCH}.pangolin.lineage_report.csv -w ${WORKFLOW} -p ${PROFILE} -n
    """
}

process get_sequence_run_info {
    
    input:
    val ready

    output:
    val true

    script:
    """
    python ${projectDir}/query_db.py get_seq_run_info -i ${SEQ_SEQBOX_INPUT_OUTDIR}/${BATCH}.seqbox_export.xlsx
    """
}