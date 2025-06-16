# Genome Annotation Pipeline

**Complete genome annotation in 3 steps: RepeatModeler → RepeatMasker → BRAKER3 → BUSCO**

## 🚀 Quick Start

**Linux/WSL2 only** (Windows users: install WSL2 first)

```bash
# 1. Install Nextflow & Singularity (one time only)
curl -s https://get.nextflow.io | bash && sudo mv nextflow /usr/local/bin/
sudo apt install -y singularity-ce

# 2. Get pipeline
git clone https://github.com/farahnini/genome-annotation.git
cd genome-annotation

# 3. Run it!
nextflow run main.nf --genome your_genome.fasta --species "your_species" -profile singularity
```

That's it! 🎉

## 📁 Results

```
results/
├── augustus.hints.gtf      # ← Your gene annotations (main result!)
├── augustus.hints.aa       # ← Predicted proteins  
├── busco_summary.txt       # ← Quality report
└── genome.masked           # ← Repeat-masked genome
```

## 🧪 Test First

```bash
# Test with small data (~5 min)
./setup_test.sh --small-test
nextflow run main.nf --genome test/test_genome.fasta --species "test" -profile singularity
```

## ⚙️ Common Options

```bash
# Basic (genome only)
nextflow run main.nf --genome genome.fa --species "E_coli" -profile singularity

# With protein evidence (better results)  
nextflow run main.nf --genome genome.fa --proteins proteins.fa --species "E_coli" -profile singularity

# Custom output location
nextflow run main.nf --genome genome.fa --species "E_coli" --outdir my_results -profile singularity
```

## ❓ Problems?

| Issue | Solution |
|-------|----------|
| Windows | Install WSL2: `wsl --install` |
| Out of memory | Edit `nextflow.config`, reduce CPU/memory |
| Can't download containers | Check internet or use `--offline` mode |
| Pipeline stuck | Check `.nextflow.log` for errors |

## What This Pipeline Does

1. **Clean headers** - Fixes FASTA sequence names
2. **RepeatModeler** - Finds repetitive DNA (12-48 hours)  
3. **RepeatMasker** - Masks repeats (2-12 hours)
4. **BRAKER3** - Predicts genes (6-48 hours)
5. **BUSCO** - Checks annotation quality (1-4 hours)

**Total time**: ~1-4 days for typical genomes

## Requirements

- Linux or WSL2
- 16+ GB RAM (64 GB recommended)
- 100+ GB disk space
- Internet (for containers)
