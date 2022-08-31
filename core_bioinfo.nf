nextflow.enable.dsl=2
include { fromQuery } from 'plugin/nf-sqldb'
workflow {
    sam_ch = Channel.fromPath(params.add_samples,checkIfExists:true)
    // today() | view
    // todolist() | view
    query = '''select sample.sample_identifier, sample.day_received, sample.month_received, sample.year_received, pr.pcr_result as qech_pcr_result, pr.ct as original_ct, project_name, e.extraction_identifier, DATE(e.date_extracted) as date_extracted, ccp.pcr_identifier, DATE(ccp.date_pcred) as date_covid_confirmatory_pcred,
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
left join raw_sequencin g_batch rsb on rs.raw_sequencing_batch_id = rsb.id
left join read_set r on rs.id = r.raw_sequencing_id
left join artic_covid_result acr on r.id = acr.readset_id
where species = 'SARS-CoV-2'
  and pr.pcr_result like 'Positive%'
  and (project_name = any(array['ISARIC', 'COCOA', 'COCOSU', 'MARVELS']))
order by sample.year_received desc, sample.month_received desc, sample.day_received desc;'''
    ch = channel.fromQuery(query,db:'seq_db',emitColumns:true)
    myFile = file("${projectDir}/seq_query.csv")
    ch.subscribe {
        ArrayList row ->
            String line  = row.get(0)

            for (int i=1; i < row.size();i++) {
                String val = row.get(i)
                if ( val == null ) {
                    val = ""
                }
                line += ",${val}"
            }
            myFile.append("${line}\n")
    }
    
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

process query_db {

    input:
    val(data)

    output:
    stdout

    script:
    """
    echo ${data}
    """
}
