#!/bin/bash
# Test run for synthetic genome annotation pipeline data

GENOME_FILE="test/test_genome.fna"
PROTEIN_FILE="test/test_proteins.faa"
RNA_SEQ_FILE="test/test_rnaseq.fastq"
SPECIES_NAME="synthetic_test_species"
OUTPUT_DIR="synthetic_test_results"

echo "Running pipeline validation with synthetic data..."
nextflow run validate.nf --genome "$GENOME_FILE"

echo "Running synthetic test annotation pipeline..."
nextflow run main.nf \
    --genome "$GENOME_FILE" \
    --proteins "$PROTEIN_FILE" \
    --rna_seq "$RNA_SEQ_FILE" \
    --species "$SPECIES_NAME" \
    --outdir "$OUTPUT_DIR" \
    -profile singularity \
    -c test/synthetic_test.config \
    -resume

echo "Synthetic test completed! Check results in: $OUTPUT_DIR"
