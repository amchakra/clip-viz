#!/usr/bin/env nextflow

// Specify DSL2
nextflow.enable.dsl=2

process BEDTOBAM {

    tag "${sample_id}"
    label 'process_medium'

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bedtools:2.30.0--hc088bd4_0"
    } else {
        container "quay.io/biocontainers/bedtools:2.30.0--hc088bd4_0"
    }

    input:
        tuple val(sample_id), path(bed)
        path(fai)

    output:
        tuple val(sample_id), path("*.bam"), emit: bam

    script:
    """
    gunzip -c $bed | \
    awk '{for(i=1; i<=\$5; i++) print}' | \
    bedtools bedtobam -i /dev/stdin -g $fai \
    > ${sample_id}.unsorted.bam
    """

}

process SORTINDEXBAM {

    tag "${sample_id}"
    label 'process_medium'

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/samtools:1.14--hb421002_0"
    } else {
        container "quay.io/biocontainers/samtools:1.14--hb421002_0"
    }

    input:
        tuple val(sample_id), path(bam)

    output:
        tuple val(sample_id), path("*.bam"), path("*.bai"), emit: bam

    script:
    """
    samtools sort -@ $task.cpus -o ${sample_id}.bam $bam
    samtools index -@ $task.cpus ${sample_id}.bam
    """

}

process BIGWIG {

    tag "${sample_id}"
    label 'process_medium'
    publishDir "${params.outdir}/bigwig", mode: 'copy', overwrite: true

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/deeptools:3.5.1--py_0"
    } else {
        container "quay.io/biocontainers/deeptools:3.5.1--py_0"
    }

    input:
        tuple val(sample_id), path(bed)
        tuple val(sample_id), path(bam), path(bai)
        each strand

    output:
        tuple val(sample_id), path("*.bigwig"), emit: bigwig

    script:
    def bin_size = params.bin_size
    def smooth_length = params.smooth_length
    def strand_name = (strand == 'reverse') ? 'F' : 'R'
    
    """
    SCALE_FACTOR=`gunzip -c $bed | awk 'BEGIN {total=0} {total+=\$5} END {print 1e6/total}'`

    bamCoverage -p $task.cpus \
    --binSize $bin_size \
    --smoothLength $smooth_length \
    --scaleFactor \$SCALE_FACTOR \
    --filterRNAstrand $strand \
    -b $bam \
    -o ${sample_id}.xpm.${bin_size}bin_${smooth_length}smooth_${strand_name}.bigwig
    """

}