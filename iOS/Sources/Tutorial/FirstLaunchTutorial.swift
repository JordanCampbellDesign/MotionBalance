import SwiftUI

struct FirstLaunchTutorial: View {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var currentStep = 0
    
    let steps = [
        TutorialStep(
            title: "Welcome to MotionBalance",
            description: "Let's get you set up in just a few steps.",
            icon: "hand.wave"
        ),
        TutorialStep(
            title: "Position Your Device",
            description: "Place your iPhone flat on a stable surface.",
            icon: "iphone.gen2"
        ),
        TutorialStep(
            title: "Connect to Mac",
            description: "Make sure your Mac app is running and Bluetooth is enabled.",
            icon: "macbook.and.iphone"
        ),
        TutorialStep(
            title: "Adjust Settings",
            description: "Customize the visual effects to your comfort level.",
            icon: "slider.horizontal.3"
        )
    ]
    
    var body: some View {
        if !hasSeenTutorial {
            ZStack {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: steps[currentStep].icon)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(steps[currentStep].title)
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text(steps[currentStep].description)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Button(currentStep < steps.count - 1 ? "Next" : "Get Started") {
                        if currentStep < steps.count - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            hasSeenTutorial = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
} 