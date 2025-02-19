import Foundation
import FirebaseAnalytics

class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    private func shouldTrack() -> Bool {
        return PrivacyManager.shared.analyticsEnabled
    }
    
    func trackSettingsChange(name: String, value: Any) {
        guard shouldTrack() else { return }
        Analytics.logEvent("settings_changed", parameters: [
            "setting_name": name,
            "setting_value": "\(value)"
        ])
    }
    
    func trackPresetSelected(preset: MotionPreset) {
        Analytics.logEvent("preset_selected", parameters: [
            "preset_name": preset.rawValue
        ])
    }
    
    func trackPerformanceMetrics(fps: Double, cpu: Double, memory: UInt64) {
        Analytics.logEvent("performance_metrics", parameters: [
            "fps": fps,
            "cpu_usage": cpu,
            "memory_usage": memory
        ])
    }
    
    func trackConnectionState(state: BluetoothCentralManager.ConnectionState) {
        Analytics.logEvent("connection_state_changed", parameters: [
            "state": state.analyticsName
        ])
    }
    
    func trackError(domain: String, description: String) {
        Analytics.logEvent("error_occurred", parameters: [
            "error_domain": domain,
            "error_description": description
        ])
    }
}

// Analytics helpers
extension BluetoothCentralManager.ConnectionState {
    var analyticsName: String {
        switch self {
        case .disconnected: return "disconnected"
        case .scanning: return "scanning"
        case .connecting: return "connecting"
        case .connected: return "connected"
        }
    }
} 