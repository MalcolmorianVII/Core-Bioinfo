nextflow.enable.dsl=2

workflow {
    sam_ch = Channel.fromPath(params.add_samples,checkIfExists:true)
    today() | view
    todolist() | view
    // modify_date(today.out,params.add_samples) | view
    // replace_date(today.out,modify_date.out,params.add_samples) | view
    
}

process today {
    tag "Get todays folder"
    
    output:
    stdout emit: day

    script:
    """
    echo \$(date +"%Y.%m.%d")
    """

}
process modify_date {
    tag "Modify add samples script"

    input:
    val day 
    path add_sam

    output:
    stdout emit:dy

    script:
    """
    egrep -wo -m 1 [0-9]{4}.[0-9]{2}.[0-9]{2} $params.add_samples
    """
     
}

process replace_date {
    tag "Modify add samples script"

    input:
    val day
    val dy 
    path add_sam

    output:
    stdout

    shell:
    """
    sed -i "s/$dy/$day/" $params.add_samples
    """
}

process todolist {
    tag "Run add_samples.sh"
    conda "/home/bkutambe/miniconda3/envs/seqbox"

    output:
    stdout 

    script:
    """
    bash ${params.add_samples}
    """
}


