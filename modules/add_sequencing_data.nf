nextflow.enable.dsl=2
include  { mk_today} from './todo_list'
workflow {
    mk_today()
    make_seq_seqbox_input(params.make_seqbox_input_py) | view
    add_raw_sequencing_batches(params.seqbox_cmd_py,make_seq_seqbox_input.out) | view
    add_readset_batches(params.seqbox_cmd_py,add_raw_sequencing_batches.out) | view
    add_extractions(params.seqbox_cmd_py,add_readset_batches.out) | view
    add_covid_confirmatory_pcrs(params.seqbox_cmd_py,add_extractions.out) | view
    add_tiling_pcrs(params.seqbox_cmd_py,add_covid_confirmatory_pcrs.out)| view
    add_readsets(params.seqbox_cmd_py,add_tiling_pcrs.out) | view
    add_readset_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config,add_readsets.out) | view
    add_artic_consensus_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config,add_readset_to_filestructure.out) | view
    add_artic_covid_results(params.seqbox_cmd_py,add_artic_consensus_to_filestructure.out) | view
    add_pangolin_results(params.seqbox_cmd_py,add_artic_covid_results.out) | view
    get_sequence_run_info(add_pangolin_results.out) | view
}


process make_seq_seqbox_input {

    input:
    file inseq

    output:
    path seq_data 

    script:
    """
    python ${inseq} 
    """
}

process add_raw_sequencing_batches {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file make_seq_seqbox_input

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_raw_sequencing_batches -i ${SEQ_SEQBOX_INPUT_OUTDIR}/raw_sequencing_batches.csv
    """
}

process add_readset_batches {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file add_raw_sequencing_batches

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_readset_batches -i ${SEQ_SEQBOX_INPUT_OUTDIR}/readset_batches.csv
    """
}

process add_extractions {
    label "seqbox"

    input:
    path seqbox_cmd_py
    file add_readset_batches

    output:
    stdout 

    script:
    """
    python ${seqbox_cmd_py} add_extractions -i ${SEQ_SEQBOX_INPUT_OUTDIR}/sequencing.csv
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