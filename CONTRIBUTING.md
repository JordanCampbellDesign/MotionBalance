# Contributing to MotionBalance

Thank you for your interest in contributing to MotionBalance! This document provides guidelines and information for contributors.

## Project Overview

MotionBalance is an open-source iOS and macOS application that helps reduce motion sickness by using iPhone motion sensors to create compensatory visual effects on a Mac display.

### Key Components

1. **iOS Motion Detection (MotionManager)**
   - Handles motion sensor data collection
   - Implements filtering and accuracy tracking
   - Manages battery optimization
   - Located in `iOS/Sources/Motion/`

2. **Bluetooth Communication**
   - Handles device discovery and pairing
   - Manages data transmission
   - Located in `iOS/Sources/Bluetooth/` and `macOS/Sources/Bluetooth/`

3. **Visual Compensation (macOS)**
   - Processes motion data
   - Renders counter-motion visuals
   - Located in `macOS/Sources/Visual/`

## Getting Started

1. **Development Environment**
   - Xcode 14.0 or later
   - iOS 15.0+ / macOS 12.0+
   - Swift 5.5+

2. **Setup**
   ```bash
   git clone https://github.com/yourusername/MotionBalance.git
   cd MotionBalance
   ```

3. **Building**
   - Open `MotionBalance.xcodeproj`
   - Select appropriate scheme (iOS or macOS)
   - Build and run

## Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code style consistency
- Maintain existing formatting patterns
- Add comments for complex logic

## Testing

- Write unit tests for new features
- Update existing tests when modifying code
- Run tests before submitting PR
- Include UI tests for visual components

## Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Commit changes with clear messages
4. Write/update tests
5. Update documentation
6. Submit PR with description

## Architecture

### iOS App 