import Foundation
import Combine
import UniformTypeIdentifiers

class SettingsManager: ObservableObject {
    @Published var settings: MotionSettings {
        didSet {
            save()
            trackSettingsChanges(from: oldValue)
        }
    }
    
    private let defaults = UserDefaults.standard
    private let settingsKey = "com.motionbalance.settings"
    
    init() {
        if let data = defaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(MotionSettings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = .default
        }
    }
    
    func exportSettings() -> URL? {
        guard let data = try? JSONEncoder().encode(settings) else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MotionBalanceSettings")
            .appendingPathExtension("json")
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export settings: \(error)")
            return nil
        }
    }
    
    func importSettings(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let newSettings = try JSONDecoder().decode(MotionSettings.self, from: data)
            settings = newSettings
            AnalyticsService.shared.trackSettingsChange(name: "settings_imported", value: true)
            return true
        } catch {
            AnalyticsService.shared.trackError(domain: "settings_import", description: error.localizedDescription)
            return false
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }
    
    private func trackSettingsChanges(from oldSettings: MotionSettings) {
        if oldSettings.dotCount != settings.dotCount {
            AnalyticsService.shared.trackSettingsChange(name: "dot_count", value: settings.dotCount)
        }
        if oldSettings.dotSize != settings.dotSize {
            AnalyticsService.shared.trackSettingsChange(name: "dot_size", value: settings.dotSize)
        }
        if oldSettings.dotOpacity != settings.dotOpacity {
            AnalyticsService.shared.trackSettingsChange(name: "dot_opacity", value: settings.dotOpacity)
        }
        if oldSettings.smoothingFactor != settings.smoothingFactor {
            AnalyticsService.shared.trackSettingsChange(name: "smoothing_factor", value: settings.smoothingFactor)
        }
        // ... track other setting changes ...
    }
} 