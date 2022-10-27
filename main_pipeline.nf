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
    mk_today() | view
    query_api(mk_today.out,ch_api) | view 
    sample_sources(query_api.out,params.seqbox_cmd_py) | view
    samples(query_api.out,params.seqbox_cmd_py,sample_sources.out) | view
    pcr_results(query_api.out,params.seqbox_cmd_py,samples.out) | view
    query_db(pcr_results.out) | view
}

run_ch = Channel.fromPath(params.run,type: 'dir')

workflow PROCESS_SEQ_DATA {
    mv_dir()
    basecalling(mv_dir.out,run_ch)
    barcoding(basecalling.out,run_ch)
    artic(barcoding.out.barcodes,run_ch)
    pangolin(artic.out)
}

workflow ADD_SEQ_DATA {
    make_ch = Channel.fromPath(params.make_seqbox_input_py)
    mk_today()
    make_seq_seqbox_input(mk_today.out,SEQ_OUTPUT_DIR,make_ch)
    add_raw_sequencing_batches(params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_batch) | view
    add_readset_batches(add_raw_sequencing_batches.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.read_batch) | view
    add_extractions(add_readset_batches.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv) | view
    add_covid_confirmatory_pcrs(add_extractions.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv) | view
    add_tiling_pcrs(add_covid_confirmatory_pcrs.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv)| view
    add_readsets(add_tiling_pcrs.out,params.seqbox_cmd_py,make_seq_seqbox_input.out.seq_csv) | view
    add_readset_to_filestructure(add_readsets.out,params.file_inhandling_py,make_seq_seqbox_input.out.seq_csv) | view
    add_artic_consensus_to_filestructure(add_readset_to_filestructure.out,params.file_inhandling_py) | view
    add_artic_covid_results(add_artic_consensus_to_filestructure.out,run_ch,params.seqbox_cmd_py) | view
    add_pangolin_results(add_artic_covid_results.out,run_ch,params.seqbox_cmd_py) | view
    get_sequence_run_info(add_pangolin_results.out) | view
}



