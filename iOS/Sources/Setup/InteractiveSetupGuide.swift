import SwiftUI

struct InteractiveSetupGuide: View {
    @StateObject private var verifier = InstallationVerifier.shared
    @State private var verificationResult: InstallationVerifier.VerificationResult?
    @State private var currentStep = 0
    @State private var isShowingQRCode = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                StepProgressView(currentStep: currentStep, totalSteps: 4)
                    .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Current step content
                        switch currentStep {
                        case 0:
                            SystemCheckView(result: verificationResult)
                        case 1:
                            InstallationMethodView(isShowingQR: $isShowingQRCode)
                        case 2:
                            DeviceSetupView()
                        case 3:
                            ConnectionTestView()
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Navigation buttons
                NavigationButtons(
                    currentStep: $currentStep,
                    canProceed: canProceedToNextStep
                )
                .padding()
            }
            .navigationTitle("Setup Guide")
            .task {
                verificationResult = await verifier.verifyInstallation()
            }
            .sheet(isPresented: $isShowingQRCode) {
                QRCodeView()
            }
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0:
            return verificationResult?.isFullyFunctional ?? false
        case 1:
            return true // Installation method selected
        case 2:
            return DeviceSetupValidator.isDeviceProperlyPositioned
        case 3:
            return ConnectionTester.isConnected
        default:
            return false
        }
    }
}

struct QRCodeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Scan to Install")
                .font(.title)
            
            // Generate QR code image
            Image(uiImage: generateQRCode())
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            
            Text("Or visit:")
                .foregroundColor(.secondary)
            
            Link("TestFlight Download",
                 destination: URL(string: "https://testflight.apple.com/join/YOUR_BETA_ID")!)
            
            Button("Done") {
                dismiss()
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func generateQRCode() -> UIImage {
        // Implementation of QR code generation
        // Using CoreImage CIQRCodeGenerator
        let data = "https://testflight.apple.com/join/YOUR_BETA_ID".data(using: .utf8)!
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
        qrFilter.setValue(data, forKey: "inputMessage")
        
        let transformed = qrFilter.outputImage!.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return UIImage(ciImage: transformed)
    }
} 