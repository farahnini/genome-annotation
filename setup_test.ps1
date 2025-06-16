# PowerShell script to download test data for pipeline testing

param(
    [string]$OutputDir = "test",
    [switch]$SkipDownload = $false
)

Write-Host "Setting up test data for genome annotation pipeline..." -ForegroundColor Green

# Create test directory
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force
    Write-Host "Created directory: $OutputDir" -ForegroundColor Yellow
}

if (!$SkipDownload) {
    Write-Host "Downloading test genome (E. coli K-12 MG1655)..." -ForegroundColor Yellow
    
    # Download E. coli genome from NCBI
    $genomeUrl = "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/825/GCF_000005825.2_ASM582v2/GCF_000005825.2_ASM582v2_genomic.fna.gz"
    $genomeFile = Join-Path $OutputDir "test_genome.fna.gz"
    
    try {
        Invoke-WebRequest -Uri $genomeUrl -OutFile $genomeFile -UseBasicParsing
        
        # Extract the file
        if (Get-Command "7z" -ErrorAction SilentlyContinue) {
            & 7z x $genomeFile -o"$OutputDir"
            Remove-Item $genomeFile
            Rename-Item (Join-Path $OutputDir "GCF_000005825.2_ASM582v2_genomic.fna") (Join-Path $OutputDir "test_genome.fasta")
        } else {
            Write-Warning "7-Zip not found. Please manually extract $genomeFile"
        }
        
        Write-Host "✓ Test genome downloaded" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download test genome: $_"
        Write-Host "You can manually download it from: $genomeUrl" -ForegroundColor Yellow
    }
    
    # Download some protein sequences for testing
    Write-Host "Downloading test proteins..." -ForegroundColor Yellow
    $proteinUrl = "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/825/GCF_000005825.2_ASM582v2/GCF_000005825.2_ASM582v2_protein.faa.gz"
    $proteinFile = Join-Path $OutputDir "test_proteins.faa.gz"
    
    try {
        Invoke-WebRequest -Uri $proteinUrl -OutFile $proteinFile -UseBasicParsing
        
        # Extract the file
        if (Get-Command "7z" -ErrorAction SilentlyContinue) {
            & 7z x $proteinFile -o"$OutputDir"
            Remove-Item $proteinFile
            Rename-Item (Join-Path $OutputDir "GCF_000005825.2_ASM582v2_protein.faa") (Join-Path $OutputDir "test_proteins.fasta")
        } else {
            Write-Warning "7-Zip not found. Please manually extract $proteinFile"
        }
        
        Write-Host "✓ Test proteins downloaded" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download test proteins: $_"
        Write-Host "You can manually download it from: $proteinUrl" -ForegroundColor Yellow
    }
}

# Create a test run script
$testScript = @"
# Test run for genome annotation pipeline
# This uses the downloaded E. coli genome for testing

`$GENOME_FILE = "test/test_genome.fasta"
`$PROTEIN_FILE = "test/test_proteins.fasta"
`$SPECIES_NAME = "Escherichia_coli"
`$OUTPUT_DIR = "test_results"

Write-Host "Running pipeline validation..." -ForegroundColor Yellow
nextflow run validate.nf --genome "`$GENOME_FILE"

Write-Host "Running test annotation pipeline..." -ForegroundColor Yellow
nextflow run main.nf ``
    --genome "`$GENOME_FILE" ``
    --proteins "`$PROTEIN_FILE" ``
    --species "`$SPECIES_NAME" ``
    --outdir "`$OUTPUT_DIR" ``
    -profile singularity ``
    -c test/test_data.config ``
    -resume

Write-Host "Test completed! Check results in: `$OUTPUT_DIR" -ForegroundColor Green
"@

$testScript | Out-File -FilePath (Join-Path $OutputDir "run_test.ps1") -Encoding UTF8
Write-Host "✓ Created test run script: $OutputDir/run_test.ps1" -ForegroundColor Green

# Create a minimal test configuration
$testConfig = @"
# Minimal test configuration
params {
    genome = "test/test_genome.fasta"
    proteins = "test/test_proteins.fasta"
    species = "Escherichia_coli"
    outdir = "test_results"
}

process {
    executor = 'local'
    
    withName: REPEATMODELER {
        cpus = 2
        memory = "4.GB"
        time = "30.m"
    }
    
    withName: BRAKER3 {
        cpus = 2
        memory = "4.GB"
        time = "1.h"
    }
}
"@

$testConfig | Out-File -FilePath (Join-Path $OutputDir "minimal.config") -Encoding UTF8
Write-Host "✓ Created minimal test config: $OutputDir/minimal.config" -ForegroundColor Green

Write-Host "`nTest setup complete!" -ForegroundColor Green
Write-Host "To run the test:" -ForegroundColor Yellow
Write-Host "  cd test" -ForegroundColor Cyan
Write-Host "  .\run_test.ps1" -ForegroundColor Cyan
Write-Host "`nOr run individual validation:" -ForegroundColor Yellow
Write-Host "  nextflow run validate.nf --genome test/test_genome.fasta" -ForegroundColor Cyan
