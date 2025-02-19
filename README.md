# MotionBalance

MotionBalance is an open-source iOS and macOS application that helps reduce motion sickness by using iPhone motion sensors to create compensatory visual effects on a Mac display.

## Features

- Real-time motion detection using iPhone sensors
- Adaptive visual compensation on macOS
- Bluetooth connectivity between devices
- Customizable sensitivity settings
- Battery-optimized performance
- Accessibility support

## Requirements

- iOS 15.0+ / macOS 12.0+
- Xcode 14.0+
- iPhone with gyroscope and accelerometer
- Mac with Bluetooth support

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/MotionBalance.git
cd MotionBalance
```

2. Open the project in Xcode:
```bash
open MotionBalance.xcodeproj
```

3. Build and run both the iOS and macOS targets.

## Usage

1. Launch the macOS app on your Mac
2. Launch the iOS app on your iPhone
3. Follow the setup wizard to:
   - Position your device correctly
   - Calibrate motion detection
   - Connect to your Mac
   - Adjust comfort settings

## Architecture

### iOS App
- `MotionManager`: Handles sensor data collection and processing
- `BluetoothPeripheralManager`: Manages device communication
- `SetupManager`: Controls setup and calibration flow

### macOS App
- `MotionCompensationView`: Renders visual compensation
- `MetalDotRenderer`: Handles efficient graphics rendering
- `BluetoothCentralManager`: Manages device connections

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 