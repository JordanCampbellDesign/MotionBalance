#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Installation modes
MODE_DEV="development"
MODE_RELEASE="release"

# QR code data
TESTFLIGHT_URL="https://testflight.apple.com/join/YOUR_BETA_ID"
RELEASES_URL="https://github.com/yourusername/MotionBalance/releases/latest"

function generate_qr_code() {
    echo "Generate QR code at: https://api.qrserver.com/v1/create-qr-code/?data=$1"
}

function verify_installation() {
    local issues=0
    
    # Check app installation
    if [ -d "/Applications/MotionBalance.app" ]; then
        printf "${GREEN}✓ macOS app installed${NC}\n"
    else
        printf "${RED}✗ macOS app not found${NC}\n"
        issues=$((issues + 1))
    }
    
    # Check permissions
    if system_profiler SPBluetoothDataType | grep -q "State: On"; then
        printf "${GREEN}✓ Bluetooth enabled${NC}\n"
    else
        printf "${RED}✗ Bluetooth disabled${NC}\n"
        issues=$((issues + 1))
    }
    
    return $issues
}

function install_development() {
    echo "Installing development version..."
    
    # Verify Xcode installation
    if ! xcode-select -p &> /dev/null; then
        printf "${RED}Xcode not installed. Please install Xcode first.${NC}\n"
        exit 1
    }
    
    # Clone repository if needed
    if [ ! -d "MotionBalance" ]; then
        git clone https://github.com/yourusername/MotionBalance.git
        cd MotionBalance
    fi
    
    # Build and install
    xcodebuild -scheme "MotionBalance macOS" build
    
    printf "${GREEN}Development installation complete!${NC}\n"
    printf "${YELLOW}Now connect your iPhone and run:${NC}\n"
    printf "xcodebuild -scheme \"MotionBalance iOS\" -destination \"platform=iOS\"\n"
}

function install_release() {
    echo "Installing release version..."
    
    # Download latest release
    curl -L -o MotionBalance.dmg "$RELEASES_URL/download/latest/MotionBalance.dmg"
    
    # Mount DMG
    hdiutil attach MotionBalance.dmg
    
    # Copy to Applications
    cp -R "/Volumes/MotionBalance/MotionBalance.app" /Applications/
    
    # Unmount DMG
    hdiutil detach "/Volumes/MotionBalance"
    
    printf "${GREEN}Release installation complete!${NC}\n"
    printf "${YELLOW}Scan this QR code to install the iOS app:${NC}\n"
    generate_qr_code "$TESTFLIGHT_URL"
}

# Main installation flow
echo "MotionBalance Installer"
echo "----------------------"

# Parse arguments
MODE=$1
if [ -z "$MODE" ]; then
    echo "Select installation mode:"
    echo "1) Development (build from source)"
    echo "2) Release (install from TestFlight/DMG)"
    read -p "Enter choice (1/2): " choice
    case $choice in
        1) MODE=$MODE_DEV ;;
        2) MODE=$MODE_RELEASE ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
fi

# Run installation
case $MODE in
    $MODE_DEV) install_development ;;
    $MODE_RELEASE) install_release ;;
    *) echo "Invalid mode: $MODE"; exit 1 ;;
esac

# Verify installation
verify_installation

# Show first launch tutorial
open "motionbalance://tutorial" 