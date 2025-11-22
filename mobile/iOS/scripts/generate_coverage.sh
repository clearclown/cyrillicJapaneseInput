#!/bin/bash
#
# generate_coverage.sh
# Generates detailed code coverage report for Pismo IME
#
# Phase 4: Coverage report generation script
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="Pismo"
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=latest"
RESULT_BUNDLE="TestResults.xcresult"

echo "================================================"
echo "Pismo IME - Coverage Report Generator"
echo "================================================"
echo ""

cd "$PROJECT_DIR"

# Check if test results exist
if [ ! -d "$RESULT_BUNDLE" ]; then
    echo -e "${YELLOW}⚠️  Test results not found. Running tests first...${NC}"

    xcodebuild test \
        -project Pismo.xcodeproj \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -enableCodeCoverage YES \
        -resultBundlePath "$RESULT_BUNDLE" \
        | xcpretty

    echo -e "${GREEN}✅ Tests completed${NC}"
fi

# Generate text coverage report
echo ""
echo "Generating text coverage report..."
xcrun xccov view --report "$RESULT_BUNDLE" > coverage_report.txt

# Generate JSON coverage report
echo "Generating JSON coverage report..."
xcrun xccov view --report --json "$RESULT_BUNDLE" > coverage.json

# Generate HTML coverage report (if xcov is installed)
if command -v xcov >/dev/null 2>&1; then
    echo "Generating HTML coverage report with xcov..."
    xcov \
        --scheme "$SCHEME" \
        --minimum_coverage_percentage 80 \
        --output_directory coverage_html \
        --json_report \
        --html_report

    echo -e "${GREEN}✅ HTML report generated in coverage_html/${NC}"
else
    echo -e "${YELLOW}⚠️  xcov not installed. Install with: gem install xcov${NC}"
fi

# Parse and display coverage summary
echo ""
echo "================================================"
echo "Coverage Summary"
echo "================================================"
echo ""

# Extract coverage data
total_coverage=$(xcrun xccov view --report "$RESULT_BUNDLE" | grep "Pismo.app" | awk '{print $2}' || echo "0%")
echo -e "${BLUE}Total Coverage: $total_coverage${NC}"

# Show file-by-file coverage
echo ""
echo "File-by-file coverage:"
xcrun xccov view --report "$RESULT_BUNDLE" | grep "\.swift" | head -20

# Check coverage threshold
coverage_value=$(echo "$total_coverage" | sed 's/%//')
if (( $(echo "$coverage_value >= 80.0" | bc -l) )); then
    echo ""
    echo -e "${GREEN}✅ Coverage meets 80% threshold${NC}"
    exit_code=0
else
    echo ""
    echo -e "${RED}❌ Coverage $total_coverage is below 80% threshold${NC}"
    exit_code=1
fi

# Display uncovered files
echo ""
echo "Files with lowest coverage:"
xcrun xccov view --report "$RESULT_BUNDLE" | grep "\.swift" | sort -k2 -n | head -10

# Generate coverage badge (optional)
if command -v jq >/dev/null 2>&1; then
    echo ""
    echo "Generating coverage badge data..."

    coverage_int=$(printf "%.0f" "$coverage_value")

    if [ "$coverage_int" -ge 80 ]; then
        color="brightgreen"
    elif [ "$coverage_int" -ge 60 ]; then
        color="yellow"
    else
        color="red"
    fi

    cat > coverage_badge.json <<EOF
{
  "schemaVersion": 1,
  "label": "coverage",
  "message": "${coverage_int}%",
  "color": "$color"
}
EOF

    echo "Coverage badge data saved to coverage_badge.json"
fi

echo ""
echo "================================================"
echo "Reports generated:"
echo "  - Text: $PROJECT_DIR/coverage_report.txt"
echo "  - JSON: $PROJECT_DIR/coverage.json"
if [ -d "coverage_html" ]; then
    echo "  - HTML: $PROJECT_DIR/coverage_html/index.html"
fi
echo "================================================"
echo ""

exit $exit_code
