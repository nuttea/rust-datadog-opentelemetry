#!/bin/bash
set -e

echo "=========================================="
echo "  Security Audit for Rust Datadog OTEL"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}❌ Cargo not found. Please install Rust.${NC}"
    exit 1
fi

echo "✅ Cargo found: $(cargo --version)"
echo "✅ Rust version: $(rustc --version)"
echo ""

# Install cargo-audit if not present
echo "Checking for cargo-audit..."
if ! command -v cargo-audit &> /dev/null; then
    echo -e "${YELLOW}⚠️  cargo-audit not found. Installing...${NC}"
    cargo install cargo-audit
else
    echo "✅ cargo-audit found: $(cargo-audit --version)"
fi
echo ""

# Run security audit
echo "=========================================="
echo "  Running Security Audit"
echo "=========================================="
echo ""

if cargo audit; then
    echo -e "${GREEN}✅ No known vulnerabilities found!${NC}"
else
    echo -e "${RED}❌ Security vulnerabilities detected!${NC}"
    echo ""
    echo "Please review the vulnerabilities above and take action:"
    echo "  1. Update affected dependencies"
    echo "  2. Check if vulnerability applies to your usage"
    echo "  3. Apply patches or workarounds if available"
    echo "  4. Update SECURITY.md with findings"
    exit 1
fi
echo ""

# Check for outdated dependencies
echo "=========================================="
echo "  Checking for Outdated Dependencies"
echo "=========================================="
echo ""

if command -v cargo-outdated &> /dev/null; then
    cargo outdated
else
    echo -e "${YELLOW}⚠️  cargo-outdated not installed. Install with:${NC}"
    echo "    cargo install cargo-outdated"
fi
echo ""

# Check Rust version
echo "=========================================="
echo "  Rust Version Check"
echo "=========================================="
echo ""

RUST_VERSION=$(rustc --version | cut -d' ' -f2)
REQUIRED_VERSION="1.84.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$RUST_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
    echo -e "${GREEN}✅ Rust version $RUST_VERSION meets minimum requirement ($REQUIRED_VERSION)${NC}"
else
    echo -e "${RED}❌ Rust version $RUST_VERSION is below minimum requirement ($REQUIRED_VERSION)${NC}"
    echo "    Please update Rust: rustup update"
fi
echo ""

# Check for common security issues in Cargo.toml
echo "=========================================="
echo "  Cargo.toml Security Checks"
echo "=========================================="
echo ""

# Check for wildcard versions
if grep -q '"*"' Cargo.toml 2>/dev/null; then
    echo -e "${RED}❌ Wildcard (*) version found in Cargo.toml${NC}"
    echo "    Specify exact versions for better security"
else
    echo -e "${GREEN}✅ No wildcard versions found${NC}"
fi

# Check for git dependencies
if grep -q 'git = ' Cargo.toml 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Git dependencies found in Cargo.toml${NC}"
    echo "    Consider using published crate versions"
else
    echo -e "${GREEN}✅ No git dependencies found${NC}"
fi
echo ""

# Generate dependency tree
echo "=========================================="
echo "  Dependency Tree Analysis"
echo "=========================================="
echo ""

echo "Analyzing dependency tree..."
cargo tree --depth 1
echo ""

# Summary
echo "=========================================="
echo "  Security Audit Summary"
echo "=========================================="
echo ""

echo "Audit completed at: $(date)"
echo ""
echo "Next steps:"
echo "  1. Review any warnings or vulnerabilities"
echo "  2. Update dependencies: cargo update"
echo "  3. Test after updates: cargo test"
echo "  4. Update SECURITY.md with findings"
echo "  5. Schedule next audit in 1 week"
echo ""

echo -e "${GREEN}✅ Security audit complete!${NC}"

