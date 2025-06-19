#!/bin/bash

# Create HPC deployment package
# Run this script to prepare files for HPC transfer

echo "=== Creating HPC Deployment Package ==="

# Set package name with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="genome-annotation-hpc-${TIMESTAMP}.tar.gz"

echo "📦 Preparing deployment package: $PACKAGE_NAME"

# Files to include
INCLUDE_FILES=(
    "main.nf"
    "nextflow.config" 
    "validate.nf"
    "activate_environment.sh"
    "HPC_DEPLOYMENT.md"
    "README.md"
    "TROUBLESHOOTING.md"
    "modules/"
    "test/"
    "conf/"
)

# Check if required files exist
echo "🔍 Checking required files..."
MISSING_FILES=()
for file in "${INCLUDE_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ Missing required files:"
    printf '  %s\n' "${MISSING_FILES[@]}"
    echo "Please ensure all files are present before creating package."
    exit 1
fi

# Create the package
echo "📦 Creating package..."
tar -czf "$PACKAGE_NAME" "${INCLUDE_FILES[@]}" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Package created successfully: $PACKAGE_NAME"
    echo "📊 Package size: $(du -h $PACKAGE_NAME | cut -f1)"
    echo
    echo "📋 Next steps:"
    echo "1. Transfer to HPC: scp $PACKAGE_NAME username@hpc:/path/to/destination/"
    echo "2. Extract on HPC: tar -xzf $PACKAGE_NAME"
    echo "3. Follow HPC_DEPLOYMENT.md for setup instructions"
else
    echo "❌ Failed to create package"
    exit 1
fi
