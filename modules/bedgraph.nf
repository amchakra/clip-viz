#!/usr/bin/env nextflow

// Specify DSL2
nextflow.enable.dsl=2

process BEDGRAPH {

    tag "${sample_id}"
    label 'process_medium'
    publishDir "${params.outdir}/bedgraph/raw", pattern: '*.raw.bedgraph.gz', mode: 'copy', overwrite: true
    publishDir "${params.outdir}/bedgraph/xpm", pattern: '*.xpm.bedgraph.gz', mode: 'copy', overwrite: true

    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bedtools:2.30.0--hc088bd4_0"
    } else {
        container "quay.io/biocontainers/bedtools:2.30.0--hc088bd4_0"
    }

    input:
        tuple val(sample_id), path(bed)

    output:
        tuple val(sample_id), path("${bed.simpleName}.raw.bedgraph.gz"), emit: rawbedgraph
        tuple val(sample_id), path("${bed.simpleName}.xpm.bedgraph.gz"), emit: normbedgraph


    script:
    """
    # Raw bedgraphs
    gunzip -c $bed | \
    awk '{OFS = "\t"}{if (\$6 == "+") {print \$1, \$2, \$3, \$5} else {print \$1, \$2, \$3, -\$5}}' | \
    gzip > ${bed.simpleName}.raw.bedgraph.gz
    
    # Normalised bedgraphs
    TOTAL=`gunzip -c $bed | awk 'BEGIN {total=0} {total=total+\$5} END {print total}'`

    echo \$TOTAL

    gunzip -c $bed | \
    awk -v total=\$TOTAL '{printf "%s\\t%i\\t%i\\t%s\\t%f\\t%s\\n", \$1, \$2, \$3, \$4, 1000000*\$5/total, \$6}' | \
    awk '{OFS = "\t"}{if (\$6 == "+") {print \$1, \$2, \$3, \$5} else {print \$1, \$2, \$3, -\$5}}' | \
    sort -k1,1 -k2,2n | \
    gzip > ${bed.simpleName}.xpm.bedgraph.gz
    """

}