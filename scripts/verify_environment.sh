#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Verifying development environment..."

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | grep "Xcode" | cut -d' ' -f2)
REQUIRED_XCODE="14.0"

if [ "$(printf '%s\n' "$REQUIRED_XCODE" "$XCODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_XCODE" ]; then
    printf "${GREEN}✓ Xcode version $XCODE_VERSION${NC}\n"
else
    printf "${RED}✗ Xcode version $XCODE_VERSION (required: $REQUIRED_XCODE or later)${NC}\n"
    exit 1
fi

# Check SwiftLint
if which swiftlint >/dev/null; then
    printf "${GREEN}✓ SwiftLint installed${NC}\n"
else
    printf "${RED}✗ SwiftLint not found${NC}\n"
    printf "${YELLOW}Install with: brew install swiftlint${NC}\n"
    exit 1
fi

# Check Git
if which git >/dev/null; then
    printf "${GREEN}✓ Git installed${NC}\n"
else
    printf "${RED}✗ Git not found${NC}\n"
    exit 1
fi

# Check for required frameworks
FRAMEWORKS=("CoreMotion.framework" "CoreBluetooth.framework" "Metal.framework")
for framework in "${FRAMEWORKS[@]}"; do
    if [ -d "/System/Library/Frameworks/$framework" ]; then
        printf "${GREEN}✓ $framework found${NC}\n"
    else
        printf "${RED}✗ $framework not found${NC}\n"
        exit 1
    fi
done

# Check macOS version
OS_VERSION=$(sw_vers -productVersion)
REQUIRED_OS="12.0"

if [ "$(printf '%s\n' "$REQUIRED_OS" "$OS_VERSION" | sort -V | head -n1)" = "$REQUIRED_OS" ]; then
    printf "${GREEN}✓ macOS version $OS_VERSION${NC}\n"
else
    printf "${RED}✗ macOS version $OS_VERSION (required: $REQUIRED_OS or later)${NC}\n"
    exit 1
fi

# Verify Xcode command line tools
if xcode-select -p >/dev/null; then
    printf "${GREEN}✓ Xcode command line tools installed${NC}\n"
else
    printf "${RED}✗ Xcode command line tools not installed${NC}\n"
    printf "${YELLOW}Install with: xcode-select --install${NC}\n"
    exit 1
fi

echo ""
printf "${GREEN}Environment verification complete!${NC}\n" 