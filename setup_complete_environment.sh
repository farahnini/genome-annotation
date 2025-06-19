#!/bin/bash

# Complete environment setup with Java compatibility fix
# This script creates a full working environment for the genome annotation pipeline

set -e

echo "=== Genome Annotation Pipeline - Complete Environment Setup ==="
echo "This script will set up a complete working environment with:"
echo "- Java 17 (compatible with Nextflow)"
echo "- Nextflow (latest version)"
echo "- Singularity (for containers)"
echo "- Complete Singularity container with all tools"
echo

# Check if running on WSL2/Linux
if [[ ! "$(uname)" == "Linux" ]]; then
    echo "❌ This script requires Linux or WSL2"
    echo "If you're on Windows, please install WSL2 first:"
    echo "  wsl --install Ubuntu-22.04"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    echo "Run as regular user, script will use sudo when needed"
    exit 1
fi

# Environment setup
ENV_DIR="$HOME/.genome-annotation-env"
JAVA_DIR="$ENV_DIR/java"
NEXTFLOW_DIR="$ENV_DIR/nextflow"
SINGULARITY_CACHE="$ENV_DIR/singularity_cache"

echo "Setting up environment in: $ENV_DIR"
mkdir -p "$ENV_DIR" "$JAVA_DIR" "$NEXTFLOW_DIR" "$SINGULARITY_CACHE"

# Update shell profile function
update_shell_profile() {
    local profile_file=""
    if [ -f "$HOME/.bashrc" ]; then
        profile_file="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        profile_file="$HOME/.bash_profile"
    elif [ -f "$HOME/.profile" ]; then
        profile_file="$HOME/.profile"
    fi
    
    if [ -n "$profile_file" ]; then
        echo "Updating $profile_file..."
        
        # Remove existing settings
        sed -i '/# Genome Annotation Pipeline Environment/,/# End Genome Annotation Pipeline Environment/d' "$profile_file"
        
        # Add new settings
        cat >> "$profile_file" << EOF

# Genome Annotation Pipeline Environment
export GENOME_ANNOTATION_ENV="$ENV_DIR"
export JAVA_HOME="$JAVA_DIR/current"
export NEXTFLOW_HOME="$NEXTFLOW_DIR"
export SINGULARITY_CACHEDIR="$SINGULARITY_CACHE"
export PATH="\$JAVA_HOME/bin:\$NEXTFLOW_HOME:\$PATH"

# Java compatibility settings for Nextflow
export JAVA_OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED"
export NXF_OPTS="\$JAVA_OPTS"

# Activate genome annotation environment
alias activate-genome-annotation="source $ENV_DIR/activate.sh"
# End Genome Annotation Pipeline Environment
EOF
        echo "✓ Updated $profile_file"
    fi
}

# Step 1: Install system dependencies
echo "1. Installing system dependencies..."
sudo apt update

# Install required packages
sudo apt install -y \
    openjdk-17-jdk \
    wget \
    curl \
    git \
    unzip \
    build-essential \
    squashfs-tools \
    libseccomp-dev \
    pkg-config \
    cryptsetup

echo "✓ System dependencies installed"

# Step 2: Set up Java 17
echo "2. Setting up Java 17..."
JAVA_17_PATH=$(update-alternatives --list java | grep java-17 | head -n1 | sed 's|/bin/java||' || echo "")

if [ -z "$JAVA_17_PATH" ]; then
    # Find Java 17 manually
    JAVA_17_PATH=$(find /usr/lib/jvm -name "java-17-openjdk*" -type d | head -n1)
fi

if [ -n "$JAVA_17_PATH" ] && [ -d "$JAVA_17_PATH" ]; then
    ln -sf "$JAVA_17_PATH" "$JAVA_DIR/current"
    echo "✓ Java 17 configured: $JAVA_17_PATH"
else
    echo "❌ Could not find Java 17 installation"
    exit 1
fi

# Step 3: Install Singularity if not present
echo "3. Installing Singularity..."
if ! command -v singularity >/dev/null 2>&1; then
    # Install Singularity
    cd /tmp
    wget https://github.com/sylabs/singularity/releases/download/v3.11.4/singularity-ce_3.11.4-jammy_amd64.deb
    sudo dpkg -i singularity-ce_3.11.4-jammy_amd64.deb || sudo apt install -f -y
    rm -f singularity-ce_3.11.4-jammy_amd64.deb
    echo "✓ Singularity installed"
else
    echo "✓ Singularity already installed: $(singularity --version)"
fi

# Step 4: Install Nextflow
echo "4. Installing Nextflow..."
export JAVA_HOME="$JAVA_DIR/current"
export PATH="$JAVA_HOME/bin:$PATH"

cd "$NEXTFLOW_DIR"
if [ ! -f "nextflow" ]; then
    curl -s https://get.nextflow.io | bash
    chmod +x nextflow
fi

# Test Nextflow with Java 17
if "$NEXTFLOW_DIR/nextflow" -version >/dev/null 2>&1; then
    echo "✓ Nextflow installed and working with Java 17"
else
    echo "❌ Nextflow test failed"
    exit 1
fi

