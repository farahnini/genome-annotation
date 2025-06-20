#!/bin/bash

# Validation script for genome annotation pipeline setup
# Checks for required tools and test data

echo "=== Genome Annotation Pipeline Setup Validation ==="
echo

# Check for Nextflow
if command -v nextflow >/dev/null 2>&1; then
    echo "✓ Nextflow found: $(nextflow -version 2>&1 | head -n1)"
else
    echo "❌ Nextflow not found"
    echo "  Install with: curl -s https://get.nextflow.io | bash && sudo mv nextflow /usr/local/bin/"
fi

# Check for Singularity
if command -v singularity >/dev/null 2>&1; then
    echo "✓ Singularity found: $(singularity --version)"
else
    echo "❌ Singularity not found"
    echo "  Install with: sudo apt install -y singularity-ce"
fi

# Check for test files (using actual extensions .fna and .faa)
# Look for files in the test directory (same directory as this script)
SCRIPT_DIR="$(dirname "$0")"

if [ -f "$SCRIPT_DIR/test_genome.fna" ]; then
    echo "✓ Test genome file found: test_genome.fna"
    file_size=$(du -h "$SCRIPT_DIR/test_genome.fna" | cut -f1)
    seq_count=$(grep -c '^>' "$SCRIPT_DIR/test_genome.fna" 2>/dev/null || echo "0")
    echo "  Size: $file_size"
    echo "  Sequences: $seq_count"
else
    echo "❌ Test genome file not found: test_genome.fna"
fi

if [ -f "$SCRIPT_DIR/test_proteins.faa" ]; then
    echo "✓ Test protein file found: test_proteins.faa"
    file_size=$(du -h "$SCRIPT_DIR/test_proteins.faa" | cut -f1)
    seq_count=$(grep -c '^>' "$SCRIPT_DIR/test_proteins.faa" 2>/dev/null || echo "0")
    echo "  Size: $file_size"
    echo "  Sequences: $seq_count"
else
    echo "❌ Test protein file not found: test_proteins.faa"
fi

echo
echo "System Resources:"
echo "  CPU cores: $(nproc)"
echo "  Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "  Disk space: $(df -h . | awk 'NR==2 {print $4}') available"

echo
echo "Setup validation complete!"
