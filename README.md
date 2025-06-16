# Genome Annotation Pipeline

A Nextflow pipeline for comprehensive genome annotation using RepeatModeler, RepeatMasker, and BRAKER3.

## ⚠️ Platform Requirements

**This pipeline runs on Linux systems only.** The annotation tools (RepeatModeler, RepeatMasker, BRAKER3) are designed for Linux environments.

**Windows users**: You must use WSL2 (Windows Subsystem for Linux) to run this pipeline.

## Overview

This pipeline performs the following steps:

1. **Header Cleaning**: Cleans FASTA headers to ensure compatibility with downstream tools
2. **RepeatModeler**: Identifies de novo repeat families in the genome
3. **RepeatMasker**: Masks repetitive elements using the custom repeat library
4. **BRAKER3**: Predicts genes using the masked genome and optional evidence
5. **BUSCO**: Evaluates completeness of predicted protein sequences using universal single-copy orthologs

## 📥 Complete Installation Guide

### Installation Path A: Native Linux Systems

#### Step 1: Install Prerequisites

##### 1.1 Update System and Install Basic Tools
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl git unzip default-jdk build-essential

# CentOS/RHEL/Fedora
sudo yum update -y  # or dnf update -y for Fedora
sudo yum install -y wget curl git unzip java-11-openjdk-devel gcc gcc-c++ make  # or dnf install for Fedora
```

##### 1.2 Verify Java Installation
```bash
java -version
# Should show version 11 or later
```

#### Step 2: Install Nextflow

```bash
# Create tools directory
mkdir -p ~/tools
cd ~/tools

# Download and install Nextflow
wget -qO- https://get.nextflow.io | bash

# Make it executable and add to PATH
chmod +x nextflow
sudo mv nextflow /usr/local/bin/

# OR add to your local PATH
echo 'export PATH=~/tools:$PATH' >> ~/.bashrc
source ~/.bashrc
```

#### Step 3: Install Container Runtime

##### Option A: Singularity/Apptainer (Recommended)
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:apptainer/ppa
sudo apt update
sudo apt install -y apptainer

# Create symlink for Singularity compatibility
sudo ln -s /usr/bin/apptainer /usr/bin/singularity

# CentOS/RHEL (requires EPEL)
sudo yum install -y epel-release
sudo yum install -y singularity-ce

# Fedora
sudo dnf install -y singularity
```

##### Option B: Docker
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# CentOS/RHEL
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Fedora
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### Step 4: Verify Installation
```bash
# Check Nextflow
nextflow -version

# Check Singularity
singularity --version

# Check Docker (if installed)
docker --version
docker run hello-world
```

### Installation Path B: Windows Users (WSL2 Required)

#### Step 1: Install WSL2 and Ubuntu

1. **Enable WSL2 on Windows**
   ```powershell
   # Run as Administrator in PowerShell
   wsl --install
   
   # Restart your computer when prompted
   ```

2. **Install Ubuntu after restart**
   ```powershell
   # Install Ubuntu 20.04 LTS (recommended)
   wsl --install -d Ubuntu-20.04
   
   # Set up username and password when prompted
   ```

3. **Update WSL2 to version 2**
   ```powershell
   wsl --set-version Ubuntu-20.04 2
   wsl --set-default Ubuntu-20.04
   ```

#### Step 2: Configure Ubuntu in WSL2

```bash
# Enter WSL2 Ubuntu environment
wsl

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y wget curl git unzip default-jdk build-essential

# Verify Java
java -version
```

#### Step 3: Install Nextflow in WSL2

```bash
# Create tools directory
mkdir -p ~/tools
cd ~/tools

# Download and install Nextflow
wget -qO- https://get.nextflow.io | bash

# Add to PATH
echo 'export PATH=~/tools:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify installation
nextflow -version
```

#### Step 4: Install Singularity in WSL2

```bash
# Install Singularity/Apptainer
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:apptainer/ppa
sudo apt update
sudo apt install -y apptainer

# Create symlink for compatibility
sudo ln -s /usr/bin/apptainer /usr/bin/singularity

# Verify installation
singularity --version
```

#### Step 5: Access Files Between Windows and WSL2

```bash
# Windows files are accessible at /mnt/c/
ls /mnt/c/Users/YourUsername/

# WSL2 files are accessible from Windows at:
# \\wsl$\Ubuntu-20.04\home\yourusername\

# Copy pipeline to WSL2 (recommended)
cp -r /mnt/c/Projects/genome-annotation ~/genome-annotation
cd ~/genome-annotation
```

### Common Setup for All Linux Systems

#### Download the Pipeline

##### Option A: Git Clone (Recommended)
```bash
# Clone the repository
git clone https://github.com/your-username/genome-annotation.git
cd genome-annotation

# Make scripts executable
chmod +x *.sh
```

##### Option B: Download and Extract
```bash
# Download pipeline
wget https://github.com/your-username/genome-annotation/archive/main.zip
unzip main.zip
mv genome-annotation-main genome-annotation
cd genome-annotation

# Make scripts executable
chmod +x *.sh
```

