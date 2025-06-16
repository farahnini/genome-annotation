#!/bin/bash

# Linux setup script for genome annotation pipeline test data
# This script downloads test data for pipeline validation

OUTPUT_DIR="test"
SKIP_DOWNLOAD=false
SMALL_TEST=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --skip-download)
            SKIP_DOWNLOAD=true
            shift
            ;;
        --small-test)
            SMALL_TEST=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--output-dir DIR] [--skip-download] [--small-test] [--help]"
            echo ""
            echo "Options:"
            echo "  --output-dir DIR    Output directory for test data (default: test)"
            echo "  --skip-download     Skip downloading test data"
            echo "  --small-test        Download only a small test FASTA (~1MB) for quick testing"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Setting up test data for genome annotation pipeline..."

# Create test directory
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo "Created directory: $OUTPUT_DIR"
fi

if [ "$SKIP_DOWNLOAD" = false ]; then
    if [ "$SMALL_TEST" = true ]; then
        echo "Downloading small test FASTA for quick testing..."
        
        # Create a small test genome (Lambda phage - ~48kb)
        LAMBDA_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/840/245/GCF_000840245.1_ViralProj14204/GCF_000840245.1_ViralProj14204_genomic.fna.gz"
        LAMBDA_FILE="$OUTPUT_DIR/lambda_genome.fna.gz"
        
        echo "Downloading Lambda phage genome (~48kb) for quick testing..."
        if wget -O "$LAMBDA_FILE" "$LAMBDA_URL" 2>/dev/null; then
            gunzip "$LAMBDA_FILE"
            mv "$OUTPUT_DIR/GCF_000840245.1_ViralProj14204_genomic.fna" "$OUTPUT_DIR/test_genome.fasta"
            echo "✓ Small test genome downloaded (Lambda phage)"
        else
            echo "❌ Failed to download Lambda phage genome, creating minimal test FASTA..."
            # Create a minimal test FASTA if download fails
            cat > "$OUTPUT_DIR/test_genome.fasta" << 'FASTA_EOF'
>test_sequence_1
ATGCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATC
GATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATC
GATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATC
GATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATC
GATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATC
>test_sequence_2
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA
FASTA_EOF
            echo "✓ Created minimal test FASTA file"
        fi
        
        # Create a small protein file for testing
        cat > "$OUTPUT_DIR/test_proteins.fasta" << 'PROTEIN_EOF'
>test_protein_1
MKAIFVLKGASDERIVPIGFAIAERVTGKHNLLQSLKDTPAVLSKVLATVCVDWVSKG
APAVSAILEMKGRTLAAEYGLLAPTTLGKGGQTSPNKVAFGQIAKVEGYDIDVGNHRV
EAAARKAGLNLRVPEHTYAALEHKSSVITGAYMNPKLLLPSLSDYINQFHDTVPVNIP
>test_protein_2
MKQQLLKLVSKAYQEALAKFGGTQWDPVEALLKLLEAGGRAVKDLVRLPLEVNSAGKA
KAALWGKGQNTRRAVFLSRLPPQPALAVTLQEALALLGTSFLNSRTFTVATVGETAAE
DQGNMRVVLADFTTAGEPGRFNPRHYWLSKGSRHHSAWTPLLALLELNDQLYRVLRTQ
PROTEIN_EOF
        echo "✓ Created small test protein file"
        
    else
        echo "Downloading test genome (E. coli K-12 MG1655)..."
        
        # Download E. coli genome from NCBI
        GENOME_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/825/GCF_000005825.2_ASM582v2/GCF_000005825.2_ASM582v2_genomic.fna.gz"
        GENOME_FILE="$OUTPUT_DIR/test_genome.fna.gz"
        
        if wget -O "$GENOME_FILE" "$GENOME_URL"; then
            # Extract the file
            gunzip "$GENOME_FILE"
            mv "$OUTPUT_DIR/GCF_000005825.2_ASM582v2_genomic.fna" "$OUTPUT_DIR/test_genome.fasta"
            echo "✓ Test genome downloaded and extracted"
        else
            echo "❌ Failed to download test genome"
            echo "You can manually download it from: $GENOME_URL"
        fi
        
        # Download protein sequences for testing
        echo "Downloading test proteins..."
        PROTEIN_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/825/GCF_000005825.2_ASM582v2/GCF_000005825.2_ASM582v2_protein.faa.gz"
        PROTEIN_FILE="$OUTPUT_DIR/test_proteins.faa.gz"
        
        if wget -O "$PROTEIN_FILE" "$PROTEIN_URL"; then
            # Extract the file
            gunzip "$PROTEIN_FILE"
            mv "$OUTPUT_DIR/GCF_000005825.2_ASM582v2_protein.faa" "$OUTPUT_DIR/test_proteins.fasta"
            echo "✓ Test proteins downloaded and extracted"
        else
            echo "❌ Failed to download test proteins"
            echo "You can manually download it from: $PROTEIN_URL"
        fi
    fi
