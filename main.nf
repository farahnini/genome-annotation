#!/usr/bin/env nextflow

/*
 * Genome Annotation Pipeline
 * 
 * This pipeline performs genome annotation starting with:
 * 1. Sequence header cleaning
 * 2. RepeatModeler for de novo repeat identification
 * 3. RepeatMasker for repeat masking
 * 4. BRAKER3 for gene prediction
 */

nextflow.enable.dsl = 2

// Include modules
include { CLEAN_HEADERS } from './modules/clean_headers'
include { REPEATMODELER } from './modules/repeatmodeler'
include { REPEATMASKER } from './modules/repeatmasker'
include { BRAKER3 } from './modules/braker3'
include { BUSCO } from './modules/busco'

// Default parameters
params.genome = null
params.proteins = null
params.rna_seq = null
params.outdir = "results"
params.species = "unknown_species"
params.busco_db = "auto"  // auto, bacteria_odb10, eukaryota_odb10, etc.

// Validate required parameters
if (!params.genome) {
    error "Please provide a genome file with --genome"
}

log.info """
=========================================
Genome Annotation Pipeline
=========================================
Genome       : ${params.genome}
Proteins     : ${params.proteins ?: 'Not provided'}
RNA-seq data : ${params.rna_seq ?: 'Not provided'}
Species      : ${params.species}
BUSCO DB     : ${params.busco_db}
Output dir   : ${params.outdir}
=========================================
"""

/*
 * WORKFLOW
 */
workflow {
    // Input channels
    genome_ch = Channel.fromPath(params.genome, checkIfExists: true)
    
    // Optional protein channel
    proteins_ch = params.proteins ? 
        Channel.fromPath(params.proteins, checkIfExists: true) : 
        Channel.fromPath('NO_FILE')
    
    // Optional RNA-seq channel  
    rna_seq_ch = params.rna_seq ? 
        Channel.fromPath(params.rna_seq, checkIfExists: true) : 
        Channel.fromPath('NO_FILE')
    
    // Step 1: Clean sequence headers
    CLEAN_HEADERS(genome_ch)
    
    // Step 2: RepeatModeler for de novo repeat identification
    REPEATMODELER(CLEAN_HEADERS.out.cleaned_genome)
    
    // Step 3: RepeatMasker using RepeatModeler library
    REPEATMASKER(
        CLEAN_HEADERS.out.cleaned_genome,
        REPEATMODELER.out.repeat_library
    )
      // Step 4: BRAKER3 gene prediction
    BRAKER3(
        REPEATMASKER.out.masked_genome,
        proteins_ch,
        rna_seq_ch
    )
    
    // Step 5: BUSCO analysis on predicted proteins
    BUSCO(
        BRAKER3.out.protein_sequences,
        params.busco_db
    )
    
    // Emit final outputs for potential downstream processing
    emit:
    cleaned_genome = CLEAN_HEADERS.out.cleaned_genome
    repeat_library = REPEATMODELER.out.repeat_library
    masked_genome = REPEATMASKER.out.masked_genome
    gene_annotation = BRAKER3.out.gene_annotation
    protein_sequences = BRAKER3.out.protein_sequences
    busco_summary = BUSCO.out.summary
}


