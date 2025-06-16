process BRAKER3 {
    tag "$genome.simpleName"
    publishDir "${params.outdir}/04_braker3", mode: 'copy'
    
    container 'docker://teambraker/braker3:latest'
    
    cpus 16
    memory '64 GB'
    time '72h'
    
    input:
    path masked_genome
    path proteins
    path rna_seq
    
    output:
    path "braker_output/", emit: output_dir
    path "braker_output/augustus.hints.gtf", emit: gene_annotation, optional: true
    path "braker_output/augustus.hints.gff3", emit: gene_annotation_gff3, optional: true
    path "braker_output/augustus.hints.aa", emit: protein_sequences, optional: true
    path "braker_output/augustus.hints.codingseq", emit: coding_sequences, optional: true
    path "braker_output/braker.log", emit: log_file
    
    script:
    def protein_arg = proteins.name != 'NO_FILE' && proteins.size() > 0 ? "--prot_seq=${proteins}" : ""
    def rnaseq_arg = rna_seq.name != 'NO_FILE' && rna_seq.size() > 0 ? "--rnaseq_sets_ids=${rna_seq}" : ""
    def species_name = params.species.replaceAll(/[^a-zA-Z0-9_]/, "_")
    """
    #!/bin/bash
    
    # Set up BRAKER3 environment
    export AUGUSTUS_CONFIG_PATH=/opt/Augustus/config
    export AUGUSTUS_BIN_PATH=/opt/Augustus/bin
    export AUGUSTUS_SCRIPTS_PATH=/opt/Augustus/scripts
    export GENEMARK_PATH=/opt/gmes_linux_64
    export PROTHINT_PATH=/opt/ProtHint/bin
    
    # Create output directory
    mkdir -p braker_output
    cd braker_output
    
    echo "Starting BRAKER3 analysis..." > braker.log
    echo "Input genome: ${masked_genome}" >> braker.log
    echo "Proteins: ${proteins.name != 'NO_FILE' ? proteins : 'Not provided'}" >> braker.log
    echo "RNA-seq: ${rna_seq.name != 'NO_FILE' ? rna_seq : 'Not provided'}" >> braker.log
    echo "Species: ${species_name}" >> braker.log
    echo "CPUs: ${task.cpus}" >> braker.log
    echo "Start time: \$(date)" >> braker.log
    echo "" >> braker.log
    
    # Prepare AUGUSTUS species config
    mkdir -p /opt/Augustus/config/species/${species_name}
    cp /opt/Augustus/config/species/generic/* /opt/Augustus/config/species/${species_name}/
    
    # Build BRAKER command
    braker_cmd="braker.pl \\
        --genome=../${masked_genome} \\
        --species=${species_name} \\
        --cores=${task.cpus} \\
        --workingdir=. \\
        --gff3 \\
        --softmasking"
    
    # Add protein evidence if provided
    if [ "${protein_arg}" != "" ]; then
        echo "Adding protein evidence..." >> braker.log
        braker_cmd="\$braker_cmd ${protein_arg}"
    fi
    
    # Add RNA-seq evidence if provided
    if [ "${rnaseq_arg}" != "" ]; then
        echo "Adding RNA-seq evidence..." >> braker.log
        braker_cmd="\$braker_cmd ${rnaseq_arg}"
    fi
    
    # Check if we have any evidence
    if [ "${protein_arg}" == "" ] && [ "${rnaseq_arg}" == "" ]; then
        echo "WARNING: No external evidence provided, running BRAKER in unsupervised mode" >> braker.log
        braker_cmd="\$braker_cmd --esmode"
    fi
    
    echo "BRAKER command: \$braker_cmd" >> braker.log
    echo "" >> braker.log
    
    # Run BRAKER3
    eval "\$braker_cmd" 2>&1 | tee -a braker.log
    
    if [ \$? -ne 0 ]; then
        echo "ERROR: BRAKER3 failed!" >> braker.log
        exit 1
    fi
    
    # Check for output files and create summaries
    echo "" >> braker.log
    echo "BRAKER3 Output Summary:" >> braker.log
    
    if [ -f augustus.hints.gtf ]; then
        gene_count=\$(grep -c "\\tgene\\t" augustus.hints.gtf)
        echo "Genes predicted: \$gene_count" >> braker.log
        
        if [ -f augustus.hints.aa ]; then
            protein_count=\$(grep -c '^>' augustus.hints.aa)
            echo "Proteins predicted: \$protein_count" >> braker.log
        fi
        
        if [ -f augustus.hints.codingseq ]; then
            cds_count=\$(grep -c '^>' augustus.hints.codingseq)
            echo "Coding sequences: \$cds_count" >> braker.log
        fi
    else
        echo "WARNING: No augustus.hints.gtf file found!" >> braker.log
        ls -la >> braker.log
    fi
    
    # Generate gene density statistics
    if [ -f augustus.hints.gtf ] && [ -f "../${masked_genome}" ]; then
        genome_size=\$(seqkit stats "../${masked_genome}" -T | tail -n1 | cut -f5)
        if [ "\$gene_count" -gt 0 ] && [ "\$genome_size" -gt 0 ]; then
            gene_density=\$(echo "scale=2; \$gene_count * 1000000 / \$genome_size" | bc -l 2>/dev/null || echo "N/A")
            echo "Gene density: \$gene_density genes per Mb" >> braker.log
        fi
    fi
    
    echo "BRAKER3 completed at: \$(date)" >> braker.log
    """
}
