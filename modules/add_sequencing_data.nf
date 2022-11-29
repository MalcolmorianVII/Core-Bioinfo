nextflow.enable.dsl=2
include  { mk_today_dir} from './todo_list'
workflow {
    make_seq_output_ch = Channel.fromPath(params.make_seqbox_input_py)
    run_dir_ch = Channel.fromPath(params.run_dir)
    seqbox_cmd_ch = Channel.fromPath(params.seqbox_cmd_py,checkIfExists:true)
    inhandling_ch = Channel.fromPath(params.inhandling_py)

    mk_today_dir()
    make_seq_seqbox_input(mk_today_dir.out,TODAY_DIR,make_seq_output_ch)
    add_raw_sequencing_batches(seqbox_cmd_ch,make_seq_seqbox_input.out.seq_batch) 
    add_readset_batches(add_raw_sequencing_batches.out,seqbox_cmd_ch,make_seq_seqbox_input.out.read_batch) 
    add_extractions(add_readset_batches.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv) 
    add_covid_confirmatory_pcrs(add_extractions.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv) 
    add_tiling_pcrs(add_covid_confirmatory_pcrs.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv)
    add_readsets(add_tiling_pcrs.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv) 
    
    add_readset_to_filestructure(add_readsets.out,inhandling_ch,make_seq_seqbox_input.out.seq_csv) 
    add_artic_consensus_to_filestructure(add_readset_to_filestructure.out,inhandling_ch) 
    add_artic_covid_results(add_artic_consensus_to_filestructure.out,run_dir_ch,seqbox_cmd_ch) 
    add_pangolin_results(add_artic_covid_results.out,run_dir_ch,seqbox_cmd_ch) 
    get_latest_seq_data(add_pangolin_results.out) 
}

process move_to_archive{

    publishDir params.archive,mode:"move"

    input:
    path source

    output:
    path "${BATCH}"
    val true 

    script:
    """
    mv ${source} ${BATCH} 
    """
}

process make_seq_seqbox_input {
    debug true

    input:
    val ready
    path TODAY_DIR
    file make_seq_out_py

    output:
    path "${TODAY_DIR}/raw_sequencing_batches.csv",emit:seq_batch
    path "${TODAY_DIR}/readset_batches.csv",emit:read_batch
    path "${TODAY_DIR}/sequencing.csv",emit:seq_csv

    script:
    """
    python ${make_seq_out_py} ${params.archive_runs}/${BATCH}
    """
}

process add_raw_sequencing_batches {
    label "seqbox"

    input:
    file seqbox_cmd_py
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
    file seqbox_cmd_py
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
    file seqbox_cmd_py
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
    file seqbox_cmd_py
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
    file seqbox_cmd_py
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
    file seqbox_cmd_py
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
    file inhandling_py
    file seq_csv

    output:
    val true 

    script:
    """
    python ${inhandling_py} add_readset_to_filestructure -i ${seq_csv} -c ${gpu2_seqbox_config} -s -n
    """
}

process add_artic_consensus_to_filestructure {
    label "seqbox"
    
    input:
    val ready
    file file_inhandling_py

    output:
    val true

    script:
    """
    python ${file_inhandling_py} add_artic_consensus_to_filestructure -b ${BATCH} -c ${gpu2_seqbox_config} -d ${params.run_dir}/work
    """
}

process add_artic_covid_results {
    label "seqbox"

    input:
    val ready
    path run_dir_ch
    file seqbox_cmd_py

    output:
    val true 

    script:
    """
    python ${seqbox_cmd_py} add_artic_covid_results -i ${run_dir_ch}/work/${BATCH}.qc.csv -b ${BATCH} -w ${WORKFLOW} -p ${PROFILE}
    """
}

process add_pangolin_results {
    label "seqbox"

    input:
    val ready
    path run_dir_ch
    file seqbox_cmd_py

    output:
    val true 

    script:
    """
    python ${seqbox_cmd_py} add_pangolin_results -i ${run_dir_ch}/work/${BATCH}.pangolin.lineage_report.csv -w ${WORKFLOW} -p ${PROFILE} -n
    """
}

process get_latest_seq_data {
    
    input:
    val ready

    output:
    val true

    script:
    """
    python ${projectDir}/query_db.py get_latest_seq_data -i ${TODAY_DIR}/${BATCH}.seqbox_export.xlsx
    """
}