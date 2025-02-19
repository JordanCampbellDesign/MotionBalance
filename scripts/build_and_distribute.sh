#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
TEAM_ID="YOUR_TEAM_ID"
BUNDLE_ID="com.yourdomain.motionbalance"
VERSION="1.0.0"

echo "MotionBalance Build & Distribution"
echo "--------------------------------"

# Check for required tools
if ! command -v fastlane &> /dev/null; then
    printf "${RED}Fastlane not found. Installing...${NC}\n"
    brew install fastlane
fi

# Verify certificates and provisioning profiles
echo "Verifying certificates..."
fastlane match development --readonly
fastlane match appstore --readonly

# Build iOS app
echo "Building iOS app..."
fastlane ios beta

# Build macOS app
echo "Building macOS app..."
fastlane mac release

# Generate TestFlight invitation
echo "Generating TestFlight invitation..."
TESTFLIGHT_URL="https://testflight.apple.com/join/YOUR_BETA_ID"
qrencode -o testflight_qr.png "$TESTFLIGHT_URL"

# Print success message
printf "${GREEN}Build complete!${NC}\n\n"
printf "TestFlight URL: $TESTFLIGHT_URL\n"
printf "QR Code generated: testflight_qr.png\n\n"
printf "Next steps:\n"
printf "1. Share the TestFlight URL or QR code with testers\n"
printf "2. Install the macOS app from ./build/MotionBalance.dmg\n" 