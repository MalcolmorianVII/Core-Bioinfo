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
    myFile = file("${projectDir}/seq_query.csv")
    today()
    mk_today(ch_infiles,today.out) | view
    query_api(ch_api,today.out,ch_infiles)
    // add_groups(query_api.out,params.seq_py)
    // add_projects(query_api.out,params.seq_py)
    sample_sources(query_api.out,params.seq_py)
    samples(query_api.out,params.seq_py)
    add_pcr_assay(query_api.out,params.seq_py)
    pcr_results(query_api.out,params.seq_py)

    // Query the db now
    ch_db.subscribe {
            ArrayList row ->
                String line  = row.get(0)

                for (int i = 1; i < row.size();i++) {
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
    echo -n \$(date +"%Y.%m.%d")
    """

}

process mk_today {
    tag "Make todays folder"
    
    input:
    path seq_dir
    val day
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
    path api
    val day
    val seq_dir

    output:
    file("${day}.sample_source_sample_pcrs.csv")

    script:
    """
    python ${api} > ${day}.sample_source_sample_pcrs.csv
    """
}

process add_groups {
    conda "/home/bkutambe/miniconda3/envs/seqbox"
    input:
    file covid_cases
    path seq

    output:
    stdout

    script:
    """
    python ${seq} add_groups -i /home/bkutambe/Documents/seqbox/seqbox/test/01.test_todo_list_query/groups.csv
    """
}
process add_projects {
    conda "/home/bkutambe/miniconda3/envs/seqbox"
    input:
    file covid_cases
    path seq

    output:
    stdout

    script:
    """
    python ${seq} add_projects -i /home/bkutambe/Documents/seqbox/seqbox/test/01.test_todo_list_query/projects.csv
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

    output:
    stdout

    script:
    """
    python ${seq} add_samples -i ${covid_cases}
    """
}

process add_pcr_assay {
    errorStrategy 'ignore'
    conda "/home/bkutambe/miniconda3/envs/seqbox"
    input:
    file covid_cases
    path seq

    output:
    stdout

    script:
    """
    python ${seq} add_pcr_assays -i /home/bkutambe/Documents/seqbox/seqbox/test/01.test_todo_list_query/pcr_assay.csv
    """
}
process pcr_results {
    // errorStrategy 'ignore'
    conda "/home/bkutambe/miniconda3/envs/seqbox"
    input:
    file covid_cases
    path seq

    output:
    stdout

    script:
    """
    python ${seq} add_pcr_results -i ${covid_cases}
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


// Processing the sequencing data

// process mv_dir {
//     tag "Move SARS-CoV2 run from Minknow directory"

//     input:
//     path minknw
//     path minruns

//     output:
//     stdout 

//     script:
//     """
//     mv ${minknw} ${minruns}
//     chown -R phil:phil ${minruns}
//     """

// }

// process basecaller {
//     tag "Performing Basecalling with Guppy"

//     input:
//     path minruns
    
//     output:
//     stdout

//     script:
//     """
//     cd ${minruns}
//     ~/programs/ont-guppy/ont-guppy/bin/guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i fast5 -s fastq
//     """
// }

// process barcoding {
//     tag "Barcode the samples"

//     output:
//     stdout

//     script:
//     """
//     ~/programs/ont-guppy/ont-guppy/bin/guppy_barcoder -r -q 0 --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i fastq -s fastq_pass
//     """
// }

// process medaka_py {
//     tag "Modify medaka script"

//     input:
//     path medaka

//     output:
//     stdout

//     script:
//     """
//     MOdify line 48 
//     ~/scripts/covid/artic_covid_medaka.py
//     """
// }

// process artic {
//     tag "Consensus sequence"
//     conda "artic_new10"
//     input:
//     path medaka

//     output:
//     stdout emit:artic_out

//     script:
//     """
//     mkdir work && cd work
//     python ~/scripts/covid/artic_covid_medaka.py
//     """
// }

// process pangolin {
//     tag "Running pangolin"

//     input:
//     file artic_out

//     output:
//     file pango_lineage

//     script:
//     """
//     pangolin --outfile 20220620_1115_MN33881_FAQ93003_a6746e26.pangolin.lineage_report.csv 20220620_1115_MN33881_FAQ93003_a6746e26.consensus.fasta
//     """
// }