fi

# Create a test run script
cat > "$OUTPUT_DIR/run_test.sh" << 'EOF'
#!/bin/bash
# Test run for genome annotation pipeline
# This uses the downloaded E. coli genome for testing

GENOME_FILE="test/test_genome.fasta"
PROTEIN_FILE="test/test_proteins.fasta"
SPECIES_NAME="Escherichia_coli"
OUTPUT_DIR="test_results"

echo "Running pipeline validation..."
nextflow run validate.nf --genome "$GENOME_FILE"

echo "Running test annotation pipeline..."
nextflow run main.nf \
    --genome "$GENOME_FILE" \
    --proteins "$PROTEIN_FILE" \
    --species "$SPECIES_NAME" \
    --outdir "$OUTPUT_DIR" \
    -profile singularity \
    -c test/test_data.config \
    -resume

echo "Test completed! Check results in: $OUTPUT_DIR"
EOF

chmod +x "$OUTPUT_DIR/run_test.sh"
echo "✓ Created test run script: $OUTPUT_DIR/run_test.sh"

# Create a minimal test configuration
cat > "$OUTPUT_DIR/minimal.config" << 'EOF'
// Minimal test configuration for small genomes
params {
    genome = "test/test_genome.fasta"
    proteins = "test/test_proteins.fasta"
    species = "Escherichia_coli"
    outdir = "test_results"
}

process {
    executor = 'local'
    
    withName: CLEAN_HEADERS {
        cpus = 1
        memory = "2.GB"
        time = "30.m"
    }
    
    withName: REPEATMODELER {
        cpus = 2
        memory = "4.GB"
        time = "2.h"
    }
    
    withName: REPEATMASKER {
        cpus = 2
        memory = "4.GB"
        time = "1.h"
    }
    
    withName: BRAKER3 {
        cpus = 2
        memory = "8.GB"
        time = "4.h"
    }
    
    withName: BUSCO {
        cpus = 2
        memory = "4.GB"
        time = "1.h"
    }
}
EOF

echo "✓ Created minimal test config: $OUTPUT_DIR/minimal.config"

# Create ultra-minimal config for very small tests
cat > "$OUTPUT_DIR/ultra_minimal.config" << 'EOF'
// Ultra-minimal configuration for very small genomes (like Lambda phage)
params {
    genome = "test/test_genome.fasta"
    proteins = "test/test_proteins.fasta"
    species = "test_virus"
    outdir = "test_results_minimal"
}

process {
    executor = 'local'
    
    withName: CLEAN_HEADERS {
        cpus = 1
        memory = "1.GB"
        time = "10.m"
    }
    
    withName: REPEATMODELER {
        cpus = 1
        memory = "2.GB"
        time = "30.m"
    }
    
    withName: REPEATMASKER {
        cpus = 1
        memory = "2.GB"
        time = "15.m"
    }
    
    withName: BRAKER3 {
        cpus = 1
        memory = "4.GB"
        time = "1.h"
    }
    
    withName: BUSCO {
        cpus = 1
        memory = "2.GB"
        time = "30.m"
    }
}
EOF

