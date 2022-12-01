nextflow.enable.dsl=2

workflow {
    run_dir_ch = Channel.fromPath(params.run_dir,type: 'dir')
    mv_minknw_dir()
    basecalling(mv_minknw_dir.out,run_dir_ch)
    barcoding(basecalling.out,run_dir_ch)
    artic(barcoding.our.barcodes,run_dir_ch)
    pangolin(artic.out)
    move_to_archive(pangolin.out,params.run_dir)
}


process mv_minknw_dir {
    tag "Move SARS-CoV2 run from Minknow directory"

    publishDir params.run_dir,mode:"move"

    input:
    path source

    output:
    path "${BATCH}",optional: true
    val true,emit:done

    script:
    File minion_dir = new File("${params.run_dir}/${BATCH}")
    if (minion_dir.exists()) {
        """echo Directory already moved"""
    } else {
        """
        sudo chown -R ${params.owner} ${source}/${BATCH}
        sudo mv ${source}/${BATCH} ${BATCH}
        """
    }
    
}

process basecalling {
    label "guppy"
    // debug true

    input:
    val ready
    path run_dir_ch 
    
    output:
    val true,emit:basecalled
    path "${run_dir_ch}/${BATCH}/fastq*"

    script:
    File fastq = new File("${params.run_dir}/${BATCH}/fastq_pass")
    if (fastq.exists()) {
        """
        echo Skipping basecalling since basecalled data exists
        """
    } else {
        """
        guppy_basecaller -r -q 0 --disable_pings --compress_fastq -c dna_r9.4.1_450bps_sup.cfg -x "auto" -i ${run_dir_ch}/${BATCH}/fast5 -s ${run_dir_ch}/${BATCH}/fastq
        """
    }
}

process barcoding {
    label "guppy"
    // debug true

    input:
    val ready
    path run_dir_ch

    output:
    val true,emit:barcodes
    path "${run_dir_ch}/${BATCH}/fastq_pass"

    script:
    File fastqPass = new File("${params.run_dir}/${BATCH}/fastq_pass")
    if (fastqPass.exists()) {
        """
        echo Skipping barcoding since we have barcoded data
        """
    } else {
        """
        guppy_barcoder -r -q 0 --disable_pings --compress_fastq --require_barcodes_both_ends --barcode_kits EXP-NBD196 -x "auto" -i ${run_dir_ch}/${BATCH}/fastq -s ${run_dir_ch}/${BATCH}/fastq_pass
        """
    }
    
}


process artic {
    // debug true

    cpus 48
    
    input:
    val ready
    path run_dir_ch

    output:
    path "${run_dir_ch}/${BATCH}/work/${BATCH}.consensus.fasta",emit: consensus

    script:
    """
    mkdir -p ${run_dir_ch}/${BATCH}/work && cd ${run_dir_ch}/${BATCH}/work
    python ${params.artic_covid_medaka_py} ${params.run_dir}/${BATCH}
    """
}

process pangolin {
    // debug true
    publishDir "${params.run_dir}/${BATCH}/work",mode:"move"

    input:
    path consensus

    output:
    path "${BATCH}.pangolin.lineage_report.csv"
    val true,emit:done

    script:
    """
    pangolin --outfile ${BATCH}.pangolin.lineage_report.csv ${consensus}
    """
}

process move_to_archive{

    publishDir params.archive_runs,mode:"copy"

    input:
    val ready
    path source

    output:
    path "${BATCH}"
    val true,emit:archived 

    script:
    """
    mv ${source}/${BATCH} ${BATCH} 
    """
}

