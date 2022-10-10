// nextflow.enable.dsl=2

// workflow {

//     mv_dir(params.minknw)
//     basecalling(mv_dir.out)
//     barcoding(basecalling.out)
//     artic(barcoding.out) | view
//     pangolin(artic.out) | view
// }


process mv_dir {
    tag "Move SARS-CoV2 run from Minknow directory"
    
    input:
    path minknw

    output:
    stdout emit:mv

    script:
    """
    mv ${minknw} ${WORKDIR}
    chown -R bkutambe:bkutambe ${WORKDIR}
    """

}

process basecalling {
    tag "Performing Basecalling with Guppy"
    label "guppy"

    input:
    val mv
    
    output:
    stdout 

    script:
    """
    guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i /tmp/fast5 -s /tmp/fastq
    """
}

process barcoding {
    tag "Barcode the samples"
    label "guppy"

    input:
    val basecalling

    output:
    stdout

    script:
    """
    guppy_barcoder -r -q 0 --disable_pings --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x 'auto' -i /tmp/fastq -s /tmp/fastq_pass
    """
}


process artic {
    tag "Consensus sequence"

    input:
    val artic_py
    val barcoding 

    output:
    stdout 

    script:
    """
    mkdir -p ${WORKDIR}/${BATCH}/work && cd ${WORKDIR}/${BATCH}/work
    python ${artic_py}
    """
}

process pangolin {
    tag "Assign lineages"
    
    input:
    val artic

    output:
    stdout

    script:
    """
    pangolin --outfile ${WORKDIR}/${BATCH}/work/${BATCH}.pangolin.lineage_report.csv ${WORKDIR}/${BATCH}/work/${BATCH}.consensus.fasta
    """
}
