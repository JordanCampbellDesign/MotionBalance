import SwiftUI

struct ComfortSettingsStepView: View {
    @ObservedObject var settings: MotionSettings
    @State private var selectedPreset: MotionPreset = .moderate
    @State private var showAdvancedSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose your comfort level")
                .font(.headline)
            
            Picker("Comfort Level", selection: $selectedPreset) {
                ForEach(MotionPreset.allCases, id: \.self) { preset in
                    Text(preset.rawValue)
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPreset) { newValue in
                settings = newValue.settings
            }
            
            Text(presetDescription)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            DisclosureGroup("Advanced Settings", isExpanded: $showAdvancedSettings) {
                VStack(spacing: 15) {
                    SettingSlider(
                        title: "Visual Intensity",
                        value: $settings.dotOpacity,
                        range: 0.1...0.5,
                        format: "%.2f"
                    )
                    
                    SettingSlider(
                        title: "Response Speed",
                        value: $settings.smoothingFactor,
                        range: 0.05...0.3,
                        format: "%.2f"
                    )
                    
                    SettingSlider(
                        title: "Motion Sensitivity",
                        value: $settings.minimumMovementThreshold,
                        range: 0.001...0.05,
                        format: "%.3f"
                    )
                }
                .padding(.top)
            }
        }
    }
    
    private var presetDescription: String {
        switch selectedPreset {
        case .gentle:
            return "Subtle visual effects with gentle motion response. Best for high sensitivity to motion."
        case .moderate:
            return "Balanced visual effects with moderate response. Suitable for most users."
        case .responsive:
            return "Strong visual effects with quick response. For those less sensitive to motion."
        }
    }
} 