# PowerShell script to generate summary report from pipeline results

param(
    [Parameter(Mandatory=$true)]
    [string]$ResultsDir,
    [string]$OutputFile = "annotation_summary.html"
)

if (!(Test-Path $ResultsDir)) {
    Write-Error "Results directory not found: $ResultsDir"
    exit 1
}

Write-Host "Generating annotation summary report..." -ForegroundColor Green

# Start building HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Genome Annotation Summary</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border-left: 3px solid #007acc; }
        .stats { background-color: #f9f9f9; padding: 10px; margin: 10px 0; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .code { background-color: #f5f5f5; padding: 10px; font-family: monospace; }
    </style>
</head>
<body>
"@

$html += @"
<div class="header">
    <h1>Genome Annotation Pipeline Summary</h1>
    <p><strong>Results Directory:</strong> $ResultsDir</p>
    <p><strong>Generated:</strong> $(Get-Date)</p>
</div>
"@

# Function to safely read file content
function Get-SafeFileContent {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        try {
            return Get-Content $FilePath -Raw
        } catch {
            return "Error reading file: $_"
        }
    } else {
        return "File not found: $FilePath"
    }
}

# Function to count lines in file
function Get-LineCount {
    param([string]$FilePath, [string]$Pattern = "")
    if (Test-Path $FilePath) {
        if ($Pattern) {
            return (Select-String -Path $FilePath -Pattern $Pattern).Count
        } else {
            return (Get-Content $FilePath).Count
        }
    }
    return 0
}

# 1. Header Cleaning Results
$html += '<div class="section"><h2>1. Header Cleaning Results</h2>'

$cleaningStats = Join-Path $ResultsDir "01_cleaned_genome\cleaning_stats.txt"
if (Test-Path $cleaningStats) {
    $html += '<div class="stats">'
    $html += '<h3>Cleaning Statistics</h3>'
    $html += '<div class="code">' + [System.Web.HttpUtility]::HtmlEncode((Get-SafeFileContent $cleaningStats)) + '</div>'
    $html += '</div>'
} else {
    $html += '<p class="error">Cleaning statistics not found</p>'
}

$html += '</div>'

# 2. RepeatModeler Results
$html += '<div class="section"><h2>2. RepeatModeler Results</h2>'

$repeatmodelerLog = Join-Path $ResultsDir "02_repeatmodeler\repeatmodeler_output\repeatmodeler.log"
$consensi = Join-Path $ResultsDir "02_repeatmodeler\repeatmodeler_output\consensi.fa.classified"

if (Test-Path $consensi) {
    $repeatCount = Get-LineCount $consensi "^>"
    $html += "<p class="success">✓ RepeatModeler completed successfully</p>"
    $html += "<p><strong>Repeat families identified:</strong> $repeatCount</p>"
} else {
    $html += '<p class="error">✗ RepeatModeler output not found</p>'
}

if (Test-Path $repeatmodelerLog) {
    $logContent = Get-SafeFileContent $repeatmodelerLog
    $html += '<details><summary>RepeatModeler Log (click to expand)</summary>'
    $html += '<div class="code">' + [System.Web.HttpUtility]::HtmlEncode($logContent) + '</div>'
    $html += '</details>'
}

$html += '</div>'

# 3. RepeatMasker Results
$html += '<div class="section"><h2>3. RepeatMasker Results</h2>'

$repeatmaskerLog = Join-Path $ResultsDir "03_repeatmasker\repeatmasker.log"
$maskedGenome = Get-ChildItem -Path (Join-Path $ResultsDir "03_repeatmasker") -Filter "*.masked" | Select-Object -First 1

if ($maskedGenome) {
    $html += '<p class="success">✓ RepeatMasker completed successfully</p>'
    $html += "<p><strong>Masked genome:</strong> $($maskedGenome.Name)</p>"
} else {
    $html += '<p class="error">✗ Masked genome not found</p>'
}

# Look for repeat summary table
$tblFile = Get-ChildItem -Path (Join-Path $ResultsDir "03_repeatmasker") -Filter "*.tbl" | Select-Object -First 1
if ($tblFile) {
    $html += '<h3>Repeat Classification Summary</h3>'
    $tblContent = Get-SafeFileContent $tblFile.FullName
    $html += '<div class="code">' + [System.Web.HttpUtility]::HtmlEncode($tblContent) + '</div>'
}

if (Test-Path $repeatmaskerLog) {
    $logContent = Get-SafeFileContent $repeatmaskerLog
    $html += '<details><summary>RepeatMasker Log (click to expand)</summary>'
    $html += '<div class="code">' + [System.Web.HttpUtility]::HtmlEncode($logContent) + '</div>'
    $html += '</details>'
}

$html += '</div>'

# 4. BRAKER3 Results
$html += '<div class="section"><h2>4. BRAKER3 Results</h2>'

$brakerLog = Join-Path $ResultsDir "04_braker3\braker_output\braker.log"
$geneAnnotation = Join-Path $ResultsDir "04_braker3\braker_output\augustus.hints.gtf"
$proteinSeqs = Join-Path $ResultsDir "04_braker3\braker_output\augustus.hints.aa"

