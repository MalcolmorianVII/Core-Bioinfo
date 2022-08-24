nextflow.enable.dsl=2

workflow {
    settings_ch = Channel.from(params.db,params.pypath)
    gpu1_inf_ch = Channel.from(params.gpu1_inf)
    add_sam = Channel.from(params.add_samples)

    runs(settings_ch)
    today(gpu1_inf_ch)
    modify_date(day,add_sam)
}

process runs {
    tag "Export settings & activate seqbox"
    conda "seqbox"

    input:
    tuple val(db),val(pypath)

    output:
    path("*")

    script:
    """
    export DATABASE_URL= ${db}
    export PYTHONPATH = ${pypath}
    """ 

}

process today {
    tag "Get todays folder"
    
    input:
    val gpu1_inf_ch

    output:
    val td_dir emit: day

    script:
    """
    echo ${gpu1_inf_ch}/$( date +"%Y.%m.%d" )
    """

}

process modify_date {
    tag "Modify add samples script"

    input:
    val day 
    path add_sam

    output:
    file add_samples

    script:
    """
    sed -E "s/([0-9]{4}.[0-9]{2}.[0-9]{2})/${day}/" ${add_sam}
    """
     
}

process todolist {
    tag "Run add_samples.sh"

    input:
    path add_sam

    output:
    path('*')

    script:
    """
    bash ${add_sam}
    """
}


