#!/bin/bash

# Create local test FASTA files for genome annotation pipeline testing
# This script generates synthetic test data without requiring internet downloads

OUTPUT_DIR="test"
GENOME_SIZE="small"  # small, medium, large

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --size)
            GENOME_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--output-dir DIR] [--size SIZE] [--help]"
            echo ""
            echo "Options:"
            echo "  --output-dir DIR    Output directory for test data (default: test)"
            echo "  --size SIZE         Genome size: small (~1KB), medium (~10KB), large (~100KB)"
            echo "  --help             Show this help message"
            echo ""
            echo "This script creates synthetic test FASTA files for pipeline testing"
            echo "without requiring internet downloads."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Creating local test FASTA files..."

# Create test directory
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo "Created directory: $OUTPUT_DIR"
fi

# Function to generate random DNA sequence
generate_dna_sequence() {
    local length=$1
    local sequence=""
    local bases=("A" "T" "G" "C")
    
    for ((i=0; i<length; i++)); do
        sequence+="${bases[$((RANDOM % 4))]}"
        if ((i % 60 == 59)); then
            sequence+="\n"
        fi
    done
    echo -e "$sequence"
}

# Function to generate random protein sequence
generate_protein_sequence() {
    local length=$1
    local sequence=""
    local amino_acids=("A" "R" "N" "D" "C" "Q" "E" "G" "H" "I" "L" "K" "M" "F" "P" "S" "T" "W" "Y" "V")
    
    for ((i=0; i<length; i++)); do
        sequence+="${amino_acids[$((RANDOM % 20))]}"
        if ((i % 60 == 59)); then
            sequence+="\n"
        fi
    done
    echo -e "$sequence"
}

# Set parameters based on genome size
case $GENOME_SIZE in
    "small")
        NUM_CONTIGS=3
        CONTIG_LENGTH=300
        NUM_PROTEINS=5
        PROTEIN_LENGTH=100
        echo "Generating small test genome (~1KB, 3 contigs)"
        ;;
    "medium")
        NUM_CONTIGS=10
        CONTIG_LENGTH=1000
        NUM_PROTEINS=20
        PROTEIN_LENGTH=150
        echo "Generating medium test genome (~10KB, 10 contigs)"
        ;;
    "large")
        NUM_CONTIGS=50
        CONTIG_LENGTH=2000
        NUM_PROTEINS=100
        PROTEIN_LENGTH=200
        echo "Generating large test genome (~100KB, 50 contigs)"
        ;;
    *)
        echo "Unknown size: $GENOME_SIZE. Using small."
        NUM_CONTIGS=3
        CONTIG_LENGTH=300
        NUM_PROTEINS=5
        PROTEIN_LENGTH=100
        ;;
esac

# Generate test genome
echo "Creating test genome with $NUM_CONTIGS contigs..."
{
    for ((i=1; i<=NUM_CONTIGS; i++)); do
        echo ">synthetic_contig_${i} length=${CONTIG_LENGTH}"
        generate_dna_sequence $CONTIG_LENGTH
    done
} > "$OUTPUT_DIR/test_genome.fasta"

echo "✓ Test genome created: $OUTPUT_DIR/test_genome.fasta"

# Generate test proteins
echo "Creating test proteins with $NUM_PROTEINS sequences..."
{
    for ((i=1; i<=NUM_PROTEINS; i++)); do
        echo ">synthetic_protein_${i} length=${PROTEIN_LENGTH}"
        generate_protein_sequence $PROTEIN_LENGTH
    done
} > "$OUTPUT_DIR/test_proteins.fasta"

echo "✓ Test proteins created: $OUTPUT_DIR/test_proteins.fasta"

# Create a synthetic RNA-seq file (small FASTQ for testing)
echo "Creating small synthetic RNA-seq file..."
{
    for ((i=1; i<=10; i++)); do
        echo "@synthetic_read_${i}"
        generate_dna_sequence 75 | tr -d '\n'
        echo ""
        echo "+"
        # Generate quality scores (all high quality for simplicity)
        for ((j=0; j<75; j++)); do
            echo -n "I"
        done
        echo ""
    done
} > "$OUTPUT_DIR/test_rnaseq.fastq"

echo "✓ Test RNA-seq file created: $OUTPUT_DIR/test_rnaseq.fastq"

# Show file information
echo ""
echo "Generated test files:"
echo "  Genome: $(du -h "$OUTPUT_DIR/test_genome.fasta" | cut -f1) ($(grep -c '^>' "$OUTPUT_DIR/test_genome.fasta") sequences)"
echo "  Proteins: $(du -h "$OUTPUT_DIR/test_proteins.fasta" | cut -f1) ($(grep -c '^>' "$OUTPUT_DIR/test_proteins.fasta") sequences)"
echo "  RNA-seq: $(du -h "$OUTPUT_DIR/test_rnaseq.fastq" | cut -f1) ($(grep -c '^@' "$OUTPUT_DIR/test_rnaseq.fastq") reads)"

# Create appropriate config based on size
if [ "$GENOME_SIZE" = "small" ]; then
    CONFIG_FILE="ultra_minimal.config"
    MEMORY_GENOME="1.GB"
    MEMORY_RM="2.GB"
    MEMORY_BRAKER="4.GB"
    TIME_RM="30.m"
    TIME_BRAKER="1.h"
else
    CONFIG_FILE="synthetic_test.config"
    MEMORY_GENOME="2.GB"
    MEMORY_RM="4.GB"
    MEMORY_BRAKER="8.GB"
    TIME_RM="2.h"
    TIME_BRAKER="4.h"
fi

cat > "$OUTPUT_DIR/$CONFIG_FILE" << EOF
// Configuration for synthetic test data ($GENOME_SIZE size)
params {
    genome = "test/test_genome.fasta"
    proteins = "test/test_proteins.fasta"
    rna_seq = "test/test_rnaseq.fastq"
    species = "synthetic_test_species"
    outdir = "synthetic_test_results"
}

process {
    executor = 'local'
    
    withName: CLEAN_HEADERS {
        cpus = 1
        memory = "1.GB"
        time = "10.m"
    }
    
    withName: REPEATMODELER {
        cpus = 2
        memory = "$MEMORY_RM"
        time = "$TIME_RM"
    }
    
    withName: REPEATMASKER {
        cpus = 2
        memory = "$MEMORY_RM"
        time = "30.m"
    }
    
    withName: BRAKER3 {
        cpus = 2
        memory = "$MEMORY_BRAKER"
        time = "$TIME_BRAKER"
    }
    
    withName: BUSCO {
        cpus = 1
        memory = "2.GB"
        time = "30.m"
    }
}
EOF

echo "✓ Created configuration: $OUTPUT_DIR/$CONFIG_FILE"

# Create test run script
cat > "$OUTPUT_DIR/run_synthetic_test.sh" << 'EOF'
#!/bin/bash
# Test run for synthetic genome annotation pipeline data

GENOME_FILE="test/test_genome.fasta"
PROTEIN_FILE="test/test_proteins.fasta"
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
EOF

chmod +x "$OUTPUT_DIR/run_synthetic_test.sh"
echo "✓ Created synthetic test script: $OUTPUT_DIR/run_synthetic_test.sh"

echo ""
echo "Synthetic test data creation complete!"
echo ""
echo "Quick test command:"
echo "  nextflow run main.nf --genome test/test_genome.fasta --species synthetic_test_species -c test/$CONFIG_FILE -profile singularity"
echo ""
echo "Or run the complete test:"
echo "  ./test/run_synthetic_test.sh"
