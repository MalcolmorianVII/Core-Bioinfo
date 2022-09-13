nextflow.enable.dsl=2

workflow {

    // mv_dir(params.minknw,params.minruns)
    // basecaller(params.minruns,mv_dir.out)
    // barcoding(params.minruns,basecaller.out)
    artic(params.minruns,params.run) | view
    pangolin(params.minruns,params.run) | view
}


process mv_dir {
    tag "Move SARS-CoV2 run from Minknow directory"
    publishDir "${minruns}", mode: 'copy'
    input:
    path minknw
    path minruns

    output:
    stdout emit:mv

    script:
    """
    mv ${minknw} ${minruns}
    chown -R bkutambe:bkutambe ${minruns}
    """

}

process basecaller {
    tag "Performing Basecalling with Guppy"
    publishDir "${minruns}", mode: 'copy'

    input:
    path minruns
    val mv
    
    output:
    stdout emit:run

    script:
    """
    cd ${minruns}/${params.run}
    /home/phil/programs/ont-guppy/ont-guppy/bin/guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i fast5 -s fastq
    """
}

process barcoding {
    tag "Barcode the samples"
    publishDir "${minruns}", mode: 'copy'

    input:
    path minruns
    val(run)

    output:
    stdout

    script:
    """
    cd ${minruns}/${params.run}
    /home/phil/programs/ont-guppy/ont-guppy/bin/guppy_barcoder -r -q 0 --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x 'auto' -i fastq -s fastq_pass
    """
}


process artic {
    tag "Consensus sequence"
    // publishDir "${minruns}/${run}/work", mode: 'copy'
    conda "/home/bkutambe/miniconda3/envs/artic_new10"

    input:
    path minruns
    val run
    val barcoding 

    output:
    stdout emit:artic_out

    script:
    """
    mkdir -p ${minruns}/${run}/work && cd ${minruns}/${run}/work
    python ~/Documents/seqbox/covid/artic_covid_medaka.py
    """
}

process pangolin {
    tag "Running pangolin"
    conda "/home/bkutambe/miniconda3/envs/pangolin"
    
    input:
    path minruns
    val run
    val artic

    output:
    stdout

    script:
    """
    pangolin --outfile ${minruns}/${run}/work/${BATCH}.pangolin.lineage_report.csv ${minruns}/${run}/work/${BATCH}.consensus.fasta
    """
}