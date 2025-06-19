#!/bin/bash

# Comprehensive environment setup for genome annotation pipeline
# This script sets up the complete environment with proper Java version management

set -e

echo "=== Genome Annotation Pipeline Environment Setup ==="
echo "Date: $(date)"
echo "System: $(uname -a)"
echo

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    echo "Run as regular user, script will use sudo when needed"
    exit 1
fi

# Create environment directory
ENV_DIR="$HOME/.genome-annotation-env"
JAVA_HOME_DIR="$ENV_DIR/java"
NEXTFLOW_HOME="$ENV_DIR/nextflow"

echo "Setting up environment in: $ENV_DIR"
mkdir -p "$ENV_DIR"
mkdir -p "$JAVA_HOME_DIR"
mkdir -p "$NEXTFLOW_HOME"

# Function to add to PATH if not already there
add_to_path() {
    local new_path="$1"
    if [[ ":$PATH:" != *":$new_path:"* ]]; then
        export PATH="$new_path:$PATH"
    fi
}

# Function to update shell profile
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
        echo "Updating $profile_file with environment settings..."
        
        # Remove existing genome-annotation environment settings
        sed -i '/# Genome Annotation Pipeline Environment/,/# End Genome Annotation Pipeline Environment/d' "$profile_file"
        
        # Add new environment settings
        cat >> "$profile_file" << EOF

# Genome Annotation Pipeline Environment
export GENOME_ANNOTATION_ENV="$ENV_DIR"
export JAVA_HOME="$JAVA_HOME_DIR/current"
export NEXTFLOW_HOME="$NEXTFLOW_HOME"
export PATH="\$JAVA_HOME/bin:\$NEXTFLOW_HOME:\$PATH"
# End Genome Annotation Pipeline Environment
EOF
        echo "✓ Updated $profile_file"
    fi
}

# 1. Install system dependencies
echo "1. Installing system dependencies..."
sudo apt update

# Install Java 17 (compatible with Nextflow)
echo "Installing Java 17..."
sudo apt install -y openjdk-17-jdk wget curl

# Set up Java environment
JAVA_17_PATH=$(update-alternatives --list java | grep java-17 | head -n1 | sed 's|/bin/java||')
if [ -n "$JAVA_17_PATH" ]; then
    ln -sf "$JAVA_17_PATH" "$JAVA_HOME_DIR/current"
    echo "✓ Java 17 set up at $JAVA_HOME_DIR/current"
else
    echo "❌ Could not find Java 17 installation"
    exit 1
fi

# Install Singularity
echo "Installing Singularity..."
if ! command -v singularity >/dev/null 2>&1; then
    # Install dependencies for Singularity
    sudo apt install -y \
        build-essential \
        libssl-dev \
        uuid-dev \
        libgpgme11-dev \
        squashfs-tools \
        libseccomp-dev \
        pkg-config \
        cryptsetup
    
    # Install Go (required for Singularity)
    if ! command -v go >/dev/null 2>&1; then
        wget -O /tmp/go.tar.gz https://go.dev/dl/go1.19.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        export PATH=/usr/local/go/bin:$PATH
    fi
    
    # Install Singularity from source (latest stable)
    cd /tmp
    wget https://github.com/sylabs/singularity/releases/download/v3.11.4/singularity-ce-3.11.4.tar.gz
    tar -xzf singularity-ce-3.11.4.tar.gz
    cd singularity-ce-3.11.4
    
    ./mconfig --prefix=/usr/local/singularity
    make -C builddir
    sudo make -C builddir install
    
    # Add Singularity to PATH
    sudo ln -sf /usr/local/singularity/bin/singularity /usr/local/bin/singularity
    
    echo "✓ Singularity installed"
else
    echo "✓ Singularity already installed"
fi

# 2. Install Nextflow with proper Java
echo "2. Installing Nextflow..."
export JAVA_HOME="$JAVA_HOME_DIR/current"
export PATH="$JAVA_HOME/bin:$PATH"

