nextflow.enable.dsl=2
include { fromQuery } from 'plugin/nf-sqldb'

workflow {
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
    ch_db = channel.fromQuery(query,db:'seq_db',emitColumns:true)
    ch_infiles = Channel.fromPath(params.infiles,checkIfExists:true)
    ch_api = Channel.fromPath(params.api,checkIfExists:true)
    myFile = file("/home/bkutambe/Documents/Core_Bioinfo/seq_query.csv")

    date = new Date().format('yyyy.MM.dd')
    mk_today(date,ch_infiles) | view
    query_api(date,ch_api,ch_infiles)
    sample_sources(query_api.out,params.seq_py) | view
    samples(query_api.out,params.seq_py,sample_sources.out) | view
    pcr_results(query_api.out,params.seq_py,samples.out) | view
    query_db(ch_db,myFile,pcr_results.out) | view

}

process mk_today {
    tag "Make todays folder"
    
    input:
    val day
    path seq_dir
    
    output:
    stdout

    script:
    """
    mkdir -p ${seq_dir}/${day}
    """

}

process query_api {
    publishDir "${seq_dir}/${day}", mode: 'copy'

    input:
    val day
    path api
    val seq_dir

    output:
    file("${day}.sample_source_sample_pcrs.csv")

    script:
    """
    python ${api} > ${day}.sample_source_sample_pcrs.csv
    """
}

process sample_sources {
    errorStrategy 'ignore'
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    file covid_cases
    path seq

    output:
    stdout

    script:
    """
    python ${seq} add_sample_sources -i ${covid_cases}
    """
}

process samples {
    errorStrategy 'ignore'
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    input:
    file covid_cases
    path seq
    val sample_source

    output:
    stdout

    script:
    """
    python ${seq} add_samples -i ${covid_cases}
    """
}


process pcr_results {
    // errorStrategy 'ignore'
    conda "/home/bkutambe/miniconda3/envs/seqbox"
    
    input:
    file covid_cases
    path seq
    val sample

    output:
    stdout

    script:
    """
    python ${seq} add_pcr_results -i ${covid_cases}
    """
}

process query_db {

    input:
    val data
    file myFile
    val pcr

    output:
    stdout

    exec:
    println data
    // String line = data.get(0)
    // for (int i = 1; i < data.size();i++) {
    //     String val = data.get(i)
    //     if ( val == null ) {
    //         val = ""
    //     }
    //     line += ",${val}"  
    // }
    // myFile.append("${line}\n")
}