if (Test-Path $geneAnnotation) {
    $geneCount = Get-LineCount $geneAnnotation "gene"
    $html += '<p class="success">✓ BRAKER3 completed successfully</p>'
    $html += "<p><strong>Genes predicted:</strong> $geneCount</p>"
    
    if (Test-Path $proteinSeqs) {
        $proteinCount = Get-LineCount $proteinSeqs "^>"
        $html += "<p><strong>Proteins predicted:</strong> $proteinCount</p>"
    }
} else {
    $html += '<p class="error">✗ Gene annotation not found</p>'
}

if (Test-Path $brakerLog) {
    $logContent = Get-SafeFileContent $brakerLog
    $html += '<details><summary>BRAKER3 Log (click to expand)</summary>'
    $html += '<div class="code">' + [System.Web.HttpUtility]::HtmlEncode($logContent) + '</div>'
    $html += '</details>'
}

$html += '</div>'

# 5. BUSCO Results
$html += '<div class="section"><h2>5. BUSCO Quality Assessment</h2>'

$buscoSummary = Get-ChildItem -Path (Join-Path $ResultsDir "05_busco") -Filter "short_summary*.txt" | Select-Object -First 1
$buscoLog = Join-Path $ResultsDir "05_busco\busco_output\busco.log"

if ($buscoSummary) {
    $html += '<p class="success">✓ BUSCO analysis completed successfully</p>'
    $html += "<p><strong>Summary file:</strong> $($buscoSummary.Name)</p>"
    
    # Parse BUSCO results
    $summaryContent = Get-SafeFileContent $buscoSummary.FullName
    if ($summaryContent -match "Complete BUSCOs.*\((\d+\.\d+)%\)") {
        $completePercent = $matches[1]
        $html += "<p><strong>Complete BUSCOs:</strong> $completePercent%</p>"
        
        # Quality assessment
        $complete = [double]$completePercent
        if ($complete -ge 90) {
            $html += '<p class="success"><strong>Quality Assessment:</strong> Excellent (≥90% complete)</p>'
        } elseif ($complete -ge 70) {
            $html += '<p style="color: orange;"><strong>Quality Assessment:</strong> Good (70-89% complete)</p>'
        } elseif ($complete -ge 50) {
            $html += '<p style="color: orange;"><strong>Quality Assessment:</strong> Fair (50-69% complete)</p>'
        } else {
            $html += '<p class="error"><strong>Quality Assessment:</strong> Poor (<50% complete)</p>'
        }
    }
    
    # Display BUSCO summary
    $html += '<h3>BUSCO Summary Report</h3>'
    $html += '<div class="code">' + [System.Web.HttpUtility]::HtmlEncode($summaryContent) + '</div>'
} else {
    $html += '<p class="error">✗ BUSCO analysis not found</p>'
}

if (Test-Path $buscoLog) {
    $logContent = Get-SafeFileContent $buscoLog
    $html += '<details><summary>BUSCO Log (click to expand)</summary>'
    $html += '<div class="code">' + [System.Web.HttpUtility]::HtmlEncode($logContent) + '</div>'
    $html += '</details>'
}

$html += '</div>'

# 6. Pipeline Information
$html += '<div class="section"><h2>6. Pipeline Information</h2>'

$reportFile = Join-Path $ResultsDir "pipeline_info\report.html"
$timelineFile = Join-Path $ResultsDir "pipeline_info\timeline.html"

if (Test-Path $reportFile) {
    $html += '<p><a href="' + (Resolve-Path $reportFile).Path + '">View detailed pipeline report</a></p>'
}

if (Test-Path $timelineFile) {
    $html += '<p><a href="' + (Resolve-Path $timelineFile).Path + '">View execution timeline</a></p>'
}

$html += '</div>'

# 7. Output Files Summary
$html += '<div class="section"><h2>7. Output Files Summary</h2>'
$html += '<table>'
$html += '<tr><th>File Type</th><th>Location</th><th>Status</th></tr>'

$outputFiles = @(
    @("Cleaned Genome", "01_cleaned_genome\cleaned_*.fasta", ""),
    @("Repeat Library", "02_repeatmodeler\repeatmodeler_output\consensi.fa.classified", ""),
    @("Masked Genome", "03_repeatmasker\*.masked", ""),
    @("Gene Annotation (GTF)", "04_braker3\braker_output\augustus.hints.gtf", ""),
    @("Protein Sequences", "04_braker3\braker_output\augustus.hints.aa", ""),
    @("Coding Sequences", "04_braker3\braker_output\augustus.hints.codingseq", ""),
    @("BUSCO Summary", "05_busco\short_summary*.txt", ""),
    @("BUSCO Full Table", "05_busco\full_table.tsv", "")
)

foreach ($file in $outputFiles) {
    $filePath = Join-Path $ResultsDir $file[1]
    $exists = Get-ChildItem -Path $filePath -ErrorAction SilentlyContinue
    $status = if ($exists) { '<span class="success">✓ Present</span>' } else { '<span class="error">✗ Missing</span>' }
    
    $html += "<tr><td>$($file[0])</td><td>$($file[1])</td><td>$status</td></tr>"
}

$html += '</table>'
$html += '</div>'

# Close HTML
$html += '</body></html>'

# Write the report
$outputPath = Join-Path (Get-Location) $OutputFile
$html | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "✓ Summary report generated: $outputPath" -ForegroundColor Green
Write-Host "Open the file in a web browser to view the report." -ForegroundColor Yellow

# Optionally open the report
$response = Read-Host "Open the report now? (y/N)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Start-Process $outputPath
}