# Step 5: Create activation script
echo "5. Creating environment activation script..."
cat > "$ENV_DIR/activate.sh" << 'EOF'
#!/bin/bash
# Genome Annotation Pipeline Environment Activation

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set environment variables
export GENOME_ANNOTATION_ENV="$SCRIPT_DIR"
export JAVA_HOME="$SCRIPT_DIR/java/current"
export NEXTFLOW_HOME="$SCRIPT_DIR/nextflow"
export SINGULARITY_CACHEDIR="$SCRIPT_DIR/singularity_cache"
export PATH="$JAVA_HOME/bin:$NEXTFLOW_HOME:$PATH"

# Java compatibility for Nextflow
export JAVA_OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED"
export NXF_OPTS="$JAVA_OPTS"

echo "🧬 Genome Annotation Pipeline Environment Activated"
echo "📁 Environment: $GENOME_ANNOTATION_ENV"
echo "☕ Java: $(java -version 2>&1 | head -n1)"
echo "🔬 Nextflow: $(nextflow -version 2>&1 | head -n1)"
echo "📦 Singularity: $(singularity --version 2>&1)"
echo
echo "Usage examples:"
echo "  nextflow run main.nf --genome genome.fasta --species 'E_coli' -profile singularity"
echo "  ./manage_container.sh build    # Build complete container"
echo "  ./manage_container.sh run --genome genome.fasta --species 'E_coli'"
EOF

chmod +x "$ENV_DIR/activate.sh"

# Step 6: Create convenience scripts
echo "6. Creating convenience scripts..."

# Pipeline runner script
cat > "$ENV_DIR/run_pipeline.sh" << 'EOF'
#!/bin/bash
# Convenience script to run pipeline with proper environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/activate.sh"

# Find pipeline directory
PIPELINE_DIR=""
if [ -f "main.nf" ]; then
    PIPELINE_DIR="$(pwd)"
elif [ -f "../main.nf" ]; then
    PIPELINE_DIR="$(cd .. && pwd)"
elif [ -n "$PIPELINE_HOME" ] && [ -f "$PIPELINE_HOME/main.nf" ]; then
    PIPELINE_DIR="$PIPELINE_HOME"
else
    echo "❌ Cannot find pipeline directory (main.nf not found)"
    echo "Please run this script from the pipeline directory or set PIPELINE_HOME"
    exit 1
fi

cd "$PIPELINE_DIR"
echo "Running pipeline from: $PIPELINE_DIR"
echo "Command: nextflow run main.nf $@"
echo

nextflow run main.nf "$@"
EOF

chmod +x "$ENV_DIR/run_pipeline.sh"

# Container management script
cat > "$ENV_DIR/manage_containers.sh" << 'EOF'
#!/bin/bash
# Container management with proper environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/activate.sh"

# Find pipeline directory
PIPELINE_DIR=""
if [ -f "main.nf" ]; then
    PIPELINE_DIR="$(pwd)"
elif [ -f "../main.nf" ]; then
    PIPELINE_DIR="$(cd .. && pwd)"
elif [ -n "$PIPELINE_HOME" ] && [ -f "$PIPELINE_HOME/main.nf" ]; then
    PIPELINE_DIR="$PIPELINE_HOME"
else
    echo "❌ Cannot find pipeline directory"
    exit 1
fi

cd "$PIPELINE_DIR"
exec ./manage_container.sh "$@"
EOF

chmod +x "$ENV_DIR/manage_containers.sh"

# Step 7: Update shell profile
update_shell_profile

# Step 8: Test the environment
echo "7. Testing environment..."
source "$ENV_DIR/activate.sh"

echo "Testing Java..."
java -version

echo "Testing Nextflow..."
nextflow -version

echo "Testing Singularity..."
singularity --version

# Step 9: Create environment info
cat > "$ENV_DIR/environment_info.txt" << EOF
Genome Annotation Pipeline Environment
=====================================
Created: $(date)
System: $(uname -a)
Java: $(java -version 2>&1 | head -n1)
Nextflow: $(nextflow -version 2>&1 | head -n1)
Singularity: $(singularity --version 2>&1)

Directories:
  Environment: $ENV_DIR
  Java: $JAVA_DIR/current
  Nextflow: $NEXTFLOW_DIR
  Singularity Cache: $SINGULARITY_CACHE

Scripts:
  Activate: $ENV_DIR/activate.sh
  Run Pipeline: $ENV_DIR/run_pipeline.sh
  Manage Containers: $ENV_DIR/manage_containers.sh

Quick Start:
1. Start new shell or run: source ~/.bashrc
2. Activate environment: source $ENV_DIR/activate.sh
3. Build container: ./manage_container.sh build
4. Run test: ./test/run_test.sh
5. Run pipeline: nextflow run main.nf --genome genome.fasta --species 'species' -profile singularity

Java Compatibility:
This environment is configured to work with Java 21 by setting proper JVM options
for Nextflow compatibility.
EOF

echo
echo "🎉 Environment setup completed successfully!"
echo
echo "📁 Environment location: $ENV_DIR"
echo
echo "Next steps:"
echo "1. Start a new shell session or run: source ~/.bashrc"
echo "2. Or activate manually: source $ENV_DIR/activate.sh"
echo "3. Build the complete container: ./manage_container.sh build"
echo "4. Run tests: ./test/run_test.sh"
echo
echo "📖 Environment info saved to: $ENV_DIR/environment_info.txt"
echo
echo "🔧 Troubleshooting:"
echo "  - If Java issues persist, run: source $ENV_DIR/activate.sh"
echo "  - Check environment with: ./check_installation.sh"
echo "  - Build container with: ./manage_container.sh build"
