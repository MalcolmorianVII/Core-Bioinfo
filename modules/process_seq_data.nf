nextflow.enable.dsl=2

workflow {
    run_ch = Channel.fromPath(params.run,type: 'dir')
    // mv_dir(min_ch,run_ch)
    // basecalling(run_ch)
    // barcoding(basecalling.out,run_ch)
    // artic(barcoding.our.barcodes,run_ch)
    // artic(run_ch)
    pangolin()
}


process mv_dir {
    tag "Move SARS-CoV2 run from Minknow directory"
    input:
    path run_ch

    output:
    stdout

    script:
    """
    mv ${params.minknow} ${run_ch}
    chown -R ${params.owner} ${run_ch}
    """

}

process basecalling {
    label "guppy"
    debug true

    input:
    path run_ch
    
    output:
    path "${run_ch}/fastq"

    script:
    """
    guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i ${run_ch}/fast5 -s ${run_ch}/fastq
    """
}

process barcoding {
    label "guppy"
    debug true

    input:
    path fastq
    path run_ch

    output:
    val true,emit:barcodes
    path "${run_ch}/fastq_pass"

    script:
    """
    guppy_barcoder -r -q 0 --disable_pings --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x 'auto' -i ${fastq} -s ${run_ch}/fastq_pass
    """
}


process artic {
    debug true

    input:
    // val ready
    path run_ch

    output:
    path "${run_ch}/work/${BATCH}.consensus.fasta",emit: consensus

    script:
    """
    mkdir -p ${run_ch}/work && cd ${run_ch}/work
    python ${artic_covid_medaka_py}
    """
}

process pangolin {
    debug true
    publishDir "${params.run}/work",mode:"move"

    // input:
    // path consensus

    output:
    path "${BATCH}.pangolin.lineage_report.csv"

    script:
    """
    pangolin --outfile ${BATCH}.pangolin.lineage_report.csv ${params.run}/work/${BATCH}.consensus.fasta
    """
}
