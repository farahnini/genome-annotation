process REPEATMASKER {
    tag "$genome.simpleName"
    publishDir "${params.outdir}/03_repeatmasker", mode: 'copy'
    
    container 'docker://dfam/tetools:1.88.5'
    
    cpus 8
    memory '16 GB'
    time '24h'
    
    input:
    path genome
    path repeat_library
    
    output:
    path "${genome.baseName}.masked", emit: masked_genome
    path "*.out", emit: repeat_annotation
    path "*.tbl", emit: repeat_summary
    path "*.cat.gz", emit: repeat_catalog, optional: true
    path "*.gff", emit: repeat_gff, optional: true
    path "repeatmasker.log", emit: log_file
    
    script:
    """
    #!/bin/bash
    
    # Set up RepeatMasker environment
    export PATH="/opt/RepeatMasker:\$PATH"
    
    echo "Starting RepeatMasker analysis..." > repeatmasker.log
    echo "Input genome: ${genome}" >> repeatmasker.log
    echo "Repeat library: ${repeat_library}" >> repeatmasker.log
    echo "CPUs: ${task.cpus}" >> repeatmasker.log
    echo "Start time: \$(date)" >> repeatmasker.log
    echo "" >> repeatmasker.log
    
    # Check if repeat library has content
    if [ ! -s ${repeat_library} ]; then
        echo "WARNING: Repeat library is empty, using RepBase library instead" >> repeatmasker.log
        # Run RepeatMasker with default RepBase library
        RepeatMasker \\
            -pa ${task.cpus} \\
            -species "all" \\
            -dir . \\
            -gff \\
            -excln \\
            -html \\
            -source \\
            ${genome} 2>&1 | tee -a repeatmasker.log
    else
        echo "Using custom repeat library with \$(grep -c '^>' ${repeat_library}) sequences" >> repeatmasker.log
        # Run RepeatMasker with custom library
        RepeatMasker \\
            -pa ${task.cpus} \\
            -lib ${repeat_library} \\
            -dir . \\
            -gff \\
            -excln \\
            -html \\
            -source \\
            ${genome} 2>&1 | tee -a repeatmasker.log
    fi
    
    if [ \$? -ne 0 ]; then
        echo "ERROR: RepeatMasker failed!" >> repeatmasker.log
        exit 1
    fi
    
    # Ensure masked file exists with expected name
    masked_file=\$(ls *.masked 2>/dev/null | head -1)
    if [ -n "\$masked_file" ]; then
        if [ "\$masked_file" != "${genome.baseName}.masked" ]; then
            mv "\$masked_file" "${genome.baseName}.masked"
        fi
        echo "Masked genome created: ${genome.baseName}.masked" >> repeatmasker.log
    else
        echo "ERROR: No masked genome file found!" >> repeatmasker.log
        exit 1
    fi
    
    # Generate summary statistics
    echo "" >> repeatmasker.log
    echo "RepeatMasker Summary:" >> repeatmasker.log
    
    # Count masked bases
    if [ -f "${genome.baseName}.masked" ]; then
        total_bases=\$(seqkit stats ${genome.baseName}.masked -T | tail -n1 | cut -f5)
        masked_bases=\$(seqkit seq ${genome.baseName}.masked | grep -v '^>' | tr -cd 'NnXx' | wc -c)
        echo "Total bases: \$total_bases" >> repeatmasker.log
        echo "Masked bases: \$masked_bases" >> repeatmasker.log
        
        if [ "\$total_bases" -gt 0 ]; then
            mask_percent=\$(echo "scale=2; \$masked_bases * 100 / \$total_bases" | bc -l 2>/dev/null || echo "N/A")
            echo "Percent masked: \$mask_percent%" >> repeatmasker.log
        fi
    fi
    
    # Summary from .tbl file if available
    tbl_file=\$(ls *.tbl 2>/dev/null | head -1)
    if [ -n "\$tbl_file" ]; then
        echo "" >> repeatmasker.log
        echo "Repeat classification summary from \$tbl_file:" >> repeatmasker.log
        tail -n 20 "\$tbl_file" >> repeatmasker.log
    fi
    
    echo "RepeatMasker completed at: \$(date)" >> repeatmasker.log
    """
}