echo "✓ Created ultra-minimal test config: $OUTPUT_DIR/ultra_minimal.config"

# Create quick validation script
cat > "$OUTPUT_DIR/validate_setup.sh" << 'EOF'
#!/bin/bash
# Quick validation script to check if everything is set up correctly

echo "=== Genome Annotation Pipeline Setup Validation ==="
echo ""

# Check if we're in the right directory
if [ ! -f "main.nf" ]; then
    echo "❌ main.nf not found. Please run this from the pipeline directory."
    exit 1
fi

# Check Nextflow
if command -v nextflow &> /dev/null; then
    echo "✓ Nextflow found: $(nextflow -version | head -n1)"
else
    echo "❌ Nextflow not found"
fi

# Check container runtime
if command -v singularity &> /dev/null; then
    echo "✓ Singularity found: $(singularity --version)"
elif command -v docker &> /dev/null; then
    echo "✓ Docker found: $(docker --version)"
else
    echo "❌ No container runtime found (need Singularity or Docker)"
fi

# Check test files
if [ -f "test/test_genome.fasta" ]; then
    echo "✓ Test genome file exists"
    file_size=$(du -h test/test_genome.fasta | cut -f1)
    seq_count=$(grep -c '^>' test/test_genome.fasta 2>/dev/null || echo "0")
    echo "  Size: $file_size"
    echo "  Sequences: $seq_count"
    
    # Check if it's a small test file
    file_size_bytes=$(stat -c%s test/test_genome.fasta 2>/dev/null || stat -f%z test/test_genome.fasta 2>/dev/null || echo "0")
    if [ "$file_size_bytes" -lt 100000 ]; then
        echo "  ⚡ Small test file detected - use ultra_minimal.config"
    fi
else
    echo "❌ Test genome file not found"
fi

if [ -f "test/test_proteins.fasta" ]; then
    echo "✓ Test protein file exists"
    file_size=$(du -h test/test_proteins.fasta | cut -f1)
    seq_count=$(grep -c '^>' test/test_proteins.fasta 2>/dev/null || echo "0")
    echo "  Size: $file_size"
    echo "  Sequences: $seq_count"
else
    echo "❌ Test protein file not found"
fi

# Check available resources
echo ""
echo "System Resources:"
echo "  CPU cores: $(nproc)"
echo "  Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "  Disk space: $(df -h . | awk 'NR==2 {print $4}') available"

echo ""
echo "Setup validation complete!"
EOF

chmod +x "$OUTPUT_DIR/validate_setup.sh"
echo "✓ Created validation script: $OUTPUT_DIR/validate_setup.sh"

echo ""
echo "Test setup complete!"
echo ""
echo "Test options available:"
if [ -f "$OUTPUT_DIR/test_genome.fasta" ]; then
    file_size_bytes=$(stat -c%s "$OUTPUT_DIR/test_genome.fasta" 2>/dev/null || stat -f%z "$OUTPUT_DIR/test_genome.fasta" 2>/dev/null || echo "0")
    if [ "$file_size_bytes" -lt 100000 ]; then
        echo "📦 Small test data detected (< 100KB)"
        echo "  Quick test: nextflow run main.nf --genome test/test_genome.fasta --species test_virus -c test/ultra_minimal.config -profile singularity"
    else
        echo "📦 Full test data available"
        echo "  Standard test: ./$OUTPUT_DIR/run_test.sh"
    fi
fi
echo ""
echo "Next steps:"
echo "1. Validate setup: ./$OUTPUT_DIR/validate_setup.sh"
echo "2. Run test: ./$OUTPUT_DIR/run_test.sh"
echo "3. Quick validation: nextflow run validate.nf --genome $OUTPUT_DIR/test_genome.fasta"
