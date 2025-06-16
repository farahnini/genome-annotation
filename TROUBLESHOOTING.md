# Troubleshooting Guide

## ⚠️ Platform Requirements

**This pipeline runs on Linux systems only.** If you're on Windows, you must use WSL2.

## Common Issues and Solutions

### 1. Platform and Setup Issues

#### Running on Windows directly
```
Error: Command not found or tool not working
```

**Solution:**
- This pipeline **only works on Linux**
- Windows users must use WSL2 (Windows Subsystem for Linux)
- Follow the WSL2 setup instructions in README.md
- Do not try to run annotation tools directly on Windows

#### WSL2 Performance Issues
```
Very slow execution in WSL2
```

**Solutions:**
- Copy input files to WSL2 filesystem instead of accessing via `/mnt/c/`
- Use WSL2 home directory: `cp /mnt/c/path/to/genome.fasta ~/genome.fasta`
- Allocate more RAM to WSL2 in `.wslconfig` file
- Use SSD storage for better I/O performance

### 2. Pipeline Setup Issues

#### Nextflow not found
```
Error: 'nextflow' is not recognized as a command
```

**Solution:**
- Install Nextflow following the Linux installation guide in README.md
- Ensure Nextflow is in your PATH: `echo $PATH`
- Try full path: `~/tools/nextflow` or `/usr/local/bin/nextflow`
- Verify with: `nextflow -version`

#### Container runtime issues
```
Error: Unable to access the container registry
```

**Solutions:**
- **For Singularity:** Ensure Singularity/Apptainer is properly installed
- **For Docker:** Ensure Docker daemon is running: `sudo systemctl start docker`
- Test container access: `singularity pull docker://hello-world`
- Use `-profile singularity` or `-profile docker` explicitly
- Check internet connectivity for downloading containers

### 3. Input File Issues

#### Genome file not found
```
Error: Can't read file: genome.fasta
```

**Solution:**
- Check the file path is correct (use absolute paths: `/home/user/genome.fasta`)
- Ensure the file exists and is readable: `ls -la /path/to/genome.fasta`
- For WSL2 users: avoid spaces in Windows paths or copy files to Linux filesystem
- Use forward slashes in all paths

#### Invalid FASTA format
```
Error: Invalid FASTA format detected
```

**Solutions:**
- Validate your FASTA file using `seqkit` or similar tools
- Remove any non-standard characters from headers
- Ensure sequences contain only valid nucleotide characters (A, T, G, C, N)

### 4. Memory and Resource Issues

#### Out of memory errors
```
Error: Process killed due to insufficient memory
```

**Solutions:**
- Increase memory allocation in `nextflow.config`
- Use a machine with more RAM
- Split large genomes into smaller chunks if possible
- Use the `laptop` profile for resource-constrained environments

#### Process timeout
```
Error: Process exceeded maximum time limit
```

**Solutions:**
- Increase time limits in the configuration
- Use more CPU cores to speed up processing
- Check if the process is actually making progress (not stuck)

### 5. Container Issues

#### Singularity pull failures
```
Error: Failed to pull container image
```

**Solutions:**
- Check internet connectivity
- Try pulling the container manually: `singularity pull docker://dfam/tetools:1.88.5`
- Use Docker instead if Singularity is problematic: `-profile docker`
- Set up a local container cache directory
- For WSL2: ensure adequate disk space in WSL2 filesystem

#### Docker permission issues
```
Error: Permission denied while trying to connect to Docker daemon
```

**Solutions:**
- Ensure Docker daemon is running: `sudo systemctl start docker`
- Add your user to the Docker group: `sudo usermod -aG docker $USER`
- Log out and back in after adding to docker group
- For WSL2: ensure Docker Desktop has WSL2 integration enabled

### 6. Tool-Specific Issues

#### RepeatModeler fails to find repeats
```
Warning: No repeats identified by RepeatModeler
```

**Solutions:**
- This is normal for small genomes or genomes with few repeats
- Check the log files for actual errors
- Ensure the genome is large enough (>1 Mb recommended)
- Consider using a pre-built repeat library

#### BRAKER3 configuration errors
```
Error: AUGUSTUS species configuration failed
```

**Solutions:**
- Use a simple species name without special characters
- Ensure the species name doesn't conflict with existing AUGUSTUS species
- Check AUGUSTUS installation in the container

#### RepeatMasker library issues
```
Error: Empty repeat library
```

**Solutions:**
- This happens when RepeatModeler finds no repeats
- The pipeline will fall back to the RepBase library
- For small genomes, this is expected behavior

### 7. Performance Issues

#### Very slow execution
**Solutions:**
- Increase CPU allocation for compute-intensive steps
- Use SSD storage for work directories
- Ensure sufficient RAM to avoid swapping
- Use the appropriate execution profile for your hardware

#### Disk space issues
```
Error: No space left on device
```

**Solutions:**
- Clean up previous runs: `rm -rf work .nextflow*`
- Use a different work directory with more space: `nextflow run main.nf -w /path/to/large/disk/work`
- Remove unnecessary intermediate files
- Compress large output files: `gzip large_files.fasta`
- For WSL2: clean Windows temp files and increase WSL2 disk allocation

### 8. Output Issues

#### Missing output files
**Solutions:**
- Check the process logs for errors
- Ensure all processes completed successfully
- Look for partial outputs in the work directories
- Re-run with `-resume` to continue from the last successful step

#### Corrupted output files
**Solutions:**
- Check disk space during execution
- Verify input file integrity
- Re-run the specific failed process
- Check for hardware issues (RAM, disk)

## Debugging Commands

### Check pipeline status
```powershell
.\pipeline_manager.ps1 monitor
```

### Validate input files
```powershell
.\pipeline_manager.ps1 validate -Genome genome.fasta
```

### Generate summary report
```powershell
.\pipeline_manager.ps1 summary -OutDir results
```

### Clean up failed runs
```powershell
.\pipeline_manager.ps1 clean
```

### Run with increased verbosity
```powershell
nextflow run main.nf --genome genome.fasta -profile singularity -resume -with-trace -with-report -with-timeline -with-dag
```

## Log Files to Check

1. **Main Nextflow log:** `.nextflow.log`
2. **Process-specific logs:** `work/*/*/.command.log`
3. **Tool-specific logs:**
   - `results/01_cleaned_genome/cleaning_stats.txt`
   - `results/02_repeatmodeler/repeatmodeler_output/repeatmodeler.log`
   - `results/03_repeatmasker/repeatmasker.log`
   - `results/04_braker3/braker_output/braker.log`

## Getting Help

1. **Check the logs** first - they usually contain the specific error message
2. **Search online** for the specific error message
3. **Check tool documentation:**
   - RepeatModeler: http://www.repeatmasker.org/RepeatModeler/
   - RepeatMasker: http://www.repeatmasker.org/
   - BRAKER: https://github.com/Gaius-Augustus/BRAKER
4. **Nextflow documentation:** https://www.nextflow.io/docs/latest/
5. **Container issues:** Check Docker/Singularity documentation

## Hardware Recommendations

### Minimum Requirements
- 16 GB RAM
- 8 CPU cores
- 100 GB free disk space
- Internet connection for container downloads

### Recommended Requirements
- 64 GB RAM
- 32 CPU cores
- 500 GB free disk space (SSD preferred)
- High-speed internet for large container downloads

### For Large Genomes (>5 GB)
- 128+ GB RAM
- 64+ CPU cores
- 1+ TB disk space
- Consider using HPC/cluster resources
