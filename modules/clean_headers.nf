process CLEAN_HEADERS {
    tag "$genome.simpleName"
    publishDir "${params.outdir}/01_cleaned_genome", mode: 'copy'
    
    container 'docker://biocontainers/seqkit:v2.3.1_cv1'
    
    input:
    path genome
    
    output:
    path "cleaned_${genome}", emit: cleaned_genome
    path "header_mapping.txt", emit: header_mapping
    path "cleaning_stats.txt", emit: stats
    
    script:
    """
    #!/bin/bash
    
    # Get original stats
    echo "Original genome statistics:" > cleaning_stats.txt
    echo "Number of sequences: \$(grep -c '^>' ${genome})" >> cleaning_stats.txt
    echo "Total length: \$(seqkit stats ${genome} -T | tail -n1 | cut -f5)" >> cleaning_stats.txt
    echo "" >> cleaning_stats.txt
    
    # Clean headers to remove problematic characters and make them NCBI compliant
    # Replace spaces, special characters, and long headers
    seqkit replace \\
        -p '^(.{0,50}).*' \\
        -r 'seq_{nr}_\$1' \\
        --nr-width 6 \\
        ${genome} | \\
    seqkit replace \\
        -p '[^A-Za-z0-9_-]' \\
        -r '_' > temp_cleaned.fa
    
    # Remove duplicate underscores and clean up
    seqkit replace \\
        -p '__+' \\
        -r '_' \\
        temp_cleaned.fa > cleaned_${genome}
    
    # Create a mapping file for reference
    echo "Original_Header\tNew_Header" > header_mapping.txt
    seqkit fx2tab ${genome} | cut -f1 > original_headers.txt
    seqkit fx2tab cleaned_${genome} | cut -f1 > new_headers.txt
    paste original_headers.txt new_headers.txt >> header_mapping.txt
    
    # Get cleaned stats
    echo "Cleaned genome statistics:" >> cleaning_stats.txt
    echo "Number of sequences: \$(grep -c '^>' cleaned_${genome})" >> cleaning_stats.txt
    echo "Total length: \$(seqkit stats cleaned_${genome} -T | tail -n1 | cut -f5)" >> cleaning_stats.txt
    
    # Validate that no sequences were lost
    orig_count=\$(grep -c '^>' ${genome})
    clean_count=\$(grep -c '^>' cleaned_${genome})
    
    if [ "\$orig_count" -ne "\$clean_count" ]; then
        echo "ERROR: Sequence count mismatch! Original: \$orig_count, Cleaned: \$clean_count" >&2
        exit 1
    fi
    
    # Remove temporary files
    rm original_headers.txt new_headers.txt temp_cleaned.fa
    
    echo "Header cleaning completed successfully!" >> cleaning_stats.txt
    """
}
