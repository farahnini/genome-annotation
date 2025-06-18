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

# Check if test files exist
if [ ! -f "$SCRIPT_DIR/test_genome.fna" ]; then
    echo "❌ Test genome file not found: $SCRIPT_DIR/test_genome.fna"
    echo "Please run setup_test.sh first to download test data"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/test_proteins.faa" ]; then
    echo "❌ Test protein file not found: $SCRIPT_DIR/test_proteins.faa"
    echo "Please run setup_test.sh first to download test data"
    exit 1
fi

# Check if config file exists
if [ ! -f "$SCRIPT_DIR/test_data.config" ]; then
    echo "❌ Test config file not found: $SCRIPT_DIR/test_data.config"
    echo "Please run setup_test.sh first to create test configuration"
    exit 1
fi

echo "✓ Test files and configuration found"

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
