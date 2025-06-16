#!/usr/bin/env nextflow

/*
 * Test workflow to validate pipeline functionality
 * This workflow runs basic checks on input files and pipeline setup
 */

nextflow.enable.dsl = 2

params.genome = null
params.test_mode = true

workflow VALIDATE_PIPELINE {
    
    if (!params.genome) {
        error "Please provide a test genome file with --genome"
    }
    
    genome_ch = Channel.fromPath(params.genome, checkIfExists: true)
    
    // Basic validation processes
    VALIDATE_GENOME(genome_ch)
    CHECK_CONTAINERS()
    
    VALIDATE_GENOME.out.validation_report.view { 
        "Genome validation complete: $it" 
    }
}

process VALIDATE_GENOME {
    container 'docker://biocontainers/seqkit:v2.3.1_cv1'
    
    input:
    path genome
    
    output:
    path "validation_report.txt", emit: validation_report
    
    script:
    """
    echo "Genome Validation Report" > validation_report.txt
    echo "========================" >> validation_report.txt
    echo "File: ${genome}" >> validation_report.txt
    echo "Date: \$(date)" >> validation_report.txt
    echo "" >> validation_report.txt
    
    # Check if file exists and is readable
    if [ -r "${genome}" ]; then
        echo "✓ File is readable" >> validation_report.txt
    else
        echo "✗ File is not readable" >> validation_report.txt
    fi
    
    # Get basic statistics
    echo "" >> validation_report.txt
    echo "Basic Statistics:" >> validation_report.txt
    seqkit stats ${genome} >> validation_report.txt
    
    # Check for common issues
    echo "" >> validation_report.txt
    echo "Quality Checks:" >> validation_report.txt
    
    # Check for sequences
    seq_count=\$(seqkit stats ${genome} -T | tail -n1 | cut -f4)
    if [ "\$seq_count" -gt 0 ]; then
        echo "✓ Contains \$seq_count sequences" >> validation_report.txt
    else
        echo "✗ No sequences found" >> validation_report.txt
    fi
    
    # Check for problematic characters in headers
    problematic_headers=\$(grep '^>' ${genome} | grep -c '[^A-Za-z0-9_>.-]' || echo "0")
    if [ "\$problematic_headers" -eq 0 ]; then
        echo "✓ Headers contain only standard characters" >> validation_report.txt
    else
        echo "⚠ \$problematic_headers headers contain special characters (will be cleaned)" >> validation_report.txt
    fi
    
    # Check sequence composition
    echo "" >> validation_report.txt
    echo "Sequence Composition:" >> validation_report.txt
    seqkit fx2tab ${genome} | cut -f2 | tr -d '\\n' | fold -w1 | sort | uniq -c | sort -nr >> validation_report.txt
    
    echo "" >> validation_report.txt
    echo "Validation completed successfully" >> validation_report.txt
    """
}

process CHECK_CONTAINERS {
    
    output:
    stdout emit: container_status
    
    script:
    """
    echo "Container Availability Check"
    echo "============================"
    
    # Check if Singularity is available
    if command -v singularity &> /dev/null; then
        echo "✓ Singularity is available: \$(singularity --version)"
    else
        echo "✗ Singularity not found"
    fi
    
    # Check if Docker is available
    if command -v docker &> /dev/null; then
        echo "✓ Docker is available: \$(docker --version)"
    else
        echo "✗ Docker not found"
    fi
    
    echo ""
    echo "Note: At least one container runtime (Singularity or Docker) is required"
    """
}

workflow {
    VALIDATE_PIPELINE()
}
