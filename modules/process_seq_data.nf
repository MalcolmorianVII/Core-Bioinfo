nextflow.enable.dsl=2

workflow {
<<<<<<< HEAD

    mv_dir(params.minknw)
    basecalling(mv_dir.out)
    barcoding(basecalling.out)
    artic(barcoding.out) | view
    pangolin(artic.out) | view
}
=======
    run_ch = Channel.fromPath(params.run,type: 'dir')
    // artic_ch = Channel.fromPath(params.artic_covid_medaka_py)
    // min_ch = Channel.fromPath(params.minknow,type: 'dir')
    // mv_dir(min_ch,run_ch)
    // current_run = file(params.minknow)
    // min_runs  = file(params.run)
    // current_run.moveTo(min_runs)

    // basecalling(run_ch)
    // barcoding(basecalling.out,run_ch)
    // artic(run_ch)
    pangolin()
}

>>>>>>> 158c892500271f5f6716651cae4acead5b0dde0c

// process mv_dir {
//     tag "Move SARS-CoV2 run from Minknow directory"
//     publishDir "params.run/${BATCH}/fast5", mode: 'move'
//     input:
//     path minknw
//     path run_ch

<<<<<<< HEAD
process mv_dir {
    tag "Move SARS-CoV2 run from Minknow directory"
    
    input:
    path minknw

    output:
    path(mv)
=======
//     output:
//     path "${publishDir}"
>>>>>>> 158c892500271f5f6716651cae4acead5b0dde0c

//     script:
//     """
//     mv ${minknw} ${run_ch}
//     """

// }

process basecalling {
    label "guppy"
    debug true

    input:
<<<<<<< HEAD
    path(mv)
=======
    path run_ch
>>>>>>> 158c892500271f5f6716651cae4acead5b0dde0c
    
    output:
    path "${run_ch}/fastq"

    script:
    """
<<<<<<< HEAD
    guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i ${mv}/fast5 -s ${mv}/fastq
=======
    guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x 'auto' -i ${run_ch}/fast5 -s ${run_ch}/fastq
>>>>>>> 158c892500271f5f6716651cae4acead5b0dde0c
    """
}

process barcoding {
    label "guppy"
    debug true

    input:
<<<<<<< HEAD
    path(basecalling)

    output:
    path(barcoding)

    script:
    """
    guppy_barcoder -r -q 0 --disable_pings --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x 'auto' -i ${basecalling}/fastq -s ${basecalling}/fastq_pass
=======
    path fastq
    path run_ch

    output:
    val true,emit:barcodes
    path "${run_ch}/fastq_pass"

    script:
    """
    guppy_barcoder -r -q 0 --disable_pings --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x 'auto' -i ${fastq} -s ${run_ch}/fastq_pass
>>>>>>> 158c892500271f5f6716651cae4acead5b0dde0c
    """
}


process artic {
    debug true

    input:
<<<<<<< HEAD
    path barcoding 

    output:
    path artic 
=======
    // val ready
    path run_ch 
    // file artic_py

    output:
    path "${run_ch}/work",emit: work
>>>>>>> 158c892500271f5f6716651cae4acead5b0dde0c

    script:
    """
    mkdir -p ${run_ch}/work && cd ${run_ch}/work
    python ${artic_covid_medaka_py}
    """
}

process pangolin {
<<<<<<< HEAD
    tag "Assign lineages"
    
    input:
    path artic

    output:
    path pangolin
=======
    debug true
    publishDir "${work}",mode:"copy"
    // input:
    // path work

    output:
    path "${BATCH}.pangolin.lineage_report.csv"
>>>>>>> 158c892500271f5f6716651cae4acead5b0dde0c

    script:
    """
    pangolin --outfile ${BATCH}.pangolin.lineage_report.csv ${work}/${BATCH}.consensus.fasta
    """
}