##### Option C: Create from Files
```bash
# Create directory
mkdir ~/genome-annotation
cd ~/genome-annotation

# Copy all pipeline files here
# Make sure to include: main.nf, nextflow.config, modules/, scripts/, etc.

# Make scripts executable
chmod +x *.sh
```

#### Configure the Pipeline

```bash
# Test container access
singularity pull docker://biocontainers/seqkit:v2.3.1_cv1

# OR for Docker users
docker pull biocontainers/seqkit:v2.3.1_cv1
```

#### Validate Installation

```bash
# Check all dependencies
nextflow -version
singularity --version  # or docker --version

# Download and test with sample data
./setup_test.sh  # Create this script for Linux
```

## 🚀 Quick Start Guide

### Basic Usage Commands

All commands should be run in a Linux terminal (native Linux or WSL2):

#### 1. Basic Genome Annotation
```bash
nextflow run main.nf \
    --genome /path/to/genome.fasta \
    --species "my_species" \
    --outdir results \
    -profile singularity
```

#### 2. With Protein Evidence
```bash
nextflow run main.nf \
    --genome /path/to/genome.fasta \
    --proteins /path/to/proteins.fasta \
    --species "my_species" \
    --outdir results \
    -profile singularity
```

#### 3. Complete Annotation with All Evidence
```bash
nextflow run main.nf \
    --genome /path/to/genome.fasta \
    --proteins /path/to/proteins.fasta \
    --rna_seq /path/to/rnaseq.fastq \
    --species "my_species" \
    --busco_db "eukaryota_odb10" \
    --outdir results \
    -profile singularity \
    -resume
```

#### 4. Bacterial Genome Annotation
```bash
nextflow run main.nf \
    --genome /path/to/bacterial_genome.fasta \
    --species "my_bacteria" \
    --busco_db "bacteria_odb10" \
    --outdir results \
    -profile singularity
```

#### 4. For Docker Users
```bash
nextflow run main.nf \
    --genome /path/to/genome.fasta \
    --species "my_species" \
    --busco_db "auto" \
    --outdir results \
    -profile docker
```

### File Path Guidelines

#### For Native Linux Users:
```bash
# Use standard Linux paths
--genome /home/user/data/genome.fasta
--outdir /home/user/results
```

#### For WSL2 Users:
```bash
# Access Windows files via /mnt/c/
--genome /mnt/c/Users/YourName/Documents/genome.fasta

# OR copy files to WSL2 first (recommended for better performance)
cp /mnt/c/Users/YourName/Documents/genome.fasta ~/genome.fasta
--genome ~/genome.fasta
```

## 📋 System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 18.04+, CentOS 7+, or similar) OR Windows 10/11 with WSL2
- **RAM**: 16 GB
- **CPU**: 8 cores
- **Storage**: 100 GB free space
- **Internet**: For downloading containers (~5 GB total)

### Recommended Requirements
- **RAM**: 64 GB
- **CPU**: 32 cores  
- **Storage**: 500 GB SSD
- **Internet**: High-speed for faster container downloads

### For Large Genomes (>5 GB)
- **RAM**: 128+ GB
- **CPU**: 64+ cores
- **Storage**: 1+ TB
- **Runtime**: 2-7 days depending on genome size

## Parameters

### Required
- `--genome`: Path to genome FASTA file
- `--species`: Species name (used by BRAKER)

### Optional
- `--proteins`: Path to protein FASTA file for evidence
- `--rna_seq`: Path to RNA-seq data for evidence
- `--busco_db`: BUSCO lineage database (default: "auto")
  - `auto`: Automatic lineage selection
  - `bacteria_odb10`: For bacterial genomes
  - `eukaryota_odb10`: For eukaryotic genomes
  - `archaea_odb10`: For archaeal genomes
  - `fungi_odb10`: For fungal genomes
  - `plants_odb10`: For plant genomes
- `--outdir`: Output directory (default: "results")

## Execution Profiles

### Local execution with Singularity (Recommended)
```bash
nextflow run main.nf -profile singularity [params]
```

### Local execution with Docker
```bash
nextflow run main.nf -profile docker [params]
```

### Cluster execution (SLURM)
```bash
nextflow run main.nf -profile cluster [params]
```

### High-performance computing
```bash
nextflow run main.nf -profile hpc [params]
```

## 🧪 Testing the Pipeline

### Option 1: Quick Test with Synthetic Data (No Download Required)
```bash
# Create synthetic test data locally (fastest option)
./create_test_data.sh --size small

# Run quick test
nextflow run main.nf \
    --genome test/test_genome.fasta \
    --species "synthetic_test_species" \
    -c test/ultra_minimal.config \
    -profile singularity
```

### Option 2: Download Real Test Data
```bash
# Download small test genome (Lambda phage ~48KB)
./setup_test.sh --small-test

# Download full E. coli genome (~4.6MB)
./setup_test.sh

# Run validation
nextflow run validate.nf --genome test/test_genome.fasta

# Run full test
./test/run_test.sh
```

