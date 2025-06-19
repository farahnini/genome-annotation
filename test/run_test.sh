#!/bin/bash

# Test runner script for genome annotation pipeline
# Uses the actual test file extensions (.fna and .faa)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Running Genome Annotation Pipeline Test ==="
echo "Project directory: $PROJECT_DIR"
echo "Test directory: $SCRIPT_DIR"
echo

# Check if we're in the right location
if [ ! -f "$PROJECT_DIR/main.nf" ]; then
    echo "❌ main.nf not found in $PROJECT_DIR"
    echo "Please run this script from the genome-annotation directory"
    exit 1
fi

# Check prerequisites
echo "Checking prerequisites..."

# Check Nextflow
if ! command -v nextflow >/dev/null 2>&1; then
    echo "❌ Nextflow not found. Please install it first:"
    echo "   curl -s https://get.nextflow.io | bash && sudo mv nextflow /usr/local/bin/"
    exit 1
fi
echo "✓ Nextflow found: $(nextflow -version 2>&1 | head -n1)"

# Check Singularity
if ! command -v singularity >/dev/null 2>&1; then
    echo "❌ Singularity not found. Please install it first:"
    echo "   sudo apt install -y singularity-ce"
    exit 1
fi
echo "✓ Singularity found: $(singularity --version)"

# Check if test files exist
echo
echo "Checking test data files..."
if [ ! -f "$SCRIPT_DIR/test_genome.fna" ]; then
    echo "❌ Test genome file not found: $SCRIPT_DIR/test_genome.fna"
    echo
    echo "Please run setup first:"
    echo "   ./setup_test.sh --small-test"
    echo
    exit 1
fi
echo "✓ Test genome file found"

if [ ! -f "$SCRIPT_DIR/test_proteins.faa" ]; then
    echo "❌ Test protein file not found: $SCRIPT_DIR/test_proteins.faa"
    echo
    echo "Please run setup first:"
    echo "   ./setup_test.sh --small-test"
    echo
    exit 1
fi
echo "✓ Test protein file found"

# Check if config file exists
if [ ! -f "$SCRIPT_DIR/test_data.config" ]; then
    echo "❌ Test config file not found: $SCRIPT_DIR/test_data.config"
    echo
    echo "Please run setup first:"
    echo "   ./setup_test.sh --small-test"
    echo
    exit 1
fi
echo "✓ Test configuration found"

echo
echo "✅ All prerequisites and test files found!"

# First run validation
echo "Running validation check..."
cd "$PROJECT_DIR"
nextflow run validate.nf --genome "test/test_genome.fna"

echo "✓ Validation passed"

# Run the pipeline with test data (using actual file extensions)
echo "Starting pipeline test..."
nextflow run main.nf \
    --genome "test/test_genome.fna" \
    --proteins "test/test_proteins.faa" \
    --species "test_species" \
    --outdir "test_results" \
    -profile singularity \
    -c test/test_data.config

echo "✓ Test completed successfully!"
echo "Results are in: test_results/"
