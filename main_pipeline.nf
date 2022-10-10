nextflow.enable.dsl=2
include  { mk_today;query_api;sample_sources;samples;pcr_results;query_db } from './modules/todo_list'
include { mv_dir;basecalling;barcoding;artic;pangolin } from './modules/process_seq_data'
include {
    make_seq_seqbox_input;
    add_raw_sequencing_batches;
    add_readset_batches;
    add_extractions;
    add_covid_confirmatory_pcrs;
    add_tiling_pcrs;
    add_readsets;
    add_readset_to_filestructure;
    add_artic_consensus_to_filestructure;
    add_artic_covid_results;
    add_pangolin_results;
    get_sequence_run_info } from './modules/add_sequencing_data'

if (params.mode == "test") {
    assert  DATABASE_URL.split("/")[-1].startsWith("test"),"You are running in test mode but  the database URL does not start with test"
    assert BATCH.startsWith("test"),"Test data should start with test"
} else{
    assert  ! DATABASE_URL.split("/")[-1].startsWith("test"),"Production database URL should not start with test"
    assert ! BATCH.startsWith("test"),"You are using test data in the production"
}   

workflow GENERATE_TODO_LIST {
    ch_api = Channel.fromPath(params.get_covid_cases_py,checkIfExists:true)
    date = new Date().format('yyyy.MM.dd')
    mk_today(date,params.infiles) | view
    query_api(date,ch_api,params.infiles) | view 
    sample_sources(query_api.out,params.seqbox_cmd_py) | view
    samples(query_api.out,params.seqbox_cmd_py,sample_sources.out) | view
    pcr_results(query_api.out,params.seqbox_cmd_py,samples.out) | view
    query_db(pcr_results.out,date,params.infiles) | view
}

workflow PROCESS_SEQ_DATA {
    mv_dir(params.minknow)
    basecalling(mv_dir.out)
    barcoding(basecalling.out)
    artic(params.artic_covid_medaka_py,barcoding.out) | view
    pangolin(artic.out) | view
}

workflow ADD_SEQ_DATA {
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



