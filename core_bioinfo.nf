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

<<<<<<< HEAD
    script:
    """
    echo ${data}
    """
}
=======
// Processing the sequencing data

process mv_dir {
    tag "Move SARS-CoV2 run from Minknow directory"

    input:
    path minknw
    path minruns

    output:
    stdout 

    script:
    """
    mv ${minknw} ${minruns}
    chown -R phil:phil ${minruns}
    """

}

process basecaller {
    tag "Performing Basecalling with Guppy"

    input:
    path minruns
    
    output:
    stdout

    script:
    """
    cd ${minruns}
    ~/programs/ont-guppy/ont-guppy/bin/guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i fast5 -s fastq
    """
}

process barcoding {
    tag "Barcode the samples"

    output:
    stdout

    script:
    """
    ~/programs/ont-guppy/ont-guppy/bin/guppy_barcoder -r -q 0 --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i fastq -s fastq_pass
    """
}

process medaka_py {
    tag "Modify medaka script"

    input:
    path medaka

    output:
    stdout

    script:
    """
    MOdify line 48 
    ~/scripts/covid/artic_covid_medaka.py
    """
}

process artic {
    tag "Consensus sequence"
    conda "artic_new10"
    input:
    path medaka

    output:
    stdout emit:artic_out

    script:
    """
    mkdir work && cd work
    python ~/scripts/covid/artic_covid_medaka.py
    """
}

process pangolin {
    tag "Running pangolin"

    input:
    file artic_out

    output:
    file pango_lineage

    script:
    """
    pangolin --outfile 20220620_1115_MN33881_FAQ93003_a6746e26.pangolin.lineage_report.csv 20220620_1115_MN33881_FAQ93003_a6746e26.consensus.fasta
    """
}


>>>>>>> ffcbf7b51ad36f865817ff5a0c5587bd129ee7be
