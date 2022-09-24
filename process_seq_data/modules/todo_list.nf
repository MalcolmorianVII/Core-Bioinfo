nextflow.enable.dsl=2

workflow {
    ch_api = Channel.fromPath(params.get_covid_cases_py,checkIfExists:true)
    date = new Date().format('yyyy.MM.dd')
    mk_today(date,params.infiles) | view
    query_api(date,ch_api,params.infiles) | view 
    sample_sources(query_api.out,params.seqbox_cmd_py) | view
    samples(query_api.out,params.seqbox_cmd_py,sample_sources.out) | view
    pcr_results(query_api.out,params.seqbox_cmd_py,samples.out) | view
    query_db(pcr_results.out,date,params.infiles) | view
}

process mk_today {
    tag "Make directory with todays date as name"
    
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
    val pcr_results
    val date
    val infiles

    output:
    stdout

    script:
    """
    python ${projectDir}/query_db.py get_todolist -i ${infiles}/${date}/${date}.seqbox_todolist.xlsx
    """
}
