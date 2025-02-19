import SwiftUI

struct AnimatedTutorialStep: View {
    let step: TutorialStep
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated icon
            AnimatedIcon(name: step.icon, isAnimating: isAnimating)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            // Title and description
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Interactive elements
            if let interaction = step.interaction {
                InteractiveElement(type: interaction)
                    .padding(.top)
            }
        }
        .padding()
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

struct AnimatedIcon: View {
    let name: String
    let isAnimating: Bool
    
    var body: some View {
        Image(systemName: name)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .rotationEffect(.degrees(rotationAngle))
    }
    
    private var rotationAngle: Double {
        switch name {
        case "arrow.triangle.2.circlepath":
            return isAnimating ? 360 : 0
        case "iphone.gen2":
            return isAnimating ? 5 : -5
        default:
            return 0
        }
    }
}

struct InteractiveElement: View {
    let type: TutorialStep.InteractionType
    @State private var isCompleted = false
    
    var body: some View {
        switch type {
        case .devicePosition:
            DevicePositionGuide(isCompleted: $isCompleted)
        case .bluetoothSetup:
            BluetoothSetupGuide(isCompleted: $isCompleted)
        case .calibration:
            CalibrationGuide(isCompleted: $isCompleted)
        case .comfortSettings:
            ComfortSettingsGuide(isCompleted: $isCompleted)
        }
    }
} 