#!/usr/bin/env nextflow

/*
========================================================================================
                                    amchakra/clip-viz
========================================================================================
Pipeline to create normalised IGV tracks for CLIP data
https://github.com/amchakra/clip-viz
----------------------------------------------------------------------------------------
*/

// Define DSL2
nextflow.enable.dsl=2

// Inputs
ch_fai = Channel.fromPath(params.fai, checkIfExists: true)
ch_strands = Channel.of('reverse', 'forward')

// Processes
include { METADATA } from './modules/metadata.nf'
include { BEDGRAPH } from './modules/bedgraph.nf'
include { BEDTOBAM; SORTINDEXBAM; BIGWIG } from './modules/bigwig.nf'

// Log
def summary = [:]
summary['Output directory'] = params.outdir
summary['Trace directory'] = params.tracedir
if(workflow.repository) summary['Pipeline repository'] = workflow.repository
if(workflow.revision) summary['Pipeline revision'] = workflow.revision
summary['Pipeline directory'] = workflow.projectDir
summary['Working dir'] = workflow.workDir
summary['Run name'] = workflow.runName
summary['Profile'] = workflow.profile
if(workflow.container) summary['Container'] = workflow.container
log.info summary.collect { k,v -> "${k.padRight(25)}: $v" }.join("\n")
log.info "-\033[2m---------------------------------------------------------------\033[0m-"

def settings = [:]
settings['Input'] = params.input
settings['FAI'] = params.fai
settings['Bin size'] = params.bin_size
settings['Smooth length'] = params.smooth_length
log.info settings.collect { k,v -> "${k.padRight(25)}: $v" }.join("\n")
log.info "-----------------------------------------------------------------"

// Pipeline
workflow {

    METADATA(params.input)
    
    // Bedgraphs
    BEDGRAPH(METADATA.out)

    // Bigwigs
    BEDTOBAM(METADATA.out, ch_fai.collect())
    SORTINDEXBAM(BEDTOBAM.out.bam)
    BIGWIG(METADATA.out, SORTINDEXBAM.out.bam, ch_strands)

}