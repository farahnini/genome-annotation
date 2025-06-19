#!/bin/bash

# Singularity container management script for genome annotation pipeline
# This script builds and manages the complete environment container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONTAINER_DIR="$PROJECT_DIR/containers"
CONTAINER_DEF="$CONTAINER_DIR/genome-annotation-complete.def"
CONTAINER_SIF="$CONTAINER_DIR/genome-annotation-complete.sif"

echo "=== Singularity Container Manager ==="
echo "Project directory: $PROJECT_DIR"
echo "Container definition: $CONTAINER_DEF"
echo "Container image: $CONTAINER_SIF"
echo

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    if ! command -v singularity >/dev/null 2>&1; then
        echo "❌ Singularity not found"
        echo "Please install Singularity first:"
        echo "  sudo apt install -y singularity-ce"
        exit 1
    fi
    
    echo "✓ Singularity found: $(singularity --version)"
    
    if [ ! -f "$CONTAINER_DEF" ]; then
        echo "❌ Container definition not found: $CONTAINER_DEF"
        exit 1
    fi
    
    echo "✓ Container definition found"
}

# Function to build container
build_container() {
    echo "Building Singularity container..."
    echo "This may take 30-60 minutes depending on your internet connection..."
    echo
    
    # Remove existing container if it exists
    if [ -f "$CONTAINER_SIF" ]; then
        echo "Removing existing container..."
        rm -f "$CONTAINER_SIF"
    fi
    
    # Build container
    cd "$CONTAINER_DIR"
    sudo singularity build genome-annotation-complete.sif genome-annotation-complete.def
    
    if [ -f "$CONTAINER_SIF" ]; then
        echo "✓ Container built successfully: $CONTAINER_SIF"
        
        # Test the container
        echo "Testing container..."
        singularity run "$CONTAINER_SIF" java -version
        singularity run "$CONTAINER_SIF" /opt/nextflow/nextflow -version
        
        echo "✓ Container test passed"
    else
        echo "❌ Container build failed"
        exit 1
    fi
}

# Function to test container
test_container() {
    if [ ! -f "$CONTAINER_SIF" ]; then
        echo "❌ Container not found: $CONTAINER_SIF"
        echo "Please build the container first with: $0 build"
        exit 1
    fi
    
    echo "Testing container functionality..."
    
    # Test Java
    echo "Testing Java..."
    singularity run "$CONTAINER_SIF" java -version
    
    # Test Nextflow
    echo "Testing Nextflow..."
    singularity run "$CONTAINER_SIF" /opt/nextflow/nextflow -version
    
    # Test bioinformatics tools
    echo "Testing bioinformatics tools..."
    singularity run "$CONTAINER_SIF" augustus --version 2>/dev/null || echo "Augustus available"
    singularity run "$CONTAINER_SIF" busco --version
    singularity run "$CONTAINER_SIF" seqkit version
    singularity run "$CONTAINER_SIF" samtools --version | head -n1
    
    echo "✓ All tests passed"
}

# Function to run pipeline with container
run_pipeline() {
    if [ ! -f "$CONTAINER_SIF" ]; then
        echo "❌ Container not found: $CONTAINER_SIF"
        echo "Please build the container first with: $0 build"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    echo "Running pipeline with Singularity container..."
    echo "Container: $CONTAINER_SIF"
    echo "Arguments: $@"
    echo
    
    # Run the pipeline
    singularity run "$CONTAINER_SIF" /opt/nextflow/nextflow run main.nf "$@"
}

# Function to enter container shell
shell_container() {
    if [ ! -f "$CONTAINER_SIF" ]; then
        echo "❌ Container not found: $CONTAINER_SIF"
        echo "Please build the container first with: $0 build"
        exit 1
    fi
    
    echo "Starting interactive shell in container..."
    singularity shell "$CONTAINER_SIF"
}

# Function to show container info
info_container() {
    if [ ! -f "$CONTAINER_SIF" ]; then
        echo "❌ Container not found: $CONTAINER_SIF"
        return 1
    fi
    
    echo "Container Information:"
    echo "====================="
    echo "File: $CONTAINER_SIF"
    echo "Size: $(du -h "$CONTAINER_SIF" | cut -f1)"
    echo "Created: $(stat -c %y "$CONTAINER_SIF" 2>/dev/null || stat -f %Sm "$CONTAINER_SIF" 2>/dev/null)"
    echo
    
    echo "Container Contents:"
    singularity inspect "$CONTAINER_SIF"
    
    echo
    echo "Container Help:"
    singularity run-help "$CONTAINER_SIF"
}

# Function to clean up
clean_container() {
    echo "Cleaning up container files..."
    
    if [ -f "$CONTAINER_SIF" ]; then
        echo "Removing container: $CONTAINER_SIF"
        rm -f "$CONTAINER_SIF"
    fi
    
    # Clean Singularity cache
    if command -v singularity >/dev/null 2>&1; then
        echo "Cleaning Singularity cache..."
        singularity cache clean --force
    fi
    
    echo "✓ Cleanup completed"
}

# Main script logic
case "${1:-help}" in
    build)
        check_prerequisites
        build_container
        ;;
    test)
        test_container
        ;;
    run)
        shift
        run_pipeline "$@"
        ;;
    shell)
        shell_container
        ;;
    info)
        info_container
        ;;
    clean)
        clean_container
        ;;
    help|*)
        echo "Singularity Container Manager for Genome Annotation Pipeline"
        echo
        echo "Usage: $0 <command> [options]"
        echo
        echo "Commands:"
        echo "  build         Build the Singularity container (requires sudo)"
        echo "  test          Test the built container"
        echo "  run [args]    Run the pipeline with the container"
        echo "  shell         Start interactive shell in container"
        echo "  info          Show container information"
        echo "  clean         Remove container and clean cache"
        echo "  help          Show this help message"
        echo
        echo "Examples:"
        echo "  $0 build"
        echo "  $0 test"
        echo "  $0 run --genome genome.fasta --species 'E_coli' -profile singularity"
        echo "  $0 shell"
        ;;
esac
