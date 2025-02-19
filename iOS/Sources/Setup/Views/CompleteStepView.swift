import SwiftUI

struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .symbolEffect(.bounce)
            
            Text("Setup Complete!")
                .font(.title)
            
            Text("Your device is now configured and ready to help reduce motion sickness.")
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 15) {
                TipRow(icon: "iphone.gen2", text: "Keep your device flat and stable")
                TipRow(icon: "battery.100", text: "Monitor battery level for optimal performance")
                TipRow(icon: "gear", text: "Adjust settings anytime from the main screen")
                TipRow(icon: "person.fill.questionmark", text: "Contact support if you need help")
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
            Text(text)
        }
    }
} 