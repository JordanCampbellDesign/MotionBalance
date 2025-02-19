import SwiftUI

struct SetupView: View {
    @StateObject private var setupManager: SetupManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    init(motionManager: MotionManager) {
        _setupManager = StateObject(wrappedValue: SetupManager(motionManager: motionManager))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Step indicator
                StepIndicator(currentStep: setupManager.currentStep)
                    .padding(.top)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Setup progress: Step \(setupManager.currentStep.rawValue + 1) of \(SetupManager.SetupStep.allCases.count)")
                
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        stepContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    }
                    .padding()
                    .animation(.easeInOut, value: setupManager.currentStep)
                }
                
                // Navigation buttons
                NavigationButtons(
                    currentStep: setupManager.currentStep,
                    canProceed: setupManager.canProceed,
                    onNext: setupManager.nextStep,
                    onBack: setupManager.previousStep
                )
                .padding()
            }
            .navigationTitle(setupManager.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch setupManager.currentStep {
        case .welcome:
            WelcomeStepView()
        case .devicePosition:
            DevicePositionStepView(orientation: setupManager.deviceOrientation)
                .accessibilityElement(children: .combine)
        case .calibration:
            CalibrationStepView(
                isCalibrating: setupManager.isCalibrating,
                progress: setupManager.calibrationProgress,
                startCalibration: setupManager.startCalibration
            )
        case .bluetoothPairing:
            BluetoothPairingStepView(bluetoothManager: setupManager.bluetoothManager)
        case .comfort:
            ComfortSettingsStepView(settings: setupManager.motionManager.settings)
        case .complete:
            CompleteStepView()
        }
    }
}

struct StepIndicator: View {
    let currentStep: SetupManager.SetupStep
    
    var body: some View {
        HStack {
            ForEach(SetupManager.SetupStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray)
                    .frame(width: 8, height: 8)
                
                if step != .complete {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray)
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
            
            Text("Welcome to MotionBalance")
                .font(.title)
            
            Text("This app helps reduce motion sickness by creating compensatory visual effects on your Mac display.")
                .multilineTextAlignment(.center)
            
            Text("Let's get started by setting up your device.")
                .foregroundColor(.secondary)
        }
        .makeAccessible()
    }
}

struct DevicePositionStepView: View {
    let orientation: DeviceOrientation
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: orientationIcon)
                .font(.system(size: 60))
                .foregroundColor(orientationColor)
            
            Text("Current Position: \(orientation.rawValue)")
                .font(.headline)
            
            Text(orientationInstructions)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .makeAccessible()
    }
    
    private var orientationIcon: String {
        switch orientation {
        case .flat: return "iphone"
        case .upright: return "iphone.gen2"
        case .tilted: return "iphone.gen2.slash"
        case .unknown: return "iphone.gen2.radiowaves.left.and.right.slash"
        }
    }
    
    private var orientationColor: Color {
        switch orientation {
        case .flat: return .green
        case .upright: return .blue
        case .tilted, .unknown: return .red
        }
    }
    
    private var orientationInstructions: String {
        switch orientation {
        case .flat:
            return "Perfect! Keep your device flat and stable."
        case .upright:
            return "Please lay your device flat on a stable surface."
        case .tilted:
            return "The device is tilted. Please adjust to be flat."
        case .unknown:
            return "Checking device orientation..."
        }
    }
}

struct CalibrationStepView: View {
    let isCalibrating: Bool
    let progress: Double
    let startCalibration: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if isCalibrating {
                ProgressView("Calibrating...", value: progress)
                    .progressViewStyle(.linear)
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                
                Text("Keep your device still")
                    .foregroundColor(.secondary)
            } else {
                Button(action: startCalibration) {
                    Text("Start Calibration")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Text("This will help optimize the visual effects for your environment")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .makeAccessible()
    }
}

// Add other step views similarly...

struct NavigationButtons: View {
    let currentStep: SetupManager.SetupStep
    let canProceed: Bool
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            if currentStep != .welcome {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .accessibilityHint("Go back to previous step")
            }
            
            Spacer()
            
            if currentStep != .complete {
                Button(action: onNext) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
                .accessibilityHint(accessibilityNextHint)
            }
        }
    }
    
    private var accessibilityNextHint: String {
        if !canProceed {
            switch currentStep {
            case .devicePosition:
                return "Please place device flat before proceeding"
            case .bluetoothPairing:
                return "Please complete pairing before proceeding"
            default:
                return "Cannot proceed yet"
            }
        }
        return "Continue to next step"
    }
}

// Add accessibility modifiers to existing views
extension WelcomeStepView {
    func makeAccessible() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Welcome to MotionBalance")
            .accessibilityHint("This app helps reduce motion sickness. Follow the setup steps to get started.")
    }
}

extension DevicePositionStepView {
    func makeAccessible() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Device Position: \(orientation.rawValue)")
            .accessibilityHint(orientationInstructions)
    }
}

extension CalibrationStepView {
    func makeAccessible() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isCalibrating ? "Calibrating: \(Int(progress * 100))% complete" : "Calibration")
            .accessibilityHint(isCalibrating ? "Keep device still during calibration" : "Start calibration process")
    }
} 