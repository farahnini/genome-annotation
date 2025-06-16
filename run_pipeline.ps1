# PowerShell run script for genome annotation pipeline
# Modify the paths and parameters as needed

# Set variables
$GENOME_FILE = "C:\path\to\your\genome.fasta"
$PROTEIN_FILE = "C:\path\to\your\proteins.fasta"  # Optional
$RNA_SEQ_FILE = "C:\path\to\your\rnaseq.fastq"   # Optional
$SPECIES_NAME = "my_species"
$OUTPUT_DIR = "results"
$PROFILE = "singularity"  # or "docker"

# Basic run (genome only)
Write-Host "Running basic genome annotation..."
nextflow run main.nf `
    --genome "$GENOME_FILE" `
    --species "$SPECIES_NAME" `
    --outdir "$OUTPUT_DIR" `
    -profile "$PROFILE" `
    -resume

# Run with protein evidence (uncomment to use)
<#
Write-Host "Running genome annotation with protein evidence..."
nextflow run main.nf `
    --genome "$GENOME_FILE" `
    --proteins "$PROTEIN_FILE" `
    --species "$SPECIES_NAME" `
    --outdir "${OUTPUT_DIR}_with_proteins" `
    -profile "$PROFILE" `
    -resume
#>

# Run with both protein and RNA-seq evidence (uncomment to use)
<#
Write-Host "Running genome annotation with protein and RNA-seq evidence..."
nextflow run main.nf `
    --genome "$GENOME_FILE" `
    --proteins "$PROTEIN_FILE" `
    --rna_seq "$RNA_SEQ_FILE" `
    --species "$SPECIES_NAME" `
    --outdir "${OUTPUT_DIR}_complete" `
    -profile "$PROFILE" `
    -resume
#>

Write-Host "Pipeline execution completed!"
Write-Host "Check the output directory: $OUTPUT_DIR"
Write-Host "View the report at: $OUTPUT_DIR/pipeline_info/report.html"
