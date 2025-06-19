#!/bin/bash

echo "=== Genome Annotation Pipeline - Quick Start ==="
echo
echo "You have several options to fix your environment:"
echo

echo "Option 1: 🧹 Clean and retry complete setup"
echo "  chmod +x fix_environment.sh"
echo "  ./fix_environment.sh"
echo "  ./setup_complete_environment.sh"
echo

echo "Option 2: 🚀 Simple setup (recommended)"
echo "  chmod +x setup_simple.sh"
echo "  ./setup_simple.sh"
echo

echo "Option 3: 🔧 Manual fixes"
echo "  # Fix Java compatibility"
echo "  export JAVA_OPTS=\"--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED\""
echo "  export NXF_OPTS=\"\$JAVA_OPTS\""
echo "  "
echo "  # Create test data"
echo "  ./setup_test.sh --small-test"
echo "  "
echo "  # Test pipeline"
echo "  ./test/run_test.sh"
echo

echo "Option 4: 📦 Use container approach"
echo "  # Make sure you're in the right directory"
echo "  cd ~/home/farah/genome-annotation"
echo "  chmod +x manage_container.sh"
echo "  ./manage_container.sh build"
echo "  ./manage_container.sh test"
echo

echo "Current issues detected:"
echo "1. Java 21 compatibility with Nextflow (needs JVM options)"
echo "2. Container manager looking in wrong directory"
echo "3. Missing test data"
echo

echo "Recommended: Try Option 2 (Simple setup) first!"
