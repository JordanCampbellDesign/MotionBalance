# Installation Guide

## Prerequisites

### Development Environment
- Xcode 14.0 or later
- macOS 12.0 or later
- iOS 15.0 or later
- Git

### Required Hardware
- iPhone with:
  - Gyroscope
  - Accelerometer
  - Bluetooth capability
  - iOS 15.0+
- Mac with:
  - Bluetooth capability
  - macOS 12.0+

## Installing the Apps

### Method 1: Using Xcode (Development)

#### iOS App
1. Connect your iPhone to your Mac with a USB cable
2. Open the project in Xcode:
```bash
open MotionBalance.xcodeproj
```
3. Select your iPhone as the target device in Xcode:
   - Click the device selector in the toolbar (next to the scheme selector)
   - Choose your iPhone from the list
4. Click the Play button (▶) or press ⌘R to build and run
5. On first launch, you'll need to trust the developer:
   - On your iPhone, go to Settings > General > VPN & Device Management
   - Trust the developer certificate

#### macOS App
1. In Xcode, select "MotionBalance macOS" from the scheme selector
2. Click the Play button (▶) or press ⌘R to build and run
3. When prompted about incoming network connections, click Allow

### Method 2: Using Release Builds

#### iOS App
1. Download the latest .ipa file from the [Releases](https://github.com/yourusername/MotionBalance/releases) page
2. Install using one of these methods:
   - TestFlight (recommended)
   - Apple Configurator
   - Ad-hoc distribution profile

#### macOS App
1. Download the latest .dmg file from the [Releases](https://github.com/yourusername/MotionBalance/releases) page
2. Double-click the .dmg file
3. Drag MotionBalance.app to your Applications folder
4. Right-click MotionBalance.app and select Open
5. Click Open in the security dialog

## First Launch

1. Launch the macOS app first:
   - Open MotionBalance from your Applications folder
   - Allow Bluetooth access when prompted
   - The app will show "Waiting for iPhone connection..."

2. Then launch the iOS app:
   - Find MotionBalance on your iPhone home screen
   - Allow required permissions (Motion, Bluetooth)
   - Follow the setup wizard to:
     1. Position your device
     2. Complete calibration
     3. Connect to your Mac
     4. Adjust comfort settings

## Troubleshooting First Launch

### iOS App
- If "Untrusted Developer" appears:
  1. Go to Settings > General > VPN & Device Management
  2. Trust the developer certificate
- If permissions are denied:
  1. Go to Settings > Privacy
  2. Enable Motion & Fitness
  3. Enable Bluetooth

### macOS App
- If "App can't be opened" appears:
  1. System Settings > Privacy & Security
  2. Click "Open Anyway"
- If Bluetooth connection fails:
  1. System Settings > Bluetooth
  2. Turn Bluetooth off and on
  3. Restart the app

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/MotionBalance.git
cd MotionBalance
```

### 2. Install Dependencies
No external dependencies are required as the project uses native Apple frameworks:
- CoreMotion
- CoreBluetooth
- Metal
- SwiftUI

### 3. Build Configuration
1. Open the project in Xcode:
```bash
open MotionBalance.xcodeproj
```

2. Select the appropriate signing team for both targets:
   - MotionBalance iOS
   - MotionBalance macOS

3. Configure build settings:
   - Set deployment targets
   - Enable necessary capabilities
     - Bluetooth
     - Motion sensors

### 4. Running the Apps

#### iOS App
1. Select the "MotionBalance iOS" scheme
2. Choose an iOS device (simulator won't work due to motion sensors)
3. Build and run (⌘R)

#### macOS App
1. Select the "MotionBalance macOS" scheme
2. Select your Mac as the target
3. Build and run (⌘R)

## Development Setup

### Code Style
The project uses SwiftLint for code style enforcement:
1. Install SwiftLint:
```bash
brew install swiftlint
```

2. SwiftLint will run automatically during builds

### Testing
Run the test suite:
```bash
xcodebuild test -scheme "MotionBalance iOS" -destination "platform=iOS Simulator,name=iPhone 14"
xcodebuild test -scheme "MotionBalance macOS" -destination "platform=macOS"
```

## Troubleshooting

### Common Issues

1. Bluetooth Connection
- Ensure Bluetooth is enabled on both devices
- Check privacy permissions
- Verify devices are in range

2. Motion Sensors
- Verify device supports required sensors
- Check motion sensor privacy permissions
- Ensure device is not in power-saving mode

3. Build Errors
- Clean build folder (⇧⌘K)
- Clean build cache:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Getting Help
1. Check existing issues on GitHub
2. Join discussions
3. Create a new issue with:
   - Device details
   - OS versions
   - Error messages
   - Steps to reproduce

## Contributing
See [CONTRIBUTING.md](../CONTRIBUTING.md) for:
- Code style guidelines
- Pull request process
- Testing requirements 

## Environment Verification

Run the environment verification script:
```bash
chmod +x scripts/verify_environment.sh
./scripts/verify_environment.sh
```

## Device Compatibility

### iOS App
Before running the app, check device compatibility:

```swift
let report = DeviceCompatibilityChecker.shared.checkCompatibility()
if !report.isCompatible {
    print(report.description)
    // Handle incompatibility
}
```

Required capabilities:
- Gyroscope
- Accelerometer
- Bluetooth LE
- iOS 15.0 or later

### macOS App
Required capabilities:
- Bluetooth LE
- Metal-capable GPU
- macOS 12.0 or later 