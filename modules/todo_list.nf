nextflow.enable.dsl=2

workflow {
    get_covid_cases_ch = Channel.fromPath(params.get_covid_cases_py,checkIfExists:true)
    seqbox_cmd_ch = Channel.fromPath(params.seqbox_cmd_py,checkIfExists:true)
    mk_today_dir() | view
    query_api(mk_today_dir.out,get_covid_cases_ch) | view
    add_sample_sources(query_api.out,seqbox_cmd_ch)
    add_samples(query_api.out,seqbox_cmd_ch,add_sample_sources.out)
    pcr_results(query_api.out,seqbox_cmd_ch,add_samples.out)
    get_todolist(pcr_results.out)
}

process mk_today_dir {
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

process add_sample_sources {
    label "seqbox"

    input:
    file covid_cases
    file seqbox_cmd_py

    output:
    val true

    script:
    """
    python3 ${seqbox_cmd_py} add_sample_sources -i ${covid_cases}
    """
}

process add_samples {
    label "seqbox"

    input:
    file covid_cases
    file seqbox_cmd_py
    val ready

    output:
    val true

    script:
    """
    python3 ${seqbox_cmd_py} add_samples -i ${covid_cases}
    """
}

process add_pcr_results {
    // debug true
    label "seqbox"

    input:
    file covid_cases
    file seqbox_cmd_py
    val ready

    output:
    val true

    script:
    """
    python3 ${seqbox_cmd_py} add_pcr_results -i ${covid_cases}
    """
}

process get_todolist {
    // debug true

    publishDir "${TODAY_DIR}",mode:"move"
    
    input:
    val ready

    output:
    path "${today}.seqbox_todolist.xlsx"

    script:
    """
    python3 ${projectDir}/query_db.py get_todolist -i ${today}.seqbox_todolist.xlsx
    """
}
