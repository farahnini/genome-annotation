#!/bin/bash

# Simple environment setup that works with existing Java
# This avoids complex Java management and just sets up Nextflow to work

set -e

echo "=== Genome Annotation Pipeline - Simple Setup ==="
echo "This script will:"
echo "- Use your existing Java installation"
echo "- Install/update Nextflow with compatibility settings"
echo "- Ensure Singularity is available"
echo "- Create test data"
echo

# Check if we're in the right directory
if [ ! -f "main.nf" ]; then
    echo "❌ Please run this script from the genome-annotation directory"
    exit 1
fi

# Check Java
echo "1. Checking Java installation..."
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
    JAVA_MAJOR=$(echo "$JAVA_VERSION" | awk -F. '{print $1}')
    echo "✓ Java found: $JAVA_VERSION"
    
    # Set Java compatibility options for Nextflow
    export JAVA_OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED"
    export NXF_OPTS="$JAVA_OPTS"
    
    echo "✓ Java compatibility options set"
else
    echo "❌ Java not found. Please install Java first:"
    echo "  sudo apt install -y openjdk-17-jdk"
    exit 1
fi

# Check/Install Nextflow
echo "2. Setting up Nextflow..."
if ! command -v nextflow >/dev/null 2>&1; then
    echo "Installing Nextflow..."
    curl -s https://get.nextflow.io | bash
    sudo mv nextflow /usr/local/bin/
    echo "✓ Nextflow installed"
else
    echo "✓ Nextflow already available: $(nextflow -version 2>&1 | head -n1)"
fi

# Test Nextflow with current Java
echo "Testing Nextflow compatibility..."
if nextflow -version >/dev/null 2>&1; then
    echo "✓ Nextflow works with current Java"
else
    echo "⚠️ Nextflow test failed, but continuing..."
fi

# Check/Install Singularity
echo "3. Checking Singularity..."
if command -v singularity >/dev/null 2>&1; then
    echo "✓ Singularity found: $(singularity --version)"
else
    echo "Installing Singularity..."
    sudo apt update
    sudo apt install -y singularity-ce
    echo "✓ Singularity installed"
fi

# Set up test data
echo "4. Setting up test data..."
chmod +x setup_test.sh
if [ ! -f "test/test_genome.fna" ]; then
    echo "Creating test data..."
    ./setup_test.sh --small-test
    echo "✓ Test data created"
else
    echo "✓ Test data already exists"
fi

# Create environment activation script
echo "5. Creating environment script..."
cat > activate_environment.sh << 'EOF'
#!/bin/bash
# Simple environment activation for genome annotation pipeline

# Java compatibility for Nextflow
export JAVA_OPTS="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED"
export NXF_OPTS="$JAVA_OPTS"

echo "🧬 Genome Annotation Environment Activated"
echo "☕ Java: $(java -version 2>&1 | head -n1)"
echo "🔬 Nextflow: $(nextflow -version 2>&1 | head -n1)"
echo "📦 Singularity: $(singularity --version 2>&1)"
echo
echo "Environment variables set:"
echo "  JAVA_OPTS=$JAVA_OPTS"
echo "  NXF_OPTS=$NXF_OPTS"
echo
echo "Quick start:"
echo "  ./test/run_test.sh                    # Run test"
echo "  nextflow run main.nf --genome genome.fasta --species 'species' -profile singularity"
EOF

chmod +x activate_environment.sh

# Test the setup
echo "6. Testing setup..."
source activate_environment.sh

# Run validation
if [ -f "test/validate_setup.sh" ]; then
    echo "Running validation..."
    chmod +x test/validate_setup.sh
    ./test/validate_setup.sh
fi

echo
echo "🎉 Simple setup completed!"
echo
echo "To use the pipeline:"
echo "1. Activate environment: source activate_environment.sh"
echo "2. Run test: ./test/run_test.sh"
echo "3. Use pipeline: nextflow run main.nf --genome your_genome.fasta --species 'your_species' -profile singularity"
echo
echo "If you still have Java issues, try:"
echo "  export JAVA_OPTS=\"--add-opens=java.base/java.lang=ALL-UNNAMED\""
echo "  export NXF_OPTS=\"\$JAVA_OPTS\""
