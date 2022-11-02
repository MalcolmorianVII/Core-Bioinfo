nextflow.enable.dsl=2

workflow {
    get_covid_cases_ch = Channel.fromPath(params.get_covid_cases_py,checkIfExists:true)
    mk_today() | view
    query_api(mk_today.out,get_covid_cases_ch) | view 
    sample_sources(query_api.out,params.seqbox_cmd_py) | view
    samples(query_api.out,params.seqbox_cmd_py,sample_sources.out) | view
    pcr_results(query_api.out,params.seqbox_cmd_py,samples.out) | view
    query_db(pcr_results.out) | view
}

process mk_today {
    tag "Make directory with todays date as name"

    output:
    val true

    script:
    """
    mkdir -p ${TODAY_DIR}
    """

}

process query_api {
    publishDir "${TODAY_DIR}", mode: "copy"

    input:
    val ready
    file get_covid_cases_py

    output:
    file("${today}.sample_source_sample_pcrs.csv")

    script:
    """
    python3 ${get_covid_cases_py} > ${today}.sample_source_sample_pcrs.csv
    """
}

process sample_sources {
    label "seqbox"

    input:
    file covid_cases
    path seq

    output:
    stdout

    script:
    """
    python3 ${seq} add_sample_sources -i ${covid_cases}
    """
}

process samples {
    label "seqbox"

    input:
    file covid_cases
    path seq
    val sample_source

    output:
    stdout

    script:
    """
    python3 ${seq} add_samples -i ${covid_cases}
    """
}

process pcr_results {
    // debug true
    label "seqbox"

    input:
    file covid_cases
    path seq
    val sample

    output:
    stdout

    script:
    """
    python3 ${seq} add_pcr_results -i ${covid_cases}
    """
}

process query_db {
    // debug true

    publishDir "${TODAY_DIR}",mode:"move"
    
    input:
    val pcr_results

    output:
    path "${today}.seqbox_todolist.xlsx"

    script:
    """
    python3 ${projectDir}/query_db.py get_todolist -i ${today}.seqbox_todolist.xlsx
    """
}
