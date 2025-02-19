import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @StateObject private var performanceMonitor = PerformanceMonitor()
    @State private var selectedPreset: MotionPreset = .moderate
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var importExportError: String?
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Presets Section with Keyboard Shortcuts
            Section("Presets") {
                Picker("Motion Preset", selection: $selectedPreset) {
                    ForEach(MotionPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue)
                            .tag(preset)
                            .help("Press \(presetKeyboardShortcut(for: preset))")
                    }
                }
                .onChange(of: selectedPreset) { newValue in
                    settings.settings = newValue.settings
                }
                
                HStack {
                    ForEach(MotionPreset.allCases, id: \.self) { preset in
                        Button(preset.rawValue) {
                            selectedPreset = preset
                            settings.settings = preset.settings
                        }
                        .keyboardShortcut(presetKeyboardShortcut(for: preset), modifiers: .command)
                    }
                }
                
                Divider()
            }
            
            // Performance Metrics
            Section("Performance") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "gauge")
                        Text("FPS: \(Int(performanceMonitor.frameRate))")
                    }
                    
                    HStack {
                        Image(systemName: "cpu")
                        Text("CPU: \(Int(performanceMonitor.cpuUsage))%")
                    }
                    
                    HStack {
                        Image(systemName: "memorychip")
                        Text("Memory: \(formatMemory(performanceMonitor.memoryUsage))")
                    }
                }
                .font(.system(.body, design: .monospaced))
                
                Divider()
            }
            
            // Advanced Settings
            Section("Advanced Settings") {
                DisclosureGroup("Visual Settings") {
                    SettingSlider(
                        title: "Dot Count",
                        value: Binding(
                            get: { Double(settings.settings.dotCount) },
                            set: { settings.settings.dotCount = Int($0) }
                        ),
                        range: 50...200,
                        format: "%.0f"
                    )
                    
                    SettingSlider(
                        title: "Dot Size",
                        value: $settings.settings.dotSize,
                        range: 2...8,
                        format: "%.1f"
                    )
                    
                    SettingSlider(
                        title: "Opacity",
                        value: $settings.settings.dotOpacity,
                        range: 0.1...0.5,
                        format: "%.2f"
                    )
                }
                
                DisclosureGroup("Motion Settings") {
                    SettingSlider(
                        title: "Smoothing",
                        value: $settings.settings.smoothingFactor,
                        range: 0.05...0.3,
                        format: "%.2f"
                    )
                    
                    SettingSlider(
                        title: "Movement Threshold",
                        value: $settings.settings.minimumMovementThreshold,
                        range: 0.001...0.05,
                        format: "%.3f"
                    )
                    
                    SettingSlider(
                        title: "Max Velocity",
                        value: $settings.settings.maxVelocity,
                        range: 20...100,
                        format: "%.0f"
                    )
                }
            }
            
            // Import/Export Buttons
            HStack {
                Button("Import Settings") {
                    showingImporter = true
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Button("Export Settings") {
                    if let url = settings.exportSettings() {
                        showingExporter = true
                    } else {
                        importExportError = "Failed to export settings"
                        showingError = true
                    }
                }
                .keyboardShortcut("e", modifiers: .command)
            }
            
            Button("Reset to Defaults") {
                settings.settings = .default
                selectedPreset = .moderate
            }
            
            Section("Privacy") {
                Toggle("Enable Analytics", isOn: .init(
                    get: { PrivacyManager.shared.analyticsEnabled },
                    set: { PrivacyManager.shared.analyticsEnabled = $0 }
                ))
                .help("Collect anonymous usage data to help improve the app")
                
                if PrivacyManager.shared.analyticsEnabled {
                    Text("Analytics help us understand how the app is used and identify areas for improvement.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
            }
            
            Section("Backups") {
                DisclosureGroup("Manage Backups") {
                    VStack(alignment: .leading, spacing: 10) {
                        Button("Create Backup") {
                            do {
                                let url = try BackupManager.shared.createBackup(settings: settings.settings)
                                importExportError = "Backup created at: \(url.lastPathComponent)"
                                showingError = true
                            } catch {
                                importExportError = "Failed to create backup: \(error.localizedDescription)"
                                showingError = true
                            }
                        }
                        
                        Divider()
                        
                        Text("Available Backups:")
                            .font(.caption)
                        
                        List(BackupManager.shared.listBackups(), id: \.url) { backup in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(backup.metadata.timestamp, style: .date)
                                        .font(.system(.body, design: .monospaced))
                                    
                                    if let description = backup.metadata.description {
                                        Text("- \(description)")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                HStack {
                                    Text("v\(backup.metadata.appVersion)")
                                    Text("•")
                                    Text(backup.metadata.deviceInfo.systemVersion)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                HStack {
                                    Spacer()
                                    Button("Restore") {
                                        do {
                                            settings.settings = try BackupManager.shared.restoreFromBackup(at: backup.url)
                                            selectedPreset = .moderate
                                        } catch {
                                            importExportError = "Failed to restore backup: \(error.localizedDescription)"
                                            showingError = true
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 300)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first,
                      settings.importSettings(from: url) else {
                    importExportError = "Failed to import settings"
                    showingError = true
                    return
                }
                selectedPreset = .moderate // Reset preset selection
            case .failure(let error):
                importExportError = error.localizedDescription
                showingError = true
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: SettingsDocument(settings: settings.settings),
            contentType: .json,
            defaultFilename: "MotionBalanceSettings"
        ) { result in
            if case .failure(let error) = result {
                importExportError = error.localizedDescription
                showingError = true
            }
        }
        .alert("Error", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(importExportError ?? "Unknown error")
        })
    }
    
    private func formatMemory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func presetKeyboardShortcut(for preset: MotionPreset) -> KeyEquivalent {
        switch preset {
        case .gentle: return "1"
        case .moderate: return "2"
        case .responsive: return "3"
        }
    }
}

struct SettingSlider: View {
    let title: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let format: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title): \(String(format: format, value.wrappedValue))")
            Slider(value: value, in: range)
        }
    }
}

// Document type for file export
struct SettingsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var settings: MotionSettings
    
    init(settings: MotionSettings) {
        self.settings = settings
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let settings = try? JSONDecoder().decode(MotionSettings.self, from: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.settings = settings
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(settings)
        return .init(regularFileWithContents: data)
    }
} 