# PowerShell utility script for managing genome annotation pipeline

param(
    [Parameter(Position=0)]
    [ValidateSet("run", "validate", "test", "monitor", "summary", "clean", "help")]
    [string]$Action = "help",
    
    [string]$Genome,
    [string]$Proteins,    [string]$RnaSeq,
    [string]$Species = "unknown_species",
    [string]$BuscoDb = "auto",
    [string]$OutDir = "results",
    [string]$Profile = "singularity",
    [string]$Config,
    [switch]$Resume,
    [switch]$DryRun
)

function Show-Help {
    Write-Host @"
Genome Annotation Pipeline Management Script
==========================================

Usage: .\pipeline_manager.ps1 <action> [options]

Actions:
  run       - Run the full annotation pipeline
  validate  - Validate input files and environment
  test      - Run pipeline with test data
  monitor   - Monitor running pipeline
  summary   - Generate summary report from results
  clean     - Clean up work directories
  help      - Show this help message

Options:
  -Genome <path>     Path to genome FASTA file  -Proteins <path>   Path to protein FASTA file (optional)
  -RnaSeq <path>     Path to RNA-seq data (optional)
  -Species <name>    Species name for annotation
  -BuscoDb <db>      BUSCO lineage database (auto, bacteria_odb10, eukaryota_odb10, etc.)
  -OutDir <path>     Output directory (default: results)
  -Profile <name>    Execution profile (singularity, docker, cluster)
  -Config <path>     Custom configuration file
  -Resume           Resume previous run
  -DryRun           Show commands without executing

Examples:
  .\pipeline_manager.ps1 run -Genome genome.fasta -Species "my_species"
  .\pipeline_manager.ps1 run -Genome genome.fasta -Species "my_species" -BuscoDb "eukaryota_odb10"
  .\pipeline_manager.ps1 validate -Genome genome.fasta
  .\pipeline_manager.ps1 test
  .\pipeline_manager.ps1 summary -OutDir results
"@ -ForegroundColor Green
}

function Test-Dependencies {
    Write-Host "Checking dependencies..." -ForegroundColor Yellow
    
    $issues = @()
    
    # Check Nextflow
    try {
        $nfVersion = & nextflow -version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Nextflow available" -ForegroundColor Green
        } else {
            $issues += "Nextflow not found or not working"
        }
    } catch {
        $issues += "Nextflow not found"
    }
    
    # Check container runtime
    $containerRuntime = $false
    
    try {
        & singularity --version 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Singularity available" -ForegroundColor Green
            $containerRuntime = $true
        }
    } catch { }
    
    try {
        & docker --version 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Docker available" -ForegroundColor Green
            $containerRuntime = $true
        }
    } catch { }
    
    if (!$containerRuntime) {
        $issues += "No container runtime found (need Singularity or Docker)"
    }
    
    return $issues
}

function Invoke-Pipeline {
    param([string[]]$Args)
    
    if ($DryRun) {
        Write-Host "Would execute: nextflow $($Args -join ' ')" -ForegroundColor Cyan
        return
    }
    
    Write-Host "Executing: nextflow $($Args -join ' ')" -ForegroundColor Yellow
    & nextflow @Args
}

switch ($Action) {
    "run" {
        if (!$Genome) {
            Write-Error "Genome file is required for run action. Use -Genome parameter."
            exit 1
        }
        
        if (!(Test-Path $Genome)) {
            Write-Error "Genome file not found: $Genome"
            exit 1
        }
        
        $issues = Test-Dependencies
        if ($issues.Count -gt 0) {
            Write-Error "Dependencies issues found:"
            $issues | ForEach-Object { Write-Error "  - $_" }
            exit 1
        }
        
        $args = @("run", "main.nf")        $args += "--genome", $Genome
        $args += "--species", $Species
        $args += "--busco_db", $BuscoDb
        $args += "--outdir", $OutDir
        $args += "-profile", $Profile
        
        if ($Proteins) { $args += "--proteins", $Proteins }
        if ($RnaSeq) { $args += "--rna_seq", $RnaSeq }
        if ($Config) { $args += "-c", $Config }
        if ($Resume) { $args += "-resume" }
        
        Invoke-Pipeline $args
    }
    
    "validate" {
        if (!$Genome) {
            Write-Error "Genome file is required for validation. Use -Genome parameter."
            exit 1
        }
        
        $args = @("run", "validate.nf", "--genome", $Genome)
        if ($Config) { $args += "-c", $Config }
        
        Invoke-Pipeline $args
    }
    
    "test" {
        Write-Host "Setting up and running test..." -ForegroundColor Yellow
        
        # Setup test data if needed
        if (!(Test-Path "test\test_genome.fasta")) {
            Write-Host "Test data not found. Setting up..." -ForegroundColor Yellow
            .\setup_test.ps1
        }
        
        $args = @("run", "main.nf")
        $args += "-c", "test\test_data.config"
        $args += "-profile", $Profile
        if ($Resume) { $args += "-resume" }
        
        Invoke-Pipeline $args
    }
    
    "monitor" {
        if (Test-Path ".nextflow.log") {
            Write-Host "Monitoring pipeline execution..." -ForegroundColor Yellow
            Get-Content ".nextflow.log" -Wait -Tail 20
        } else {
            Write-Host "No active pipeline found (.nextflow.log not present)" -ForegroundColor Red
        }
    }
    
    "summary" {
        if (!$OutDir) {
            Write-Error "Output directory is required for summary. Use -OutDir parameter."
            exit 1
        }
        
        if (!(Test-Path $OutDir)) {
            Write-Error "Results directory not found: $OutDir"
            exit 1
        }
        
        .\scripts\generate_summary.ps1 -ResultsDir $OutDir
    }
    
    "clean" {
        Write-Host "Cleaning up work directories..." -ForegroundColor Yellow
        
        $cleanItems = @("work", ".nextflow*", "trace.txt", "timeline.html", "report.html", "dag.svg")
        
        foreach ($item in $cleanItems) {
            if (Test-Path $item) {
                Write-Host "Removing: $item" -ForegroundColor Red
                Remove-Item $item -Recurse -Force
            }
        }
        
        Write-Host "Cleanup completed" -ForegroundColor Green
    }
    
    "help" {
        Show-Help
    }
    
    default {
        Write-Error "Unknown action: $Action"
        Show-Help
        exit 1
    }
}
