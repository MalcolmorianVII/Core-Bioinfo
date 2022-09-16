nextflow.enable.dsl=2
include { fromQuery } from 'plugin/nf-sqldb'
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
    add_pangolin_results } from './modules/add_sequencing_data'

workflow GENERATE_TODO_LIST {
    query = '''
                select sample.sample_identifier, sample.day_received, sample.month_received, sample.year_received, pr.pcr_result as qech_pcr_result, pr.ct as original_ct, project_name, e.extraction_identifier, DATE(e.date_extracted) as date_extracted, ccp.pcr_identifier, DATE(ccp.date_pcred) as date_covid_confirmatory_pcred,
                   ccp.ct as covid_confirmation_pcr_ct, tp.pcr_identifier as tiling_pcr_identifier, DATE(tp.date_pcred) as date_tiling_pcrer, rsb.name as read_set_batch_name, r.readset_identifier, acr.pct_covered_bases
                from sample
                left join sample_source ss on sample.sample_source_id = ss.id
                left join sample_source_project ssp on ss.id = ssp.sample_source_id
                left join project on ssp.project_id = project.id
                left join pcr_result pr on sample.id = pr.sample_id
                left join extraction e on sample.id = e.sample_id
                left join covid_confirmatory_pcr ccp on e.id = ccp.extraction_id
                left join raw_sequencing rs on e.id = rs.extraction_id
                left join tiling_pcr tp on rs.tiling_pcr_id = tp.id
                left join raw_sequencing_batch rsb on rs.raw_sequencing_batch_id = rsb.id
                left join read_set r on rs.id = r.raw_sequencing_id
                left join artic_covid_result acr on r.id = acr.readset_id
                where species = 'SARS-CoV-2'
                  and pr.pcr_result like 'Positive%'
                  and (project_name = any(array['ISARIC', 'COCOA', 'COCOSU', 'MARVELS']))
                order by sample.year_received desc, sample.month_received desc, sample.day_received desc;
            '''
    date = new Date().format('yyyy.MM.dd')
    ch_api = Channel.fromPath(params.api,checkIfExists:true)
    ch_db = channel.fromQuery(query,db:'seq_db',emitColumns:true)
    myFile = file("/home/bkutambe/Documents/Core_Bioinfo/seq_query.csv")

    mk_today(date,params.infiles) | view
    query_api(date,ch_api,params.infiles)
    sample_sources(query_api.out,params.seq_py) | view
    samples(query_api.out,params.seq_py,sample_sources.out) | view
    pcr_results(query_api.out,params.seq_py,samples.out) | view
    query_db(ch_db,myFile,pcr_results.out) | view
}

workflow PROCESS_SEQ_DATA {
    mv_dir(params.minknw)
    basecalling(mv_dir.out)
    barcoding(basecalling.out)
    artic(barcoding.out) | view
    pangolin(artic.out) | view
}

workflow ADD_SEQ_DATA {
    make_seq_seqbox_input(params.seq_in_py) | view
    add_raw_sequencing_batches(params.seq_py,make_seq_seqbox_input.out) | view
    add_readset_batches(params.seq_py,make_seq_seqbox_input.out) | view
    add_extractions(params.seq_py,make_seq_seqbox_input.out) | view
    add_covid_confirmatory_pcrs(params.seq_py,make_seq_seqbox_input.out) | view
    add_tiling_pcrs(params.seq_py,make_seq_seqbox_input.out)| view
    add_readsets(params.seq_py,make_seq_seqbox_input.out) | view
    add_readset_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config,make_seq_seqbox_input.out) | view
    add_artic_consensus_to_filestructure(params.file_inhandling_py,params.gpu2_seqbox_config,add_readset_to_filestructure.out) | view
    add_artic_covid_results(params.seq_py,add_artic_consensus_to_filestructure.out) | view
    add_pangolin_results(params.seq_py,add_artic_covid_results.out) | view
}

workflow {
    if (params.choice == 1) {
        GENERATE_TODO_LIST()
    } else if (params.choice == 2) {
        PROCESS_SEQ_DATA()
    }else if (params.choice == 3) {
        ADD_SEQ_DATA()
    } else {
        println "Error:Invalid choice"
    }
}

