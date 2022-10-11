nextflow.enable.dsl=2

workflow {

    mv_dir(params.minknw)
    basecalling(mv_dir.out)
    barcoding(basecalling.out)
    artic(barcoding.out) | view
    pangolin(artic.out) | view
}


process mv_dir {
    tag "Move SARS-CoV2 run from Minknow directory"
    
    input:
    path minknw

    output:
    path(mv)

    script:
    """
    mv ${minknw} ${WORKDIR}
    chown -R bkutambe:bkutambe ${WORKDIR}
    """

}

process basecalling {
    label "guppy"

    input:
    path(mv)
    
    output:
    stdout 

    script:
    """
    guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i ${mv}/fast5 -s ${mv}/fastq
    """
}

process barcoding {
    label "guppy"

    input:
    path(basecalling)

    output:
    path(barcoding)

    script:
    """
    guppy_barcoder -r -q 0 --disable_pings --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x 'auto' -i ${basecalling}/fastq -s ${basecalling}/fastq_pass
    """
}


process artic {
    tag "Consensus sequence"

    input:
    path barcoding 

    output:
    path artic 

    script:
    """
    mkdir -p ${WORKDIR}/${BATCH}/work && cd ${WORKDIR}/${BATCH}/work
    python ${artic_py}
    """
}

process pangolin {
    tag "Assign lineages"
    
    input:
    path artic

    output:
    path pangolin

    script:
    """
    pangolin --outfile ${WORKDIR}/${BATCH}/work/${BATCH}.pangolin.lineage_report.csv ${WORKDIR}/${BATCH}/work/${BATCH}.consensus.fasta
    """
}
