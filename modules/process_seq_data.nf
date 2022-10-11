nextflow.enable.dsl=2

workflow {
    run_ch = Channel.fromPath(params.run,type: 'dir')
    // min_ch = Channel.fromPath(params.minknow,type: 'dir')
    // mv_dir(min_ch,run_ch)
    // current_run = file(params.minknow)
    // min_runs  = file(params.run)
    // current_run.moveTo(min_runs)

    basecalling(run_ch)
    barcoding(basecalling.out,run_ch)
    artic(barcoding.out.barcodes,run_ch,params.artic_covid_medaka_py)
    pangolin(artic.out)
}


// process mv_dir {
//     tag "Move SARS-CoV2 run from Minknow directory"
//     publishDir "params.run/${BATCH}/fast5", mode: 'move'
//     input:
//     path minknw
//     path run_ch

//     output:
//     path "${publishDir}"

//     script:
//     """
//     mv ${minknw} ${run_ch}
//     """

// }

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
    val ready
    path run_ch 
    path artic_py

    output:
    path "${run_ch}/work",emit: work

    script:
    """
    mkdir -p ${run_ch}/work && cd ${run_ch}/work
    python ${artic_py}
    """
}

process pangolin {
    debug true

    input:
    path work

    output:
    path "${work}/${BATCH}.consensus.fasta",emit:consensus

    script:
    """
    pangolin --outfile ${work}/${BATCH}.pangolin.lineage_report.csv ${consensus}
    """
}
