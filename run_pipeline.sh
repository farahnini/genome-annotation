#!/bin/bash

# Example run script for genome annotation pipeline
# Modify the paths and parameters as needed

# Set variables
GENOME_FILE="/path/to/your/genome.fasta"
PROTEIN_FILE="/path/to/your/proteins.fasta"  # Optional
RNA_SEQ_FILE="/path/to/your/rnaseq.fastq"   # Optional
SPECIES_NAME="my_species"
OUTPUT_DIR="results"
PROFILE="singularity"  # or "docker", "cluster", "hpc"

# Basic run (genome only)
echo "Running basic genome annotation..."
nextflow run main.nf \
    --genome "${GENOME_FILE}" \
    --species "${SPECIES_NAME}" \
    --outdir "${OUTPUT_DIR}" \
    -profile "${PROFILE}" \
    -resume

# Run with protein evidence (uncomment to use)
# echo "Running genome annotation with protein evidence..."
# nextflow run main.nf \
#     --genome "${GENOME_FILE}" \
#     --proteins "${PROTEIN_FILE}" \
#     --species "${SPECIES_NAME}" \
#     --outdir "${OUTPUT_DIR}_with_proteins" \
#     -profile "${PROFILE}" \
#     -resume

# Run with both protein and RNA-seq evidence (uncomment to use)
# echo "Running genome annotation with protein and RNA-seq evidence..."
# nextflow run main.nf \
#     --genome "${GENOME_FILE}" \
#     --proteins "${PROTEIN_FILE}" \
#     --rna_seq "${RNA_SEQ_FILE}" \
#     --species "${SPECIES_NAME}" \
#     --outdir "${OUTPUT_DIR}_complete" \
#     -profile "${PROFILE}" \
#     -resume

echo "Pipeline execution completed!"
echo "Check the output directory: ${OUTPUT_DIR}"
echo "View the report at: ${OUTPUT_DIR}/pipeline_info/report.html"
