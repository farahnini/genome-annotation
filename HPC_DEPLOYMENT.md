# HPC Deployment Guide

## 📦 Preparing for HPC

1. **Package your pipeline:**
   ```bash
   # On Windows/local machine
   git clone https://github.com/farahnini/genome-annotation.git
   cd genome-annotation
   .\setup_simple.sh  # Sets up environment files
   
   # Create deployment package
   tar -czf genome-annotation-hpc.tar.gz *
   ```

2. **Transfer to HPC:**
   ```bash
   scp genome-annotation-hpc.tar.gz username@hpc-cluster:/path/to/your/directory/
   ```

## 🖥️ Setting up on HPC

1. **Extract and setup:**
   ```bash
   ssh username@hpc-cluster
   cd /path/to/your/directory/
   tar -xzf genome-annotation-hpc.tar.gz
   cd genome-annotation
   
   # Activate environment
   source activate_environment.sh
   ```

2. **Load HPC modules (if needed):**
   ```bash
   # Common HPC module commands
   module load singularity
   module load java/17    # or java/11
   module load nextflow   # if available
   
   # Check what's available
   module avail
   ```

3. **Test setup (optional):**
   ```bash
   # Quick test with small data
   ./test/run_test.sh
   ```

## 🚀 Running on HPC

### SLURM Example:
```bash
#!/bin/bash
#SBATCH --job-name=genome-annotation
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --mem=64GB
#SBATCH --time=48:00:00

# Load modules
module load singularity java/17

# Activate environment
cd /path/to/genome-annotation
source activate_environment.sh

# Run pipeline
nextflow run main.nf \
  --genome /path/to/your/genome.fasta \
  --species "Your_species_name" \
  --outdir results \
  -profile singularity \
  -resume
```

### PBS Example:
```bash
#!/bin/bash
#PBS -N genome-annotation
#PBS -l select=1:ncpus=16:mem=64gb
#PBS -l walltime=48:00:00

# Load modules
module load singularity java

# Activate environment
cd $PBS_O_WORKDIR/genome-annotation
source activate_environment.sh

# Run pipeline
nextflow run main.nf \
  --genome /path/to/your/genome.fasta \
  --species "Your_species_name" \
  --outdir results \
  -profile singularity \
  -resume
```

## ⚙️ HPC Configuration

Create `hpc.config` for your specific cluster:

```groovy
// HPC-specific configuration
params {
    max_memory = '128.GB'
    max_cpus = 32
    max_time = '72.h'
}

process {
    executor = 'slurm'  // or 'pbs', 'sge', etc.
    queue = 'compute'
    
    // Increase resources for HPC
    withName: REPEATMODELER {
        cpus = 16
        memory = '64.GB'
        time = '48.h'
    }
    
    withName: BRAKER3 {
        cpus = 16
        memory = '128.GB'
        time = '72.h'
    }
}

singularity {
    enabled = true
    autoMounts = true
    cacheDir = '/scratch/singularity_cache'  // Use fast storage
}
```

Then run with: `nextflow run main.nf -c hpc.config ...`

## 🔧 Common HPC Issues

1. **Java compatibility:** Environment script handles this automatically
2. **Singularity cache:** Use scratch storage for better performance
3. **File permissions:** Ensure scripts are executable: `chmod +x *.sh test/*.sh`
4. **Network access:** Some HPC systems restrict internet for container downloads

## 📁 Required Files for HPC

Minimum files needed:
- `main.nf`
- `nextflow.config`
- `activate_environment.sh`
- `modules/` directory
- `test/` directory (for testing)
- Your genome and protein files

Optional but recommended:
- `hpc.config` (cluster-specific settings)
- `TROUBLESHOOTING.md`
