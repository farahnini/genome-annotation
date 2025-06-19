#!/bin/bash

# Comprehensive installation check for genome annotation pipeline
# This script verifies all prerequisites are properly installed

echo "=== Genome Annotation Pipeline Installation Check ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "System: $(uname -a)"
echo

ERRORS=0

# Function to check command existence
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✓ $name found: $($cmd --version 2>&1 | head -n1 || $cmd -version 2>&1 | head -n1 || echo "Version info not available")"
    else
        echo "❌ $name not found"
        echo "   Install with: $install_hint"
        ERRORS=$((ERRORS + 1))
    fi
}

# Check operating system
echo "1. Operating System Check:"
if [[ "$(uname)" == "Linux" ]]; then
    echo "✓ Running on Linux"
    if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "  ℹ️  Detected WSL2 environment"
    fi
else
    echo "❌ Not running on Linux"
    echo "   This pipeline requires Linux or WSL2"
    ERRORS=$((ERRORS + 1))
fi
echo

# Check Java version first (critical for Nextflow)
echo "2. Java Version Check:"
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
    JAVA_MAJOR=$(echo "$JAVA_VERSION" | awk -F. '{print $1}')
    echo "✓ Java found: $JAVA_VERSION"
    
    if [ "$JAVA_MAJOR" -eq 11 ] || [ "$JAVA_MAJOR" -eq 17 ]; then
        echo "✓ Java version is compatible with Nextflow"
    elif [ "$JAVA_MAJOR" -eq 8 ]; then
        echo "⚠️  Java 8 detected - may work but Java 11+ recommended"
    elif [ "$JAVA_MAJOR" -ge 18 ]; then
        echo "❌ Java $JAVA_MAJOR detected - Nextflow requires Java 11 or 17"
        echo "   Install Java 17: sudo apt install -y openjdk-17-jdk"
        echo "   Set JAVA_HOME: export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
        ERRORS=$((ERRORS + 1))
    else
        echo "⚠️  Unusual Java version detected"
    fi
else
    echo "❌ Java not found"
    echo "   Install Java 17: sudo apt install -y openjdk-17-jdk"
    ERRORS=$((ERRORS + 1))
fi
echo

# Check required tools
echo "3. Required Tools Check:"
check_command "nextflow" "Nextflow" "curl -s https://get.nextflow.io | bash && sudo mv nextflow /usr/local/bin/"
check_command "singularity" "Singularity" "sudo apt install -y singularity-ce"

# Check alternative container runtime
if ! command -v singularity >/dev/null 2>&1; then
    check_command "apptainer" "Apptainer" "sudo apt install -y apptainer"
fi

if ! command -v singularity >/dev/null 2>&1 && ! command -v apptainer >/dev/null 2>&1; then
    check_command "docker" "Docker" "sudo apt install -y docker.io && sudo usermod -aG docker \$USER"
fi
echo

# Check system resources
echo "4. System Resources Check:"
MEMORY_GB=$(free -g | awk '/^Mem:/ {print $2}')
CPU_CORES=$(nproc)
DISK_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')

echo "Available Memory: ${MEMORY_GB}GB"
echo "CPU Cores: ${CPU_CORES}"
echo "Available Disk Space: ${DISK_GB}GB"

if [ "$MEMORY_GB" -lt 8 ]; then
    echo "⚠️  Warning: Less than 8GB RAM available. Consider using minimal config."
    if [ "$MEMORY_GB" -lt 4 ]; then
        echo "❌ Less than 4GB RAM. Pipeline may fail."
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "✓ Sufficient memory available"
fi

if [ "$CPU_CORES" -lt 2 ]; then
    echo "⚠️  Warning: Less than 2 CPU cores available"
else
    echo "✓ Sufficient CPU cores available"
fi

if [ "$DISK_GB" -lt 10 ]; then
    echo "❌ Less than 10GB disk space available"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Sufficient disk space available"
fi
echo

# Check internet connectivity for container downloads
echo "5. Container Access Check:"
if command -v singularity >/dev/null 2>&1; then
    echo "Testing Singularity container access..."
    if timeout 30 singularity pull --force docker://hello-world >/dev/null 2>&1; then
        echo "✓ Singularity can download containers"
        rm -f hello-world_latest.sif 2>/dev/null
    else
        echo "❌ Singularity cannot download containers"
        echo "   Check internet connection or proxy settings"
        ERRORS=$((ERRORS + 1))
    fi
elif command -v docker >/dev/null 2>&1; then
    echo "Testing Docker container access..."
    if timeout 30 docker pull hello-world >/dev/null 2>&1; then
        echo "✓ Docker can download containers"
        docker rmi hello-world >/dev/null 2>&1
    else
        echo "❌ Docker cannot download containers"
        echo "   Check Docker daemon is running: sudo systemctl start docker"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo

# Check pipeline files
echo "6. Pipeline Files Check:"
REQUIRED_FILES=("main.nf" "nextflow.config" "validate.nf" "setup_test.sh")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file found"
    else
        echo "❌ $file not found"
        ERRORS=$((ERRORS + 1))
    fi
done

if [ -d "modules" ]; then
    echo "✓ modules directory found"
    MODULE_COUNT=$(find modules -name "*.nf" | wc -l)
    echo "  Found $MODULE_COUNT module files"
else
    echo "❌ modules directory not found"
    ERRORS=$((ERRORS + 1))
fi
echo

# Check test setup
echo "7. Test Setup Check:"
if [ -f "test/test_genome.fna" ] && [ -f "test/test_proteins.faa" ]; then
    echo "✓ Test data files found"
    GENOME_SIZE=$(du -h test/test_genome.fna | cut -f1)
    PROTEIN_SIZE=$(du -h test/test_proteins.faa | cut -f1)
    echo "  Genome file size: $GENOME_SIZE"
    echo "  Protein file size: $PROTEIN_SIZE"
else
    echo "⚠️  Test data files not found"
    echo "   Run: ./setup_test.sh --small-test"
fi

if [ -f "test/test_data.config" ]; then
    echo "✓ Test configuration found"
else
    echo "❌ Test configuration not found"
    echo "   Run: ./setup_test.sh --small-test"
    ERRORS=$((ERRORS + 1))
fi
echo

# Summary
echo "8. Installation Summary:"
if [ $ERRORS -eq 0 ]; then
    echo "🎉 Installation check PASSED! You're ready to run the pipeline."
    echo
    echo "Next steps:"
    echo "1. Run test: ./test/run_test.sh"
    echo "2. Or run with your data: nextflow run main.nf --genome your_genome.fasta --species 'your_species' -profile singularity"
else
    echo "❌ Installation check FAILED with $ERRORS error(s)."
    echo
    echo "Please fix the errors above before running the pipeline."
    echo "See TROUBLESHOOTING.md for detailed solutions."
fi
echo
echo "Installation check completed at $(date)"
