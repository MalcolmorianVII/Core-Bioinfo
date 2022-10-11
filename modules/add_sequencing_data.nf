nextflow.enable.dsl=2
include  { mk_today} from './todo_list'
workflow {
    make_ch = Channel.fromPath(params.make_seqbox_input_py)
    mk_today()
    make_seq_seqbox_input(mk_today.out,make_ch)
    add_raw_sequencing_batches(params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_batch) | view
    add_readset_batches(add_raw_sequencing_batches.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.read_batch) | view
    add_extractions(add_readset_batches.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv) | view
    // add_covid_confirmatory_pcrs(params.seqbox_cmd_py,add_extractions.out) | view
    // add_tiling_pcrs(params.seqbox_cmd_py,add_covid_confirmatory_pcrs.out)| view
    // add_readsets(params.seqbox_cmd_py,add_tiling_pcrs.out) | view
    // add_readset_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config,add_readsets.out) | view
    // add_artic_consensus_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config,add_readset_to_filestructure.out) | view
    // add_artic_covid_results(params.seqbox_cmd_py,add_artic_consensus_to_filestructure.out) | view
    // add_pangolin_results(params.seqbox_cmd_py,add_artic_covid_results.out) | view
    // get_sequence_run_info(add_pangolin_results.out) | view
}


process make_seq_seqbox_input {
    debug true
    publishDir "${SEQ_OUTPUT_DIR}",mode:"copy"

    input:
    val ready
    file inseq

    output:
    path "raw_sequencing_batches.csv",emit:seq_batch
    path "readset_batches.csv",emit:read_batch
    path "sequencing.csv",emit:seq_csv

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
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_extractions -i ${seq_csv}
    """
}

process add_covid_confirmatory_pcrs {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file add_extractions

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_covid_confirmatory_pcrs -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv
    """
}

process add_tiling_pcrs {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file add_covid_confirmatory_pcrs

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_tiling_pcrs -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv
    """
}

process add_readsets {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file add_tiling_pcrs

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_readsets -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv -s -n
    """
}

process add_readset_to_filestructure {
    label "seqbox"

    input:
    path file_inhandling_py
    path gpu2_config
    file add_readsets

    output:
    stdout 

    script:
    """
    python ${file_inhandling_py} add_readset_to_filestructure -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv -c ${gpu2_config} -s -n
    """
}

process add_artic_consensus_to_filestructure {
    label "seqbox"
    
    input:
    path file_inhandling_py
    path gpu2_config
    file add_readset_to_filestructure

    output:
    stdout 

    script:
    """
    python ${file_inhandling_py} add_artic_consensus_to_filestructure -b ${BATCH} -c ${gpu2_config} -d ${WORKDIR}/${BATCH}/work
    """
}

process add_artic_covid_results {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file add_artic_consensus_to_filestructure 

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_artic_covid_results -i ${WORKDIR}/${BATCH}/work/${BATCH}.qc.csv -b ${BATCH} -w ${WORKFLOW} -p ${PROFILE}
    """
}

process add_pangolin_results {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file add_artic_covid_results

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_pangolin_results -i ${WORKDIR}/${BATCH}/work/${BATCH}.pangolin.lineage_report.csv -w ${WORKFLOW} -p ${PROFILE} -n
    """
}

process get_sequence_run_info {
    
    input:
    file add_pangolin_results

    output:
    stdout

    script:
    """
    python ${projectDir}/query_db.py get_seq_run_info -i ${SEQ_SEQBOX_INPUT_OUTDIR}/${BATCH}.seqbox_export.xlsx
    """
}