#!/bin/bash

# Quick fix script for environment setup issues

echo "=== Fixing Environment Setup Issues ==="

# Clean up partial environment
ENV_DIR="$HOME/.genome-annotation-env"
if [ -d "$ENV_DIR" ]; then
    echo "Cleaning up partial environment setup..."
    rm -rf "$ENV_DIR"
    echo "✓ Cleaned up $ENV_DIR"
fi

# Remove environment lines from shell profile
PROFILE_FILES=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
for profile in "${PROFILE_FILES[@]}"; do
    if [ -f "$profile" ]; then
        echo "Cleaning $profile..."
        sed -i '/# Genome Annotation Pipeline Environment/,/# End Genome Annotation Pipeline Environment/d' "$profile"
    fi
done

echo "✓ Environment cleanup completed"
echo
echo "Now you can run the setup script again:"
echo "  ./setup_complete_environment.sh"
echo
echo "Or try the simpler environment setup:"
echo "  ./setup_environment.sh"
