process REPEATMODELER {
    tag "$genome.simpleName"
    publishDir "${params.outdir}/02_repeatmodeler", mode: 'copy'
    
    container 'docker://dfam/tetools:1.88.5'
    
    cpus 16
    memory '32 GB'
    time '48h'
    
    input:
    path genome
    
    output:
    path "repeatmodeler_output/", emit: output_dir
    path "repeatmodeler_output/consensi.fa.classified", emit: repeat_library
    path "repeatmodeler_output/repeatmodeler.log", emit: log_file
    
    script:
    """
    #!/bin/bash
    
    # Set up RepeatModeler environment
    export PATH="/opt/RepeatMasker:/opt/RepeatModeler:\$PATH"
    
    # Create working directory
    mkdir -p repeatmodeler_output
    cd repeatmodeler_output
    
    echo "Starting RepeatModeler analysis..." > repeatmodeler.log
    echo "Input genome: ${genome}" >> repeatmodeler.log
    echo "CPUs: ${task.cpus}" >> repeatmodeler.log
    echo "Start time: \$(date)" >> repeatmodeler.log
    echo "" >> repeatmodeler.log
    
    # Create RepeatModeler database
    echo "Building RepeatModeler database..." >> repeatmodeler.log
    BuildDatabase -name genome_db ../${genome} 2>&1 | tee -a repeatmodeler.log
    
    if [ \$? -ne 0 ]; then
        echo "ERROR: BuildDatabase failed!" >> repeatmodeler.log
        exit 1
    fi
    
    # Run RepeatModeler with LTR structural analysis
    echo "Running RepeatModeler..." >> repeatmodeler.log
    RepeatModeler \\
        -pa ${task.cpus} \\
        -database genome_db \\
        -LTRStruct \\
        2>&1 | tee -a repeatmodeler.log
    
    if [ \$? -ne 0 ]; then
        echo "ERROR: RepeatModeler failed!" >> repeatmodeler.log
        exit 1
    fi
    
    # Find and organize the consensi file
    consensi_file=\$(find . -name "consensi.fa.classified" | head -1)
    if [ -z "\$consensi_file" ]; then
        # Look for unclassified consensi
        consensi_file=\$(find . -name "consensi.fa" | head -1)
        if [ -n "\$consensi_file" ]; then
            echo "Found unclassified consensi file, copying as classified..." >> repeatmodeler.log
            cp "\$consensi_file" consensi.fa.classified
        else
            echo "WARNING: No consensi file found, creating empty file..." >> repeatmodeler.log
            touch consensi.fa.classified
        fi
    else
        echo "Found classified consensi file: \$consensi_file" >> repeatmodeler.log
        if [ "\$consensi_file" != "./consensi.fa.classified" ]; then
            cp "\$consensi_file" consensi.fa.classified
        fi
    fi
    
    # Count repeats found
    if [ -s consensi.fa.classified ]; then
        repeat_count=\$(grep -c '^>' consensi.fa.classified)
        echo "RepeatModeler found \$repeat_count repeat families" >> repeatmodeler.log
    else
        echo "No repeats identified by RepeatModeler" >> repeatmodeler.log
    fi
    
    echo "RepeatModeler completed at: \$(date)" >> repeatmodeler.log
    """
}