# Download and install Nextflow
cd "$NEXTFLOW_HOME"
if [ ! -f "nextflow" ]; then
    curl -s https://get.nextflow.io | bash
    chmod +x nextflow
    echo "✓ Nextflow installed"
else
    echo "✓ Nextflow already exists"
fi

# Test Nextflow with correct Java
if "$NEXTFLOW_HOME/nextflow" -version >/dev/null 2>&1; then
    echo "✓ Nextflow works with Java 17"
else
    echo "❌ Nextflow test failed"
    exit 1
fi

# 3. Create Singularity cache directory
echo "3. Setting up Singularity cache..."
SINGULARITY_CACHE="$ENV_DIR/singularity_cache"
mkdir -p "$SINGULARITY_CACHE"
export SINGULARITY_CACHEDIR="$SINGULARITY_CACHE"

# 4. Update shell profile
update_shell_profile

# 5. Create environment activation script
cat > "$ENV_DIR/activate.sh" << 'EOF'
#!/bin/bash
# Genome Annotation Pipeline Environment Activation Script

export GENOME_ANNOTATION_ENV="$(dirname "$0")"
export JAVA_HOME="$GENOME_ANNOTATION_ENV/java/current"
export NEXTFLOW_HOME="$GENOME_ANNOTATION_ENV/nextflow"
export SINGULARITY_CACHEDIR="$GENOME_ANNOTATION_ENV/singularity_cache"
export PATH="$JAVA_HOME/bin:$NEXTFLOW_HOME:$PATH"

echo "Genome Annotation Pipeline Environment Activated"
echo "Java: $(java -version 2>&1 | head -n1)"
echo "Nextflow: $(nextflow -version 2>&1 | head -n1)"
echo "Singularity: $(singularity --version 2>&1)"
EOF

chmod +x "$ENV_DIR/activate.sh"

# 6. Create convenience scripts
cat > "$ENV_DIR/run_pipeline.sh" << 'EOF'
#!/bin/bash
# Convenience script to run the pipeline with proper environment

# Activate environment
source "$(dirname "$0")/activate.sh"

# Change to pipeline directory if provided
if [ -n "$PIPELINE_DIR" ]; then
    cd "$PIPELINE_DIR"
fi

# Run the pipeline with provided arguments
nextflow run main.nf "$@"
EOF

chmod +x "$ENV_DIR/run_pipeline.sh"

# 7. Test the environment
echo "4. Testing environment..."
source "$ENV_DIR/activate.sh"

echo "Testing Java..."
java -version

echo "Testing Nextflow..."
nextflow -version

echo "Testing Singularity..."
singularity --version

echo "Testing container pull..."
if timeout 60 singularity pull --force docker://hello-world >/dev/null 2>&1; then
    echo "✓ Container download test passed"
    rm -f hello-world_latest.sif
else
    echo "⚠️  Container download test failed (check internet connection)"
fi

# 8. Create environment info file
cat > "$ENV_DIR/environment_info.txt" << EOF
Genome Annotation Pipeline Environment
=====================================
Created: $(date)
System: $(uname -a)
Java: $(java -version 2>&1 | head -n1)
Nextflow: $(nextflow -version 2>&1 | head -n1)
Singularity: $(singularity --version 2>&1)

Environment Directory: $ENV_DIR
Java Home: $JAVA_HOME_DIR/current
Nextflow Home: $NEXTFLOW_HOME
Singularity Cache: $SINGULARITY_CACHE

To activate this environment:
source $ENV_DIR/activate.sh

To run the pipeline:
$ENV_DIR/run_pipeline.sh --genome your_genome.fasta --species "your_species" -profile singularity
EOF

echo
echo "🎉 Environment setup completed successfully!"
echo
echo "Environment location: $ENV_DIR"
echo
echo "To use the environment:"
echo "1. Start a new shell session or run: source ~/.bashrc"
echo "2. Or manually activate: source $ENV_DIR/activate.sh"
echo
echo "To run the pipeline:"
echo "$ENV_DIR/run_pipeline.sh --genome your_genome.fasta --species 'your_species' -profile singularity"
echo
echo "Environment info saved to: $ENV_DIR/environment_info.txt"
