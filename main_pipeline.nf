nextflow.enable.dsl=2
include  { mk_today_dir;query_api;add_sample_sources;add_samples;add_pcr_results;get_todolist;archive_infiles } from './modules/todo_list'
include { mv_minknw_dir;basecalling;barcoding;artic;pangolin;move_to_archive } from './modules/process_seq_data'
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
    get_latest_seq_data } from './modules/add_sequencing_data'

if (params.mode == "test") {
    assert  DATABASE_URL.split("/")[-1].startsWith("test"),"You are running in test mode but  the database URL does not start with test"
    assert BATCH.endsWith("test"),"Test data should end with test"
} else{
    assert  ! DATABASE_URL.split("/")[-1].startsWith("test"),"Production database URL should not start with test"
    assert ! BATCH.endsWith("test"),"You are using test data in  production"
}   

run_dir_ch = Channel.fromPath(params.run_dir,type: 'dir')
seqbox_cmd_ch = Channel.fromPath(params.seqbox_cmd_py,checkIfExists:true)

workflow GENERATE_TODO_LIST {
    get_covid_cases_ch = Channel.fromPath(params.get_covid_cases_py,checkIfExists:true)
    seqbox_cmd_ch = Channel.fromPath(params.seqbox_cmd_py,checkIfExists:true)

    mk_today_dir()
    query_api(mk_today_dir.out,get_covid_cases_ch) 
    add_sample_sources(query_api.out,seqbox_cmd_ch)
    add_samples(query_api.out,seqbox_cmd_ch,add_sample_sources.out)
    add_pcr_results(query_api.out,seqbox_cmd_ch,add_samples.out)
    get_todolist(add_pcr_results.out)
    archive_infiles(get_todolist.out.done,FAST_INFILES)
}

workflow PROCESS_SEQ_DATA {
    mv_minknw_dir(params.minknow)
    basecalling(mv_minknw_dir.out.done,run_dir_ch)
    barcoding(basecalling.out.basecalled,run_dir_ch)
    artic(barcoding.out.barcodes,run_dir_ch)
    pangolin(artic.out)
    move_to_archive(pangolin.out.done,params.run_dir)
}

workflow ADD_SEQ_DATA {
    make_seq_output_ch = Channel.fromPath(params.make_seqbox_input_py)
    // run_dir_ch = Channel.fromPath(params.run_dir)
    // seqbox_cmd_ch = Channel.fromPath(params.seqbox_cmd_py,checkIfExists:true)
    inhandling_ch = Channel.fromPath(params.inhandling_py)

    mk_today_dir()
    make_seq_seqbox_input(mk_today_dir.out,FAST_INFILES,make_seq_output_ch)
    add_raw_sequencing_batches(seqbox_cmd_ch,make_seq_seqbox_input.out.seq_batch) 
    add_readset_batches(add_raw_sequencing_batches.out,seqbox_cmd_ch,make_seq_seqbox_input.out.read_batch) 
    add_extractions(add_readset_batches.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv) 
    add_covid_confirmatory_pcrs(add_extractions.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv) 
    add_tiling_pcrs(add_covid_confirmatory_pcrs.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv)
    add_readsets(add_tiling_pcrs.out,seqbox_cmd_ch,make_seq_seqbox_input.out.seq_csv) 
    
    add_readset_to_filestructure(add_readsets.out,inhandling_ch,make_seq_seqbox_input.out.seq_csv) 
    add_artic_consensus_to_filestructure(add_readset_to_filestructure.out,inhandling_ch) 
    add_artic_covid_results(add_artic_consensus_to_filestructure.out,seqbox_cmd_ch) 
    add_pangolin_results(add_artic_covid_results.out,seqbox_cmd_ch) 
    get_latest_seq_data(add_pangolin_results.out)
    archive_infiles(get_latest_seq_data.out,FAST_INFILES) 
}