### Option 3: Manual Test Data Setup
```bash
# If you have your own small genome file
cp /path/to/your/small_genome.fasta test/test_genome.fasta

# Run validation
nextflow run validate.nf --genome test/test_genome.fasta

# Run with minimal resources
nextflow run main.nf \
    --genome test/test_genome.fasta \
    --species "your_species" \
    -c test/minimal.config \
    -profile singularity
```

### Test Data Options Summary

| Method | Size | Download | Time to Setup | Best For |
|--------|------|----------|---------------|----------|
| Synthetic | ~1KB | No | 1 minute | Quick validation, no internet |
| Lambda phage | ~48KB | Yes | 2 minutes | Small real genome testing |
| E. coli | ~4.6MB | Yes | 5 minutes | Full realistic testing |

## 📊 Monitoring Pipeline Execution

### Check Progress
```bash
# Monitor log in real-time
tail -f .nextflow.log

# Check running processes
ps aux | grep nextflow
```

### Resume Failed Runs
```bash
# Resume from last checkpoint
nextflow run main.nf \
    --genome genome.fasta \
    --species "my_species" \
    -profile singularity \
    -resume
```

## Output Structure

```
results/
├── 01_cleaned_genome/
│   ├── cleaned_genome.fasta
│   ├── header_mapping.txt
│   └── cleaning_stats.txt
├── 02_repeatmodeler/
│   ├── repeatmodeler_output/
│   ├── consensi.fa.classified
│   └── repeatmodeler.log
├── 03_repeatmasker/
│   ├── genome.masked
│   ├── *.out (repeat annotations)
│   ├── *.tbl (repeat summary)
│   └── repeatmasker.log
├── 04_braker3/
│   ├── braker_output/
│   ├── augustus.hints.gtf (gene predictions)
│   ├── augustus.hints.aa (protein sequences)
│   ├── augustus.hints.codingseq (coding sequences)
│   └── braker.log
├── 05_busco/
│   ├── busco_output/
│   ├── short_summary.*.txt (BUSCO summary)
│   ├── full_table.tsv (detailed results)
│   ├── missing_busco_list.tsv (missing orthologs)
│   └── busco.log
└── pipeline_info/
    ├── report.html
    ├── timeline.html
    ├── trace.txt
    └── dag.svg
```

## Key Output Files

- **Gene Annotation**: `04_braker3/augustus.hints.gtf`
- **Protein Sequences**: `04_braker3/augustus.hints.aa`
- **BUSCO Assessment**: `05_busco/short_summary.*.txt`
- **Masked Genome**: `03_repeatmasker/genome.masked`
- **Repeat Library**: `02_repeatmodeler/consensi.fa.classified`

## Container Images

The pipeline uses the following containers:
- **seqkit**: `biocontainers/seqkit:v2.3.1_cv1`
- **RepeatModeler/RepeatMasker**: `dfam/tetools:1.88.5`
- **BRAKER3**: `teambraker/braker3:latest`
- **BUSCO**: `ezlabgva/busco:v5.4.7_cv1`

## Resource Requirements

### Minimum
- 16 GB RAM
- 8 CPU cores
- 100 GB disk space

### Recommended
- 64 GB RAM
- 32 CPU cores
- 500 GB disk space

## Runtime Estimates

For a 1 Gb genome:
- Header cleaning: 5-10 minutes
- RepeatModeler: 12-48 hours
- RepeatMasker: 2-12 hours
- BRAKER3: 6-48 hours
- BUSCO: 1-4 hours

Total: 21-112 hours (depending on genome size and complexity)

## Troubleshooting

### Common Issues

1. **Out of memory**: Increase memory allocation in `nextflow.config`
2. **Container not found**: Ensure Singularity/Docker is properly installed
3. **Permission errors**: Check file permissions and container settings

### Logs
Check individual process logs in the output directories:
- `01_cleaned_genome/cleaning_stats.txt`
- `02_repeatmodeler/repeatmodeler.log`
- `03_repeatmasker/repeatmasker.log`
- `04_braker3/braker.log`

## Citation

If you use this pipeline, please cite:
- Nextflow: Paolo Di Tommaso, et al. Nextflow enables reproducible computational workflows. Nature Biotechnology 35, 316–319 (2017)
- RepeatModeler: Flynn, J.M., et al. RepeatModeler2 for automated genomic discovery of transposable element families. PNAS 117, 9451-9457 (2020)
- RepeatMasker: Smit, A.F.A., Hubley, R. & Green, P. RepeatMasker Open-4.0. http://www.repeatmasker.org (2013-2015)
- BRAKER3: Brůna, T., et al. BRAKER3: fully automated genome annotation using RNA-Seq and protein evidence with GeneMark-ETP, AUGUSTUS and TSEBRA. Genome Research (2023)

## Support

For issues and questions, please check:
1. Pipeline logs and error messages
2. Container documentation
3. Tool-specific documentation
