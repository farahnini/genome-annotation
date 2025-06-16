process BUSCO {
    tag "$proteins.simpleName"
    publishDir "${params.outdir}/05_busco", mode: 'copy'
    
    container 'docker://ezlabgva/busco:v5.4.7_cv1'
    
    cpus 8
    memory '16 GB'
    time '4h'
    
    input:
    path proteins
    val busco_lineage
    
    output:
    path "busco_output/", emit: output_dir
    path "busco_output/short_summary.*.txt", emit: summary
    path "busco_output/full_table.tsv", emit: full_table
    path "busco_output/busco.log", emit: log_file
    path "busco_output/missing_busco_list.tsv", emit: missing_list, optional: true
    
    script:
    def lineage_arg = busco_lineage != 'auto' ? "-l ${busco_lineage}" : "--auto-lineage-prok"
    """
    #!/bin/bash
    
    # Set up BUSCO environment
    export BUSCO_CONFIG_FILE=/busco_config/config.ini
    export AUGUSTUS_CONFIG_PATH=/augustus_config
    
    # Create output directory
    mkdir -p busco_output
    cd busco_output
    
    echo "Starting BUSCO analysis..." > busco.log
    echo "Input proteins: ${proteins}" >> busco.log
    echo "Lineage: ${busco_lineage}" >> busco.log
    echo "CPUs: ${task.cpus}" >> busco.log
    echo "Start time: \$(date)" >> busco.log
    echo "" >> busco.log
    
    # Check if protein file exists and has content
    if [ ! -s "../${proteins}" ]; then
        echo "ERROR: Protein file is empty or does not exist!" >> busco.log
        exit 1
    fi
    
    # Count proteins
    protein_count=\$(grep -c '^>' "../${proteins}" || echo "0")
    echo "Number of input proteins: \$protein_count" >> busco.log
    
    if [ "\$protein_count" -eq 0 ]; then
        echo "ERROR: No protein sequences found in input file!" >> busco.log
        exit 1
    fi
    
    echo "" >> busco.log
    echo "Running BUSCO analysis..." >> busco.log
    
    # Run BUSCO
    busco \\
        -i "../${proteins}" \\
        -o busco_analysis \\
        -m proteins \\
        ${lineage_arg} \\
        --cpu ${task.cpus} \\
        --force \\
        --offline \\
        2>&1 | tee -a busco.log
    
    busco_exit_code=\$?
    
    if [ \$busco_exit_code -ne 0 ]; then
        echo "BUSCO failed with exit code: \$busco_exit_code" >> busco.log
        
        # Try with auto-lineage if specific lineage failed
        if [ "${busco_lineage}" != "auto" ]; then
            echo "Retrying with auto-lineage..." >> busco.log
            busco \\
                -i "../${proteins}" \\
                -o busco_analysis_auto \\
                -m proteins \\
                --auto-lineage \\
                --cpu ${task.cpus} \\
                --force \\
                --offline \\
                2>&1 | tee -a busco.log
            
            if [ \$? -eq 0 ]; then
                mv busco_analysis_auto/* ./ 2>/dev/null || true
                echo "Auto-lineage analysis succeeded" >> busco.log
            else
                echo "ERROR: BUSCO analysis failed even with auto-lineage!" >> busco.log
                exit 1
            fi
        else
            echo "ERROR: BUSCO analysis failed!" >> busco.log
            exit 1
        fi
    fi
    
    # Move results to main directory and organize
    if [ -d "busco_analysis" ]; then
        mv busco_analysis/* ./ 2>/dev/null || true
        rmdir busco_analysis 2>/dev/null || true
    fi
    
    # Check for output files
    echo "" >> busco.log
    echo "BUSCO Analysis Results:" >> busco.log
    
    # Find summary file (name varies by BUSCO version and lineage)
    summary_file=\$(find . -name "short_summary*.txt" | head -1)
    if [ -n "\$summary_file" ]; then
        echo "Summary file found: \$summary_file" >> busco.log
        echo "" >> busco.log
        echo "BUSCO Summary:" >> busco.log
        cat "\$summary_file" >> busco.log        # Extract key statistics
        if grep -q "Complete BUSCOs" "\$summary_file"; then
            complete=\$(grep "Complete BUSCOs" "\$summary_file" | awk -F'[()]' '{print \$2}' | sed 's/%//')
            fragmented=\$(grep "Fragmented BUSCOs" "\$summary_file" | awk -F'[()]' '{print \$2}' | sed 's/%//')
            missing=\$(grep "Missing BUSCOs" "\$summary_file" | awk -F'[()]' '{print \$2}' | sed 's/%//')
            
            echo "" >> busco.log
            echo "Key Statistics:" >> busco.log
            echo "  Complete BUSCOs: \$complete%" >> busco.log
            echo "  Fragmented BUSCOs: \$fragmented%" >> busco.log
            echo "  Missing BUSCOs: \$missing%" >> busco.log
            
            # Quality assessment
            if (( \$(echo "\$complete >= 90" | bc -l 2>/dev/null || echo "0") )); then
                echo "  Quality: Excellent (>90% complete)" >> busco.log
            elif (( \$(echo "\$complete >= 70" | bc -l 2>/dev/null || echo "0") )); then
                echo "  Quality: Good (70-90% complete)" >> busco.log
            elif (( \$(echo "\$complete >= 50" | bc -l 2>/dev/null || echo "0") )); then
                echo "  Quality: Fair (50-70% complete)" >> busco.log
            else
                echo "  Quality: Poor (<50% complete)" >> busco.log
            fi
        fi
    else
        echo "WARNING: No summary file found!" >> busco.log
        ls -la >> busco.log
    fi
    
    # Check for full table
    if [ -f "full_table.tsv" ]; then
        echo "Full results table: full_table.tsv" >> busco.log
        total_buscos=\$(tail -n +6 full_table.tsv | wc -l)
        echo "Total BUSCOs evaluated: \$total_buscos" >> busco.log
    fi
    
    # Create missing BUSCOs list if it doesn't exist
    if [ ! -f "missing_busco_list.tsv" ] && [ -f "full_table.tsv" ]; then
        echo "Creating missing BUSCOs list..." >> busco.log
        echo -e "# BUSCO_ID\\tStatus\\tSequence" > missing_busco_list.tsv
        tail -n +6 full_table.tsv | awk '\$2=="Missing" {print \$1"\\t"\$2"\\t"\$3}' >> missing_busco_list.tsv
    fi
    
    echo "BUSCO analysis completed at: \$(date)" >> busco.log
    """
}
