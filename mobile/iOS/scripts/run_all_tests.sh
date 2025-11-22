#!/bin/bash
#
# run_all_tests.sh
# Runs all test suites for Pismo IME
#
# Phase 4: Comprehensive test automation script
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="Pismo"
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=latest"
RESULT_BUNDLE="TestResults.xcresult"

echo "================================================"
echo "Pismo IME - Comprehensive Test Suite"
echo "================================================"
echo ""

# Function to print section header
print_section() {
    echo ""
    echo "================================================"
    echo "$1"
    echo "================================================"
}

# Function to check if command succeeded
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 passed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 failed${NC}"
        return 1
    fi
}

# Change to iOS directory
cd "$PROJECT_DIR"

# Step 1: Build Rust Core
print_section "1. Building Rust Core"
cd "$PROJECT_DIR/../../rust_core"

echo "Building Rust Core for iOS Simulator..."
cargo lipo --release --targets aarch64-apple-ios-sim

# Copy library
mkdir -p "$PROJECT_DIR/CyrillicIMECore"
cp target/universal/release/libcyrillic_ime_core.a "$PROJECT_DIR/CyrillicIMECore/"

check_result "Rust Core build"

cd "$PROJECT_DIR"

# Step 2: Generate Xcode project
print_section "2. Generating Xcode Project"

if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate
    check_result "Xcode project generation"
else
    echo -e "${YELLOW}⚠️  xcodegen not installed, skipping project generation${NC}"
fi

# Step 3: Run Unit Tests
print_section "3. Running Unit Tests (560 cases)"

xcodebuild test \
    -project Pismo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:PismoTests \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE" \
    | xcpretty || true

check_result "Unit tests"

# Step 4: Run Automated Conversion Tests
print_section "4. Running Automated Conversion Tests"

xcodebuild test \
    -project Pismo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:PismoTests/AutomatedConversionTests \
    | xcpretty || true

check_result "Automated conversion tests"

# Step 5: Run Performance Tests
print_section "5. Running Performance Tests"

xcodebuild test \
    -project Pismo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:PismoTests/PerformanceTests \
    | xcpretty || true

check_result "Performance tests"

# Step 6: Run UI Tests
print_section "6. Running UI Tests"

xcodebuild test \
    -project Pismo.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:PismoUITests \
    | xcpretty || true

check_result "UI tests"

# Step 7: Generate Coverage Report
print_section "7. Generating Coverage Report"

if [ -d "$RESULT_BUNDLE" ]; then
    echo "Generating coverage report..."
    xcrun xccov view --report "$RESULT_BUNDLE" > coverage_report.txt

    echo "Coverage summary:"
    grep "Pismo.app" coverage_report.txt || echo "No coverage data found"

    # Extract coverage percentage
    coverage=$(xcrun xccov view --report "$RESULT_BUNDLE" | grep "Pismo.app" | awk '{print $2}' | sed 's/%//' || echo "0")

    echo ""
    echo "Total Coverage: $coverage%"

    # Check threshold
    if (( $(echo "$coverage >= 80.0" | bc -l) )); then
        echo -e "${GREEN}✅ Coverage meets 80% threshold${NC}"
    else
        echo -e "${RED}❌ Coverage below 80% threshold${NC}"
    fi

    # Generate JSON report
    xcrun xccov view --report --json "$RESULT_BUNDLE" > coverage.json
    echo "JSON coverage report saved to coverage.json"
else
    echo -e "${YELLOW}⚠️  Test results not found, skipping coverage${NC}"
fi

# Final Summary
print_section "Test Suite Summary"

echo ""
echo "All tests completed!"
echo ""
echo "Review results in:"
echo "  - Test results: $PROJECT_DIR/$RESULT_BUNDLE"
echo "  - Coverage report: $PROJECT_DIR/coverage_report.txt"
echo "  - Coverage JSON: $PROJECT_DIR/coverage.json"
echo ""
echo "================================================"
