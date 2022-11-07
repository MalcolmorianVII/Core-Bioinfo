nextflow.enable.dsl=2

workflow {
    run_dir_ch = Channel.fromPath(params.run_dir,type: 'dir')
    mv_minknw_dir()
    basecalling(mv_minknw_dir.out,run_dir_ch)
    barcoding(basecalling.out,run_dir_ch)
    artic(barcoding.our.barcodes,run_dir_ch)
    pangolin(artic.out)
}


process mv_minknw_dir {
    tag "Move SARS-CoV2 run from Minknow directory"

    output:
    val true

    script:
    """
    mv ${params.minknow} ${params.run_dir}
    chown -R ${params.owner} ${params.run_dir}
    """
}

process basecalling {
    label "guppy"
    // debug true

    input:
    val ready
    path run_dir_ch 
    
    output:
    path "${run_dir_ch}/fastq"

    script:
    """
    guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x "auto" -i ${run_dir_ch}/fast5 -s ${run_dir_ch}/fastq
    """
}

process barcoding {
    label "guppy"
    // debug true

    input:
    path fastq
    path run_dir_ch

    output:
    val true,emit:barcodes
    path "${run_dir_ch}/fastq_pass"

    script:
    """
    guppy_barcoder -r -q 0 --disable_pings --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x "auto" -i ${fastq} -s ${run_dir_ch}/fastq_pass
    """
}


process artic {
    // debug true

    input:
    val ready
    path run_dir_ch

    output:
    path "${run_dir_ch}/work/${BATCH}.consensus.fasta",emit: consensus

    script:
    """
    mkdir -p ${run_dir_ch}/work && cd ${run_dir_ch}/work
    python ${params.artic_covid_medaka_py} ${params.run_dir}
    """
}

process pangolin {
    // debug true
    publishDir "${params.run_dir}/work",mode:"move"

    input:
    path consensus

    output:
    path "${BATCH}.pangolin.lineage_report.csv"

    script:
    """
    pangolin --outfile ${BATCH}.pangolin.lineage_report.csv ${consensus}
    """
}
