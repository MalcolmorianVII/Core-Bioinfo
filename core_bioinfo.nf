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


