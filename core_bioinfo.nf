nextflow.enable.dsl=2

workflow {
    runs() | view
    
}

process runs {
    tag "Export settings"

    output:
    stdout

    script:
    """
    printenv | grep $DATABASE_URL
    """ 
}


// process today {
//     tag "Get todays folder"
    
//     input:
//     val gpu1_inf_ch

//     output:
//     val td_dir emit: day

//     script:
//     """
//     echo ${gpu1_inf_ch}/$( date +"%Y.%m.%d" )
//     """

// }

// process modify_date {
//     tag "Modify add samples script"

//     input:
//     val day 
//     path add_sam

//     output:
//     file add_samples

//     script:
//     """
//     sed -E "s/([0-9]{4}.[0-9]{2}.[0-9]{2})/${day}/" ${add_sam}
//     """
     
// }

// process todolist {
//     tag "Run add_samples.sh"
//     conda "seqbox"

//     input:
//     path add_sam

//     output:
//     path('*')

//     script:
//     """
//     bash ${add_sam}
//     """
// }


