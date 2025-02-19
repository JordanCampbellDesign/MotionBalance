import Foundation

struct BackupMetadata: Codable {
    let timestamp: Date
    let appVersion: String
    let description: String?
    let deviceInfo: DeviceInfo
    let settingsVersion: Int
    
    struct DeviceInfo: Codable {
        let systemVersion: String
        let deviceModel: String
        
        static var current: DeviceInfo {
            DeviceInfo(
                systemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                deviceModel: "macOS" // Could be more specific if needed
            )
        }
    }
    
    static func create(for settings: MotionSettings, description: String? = nil) -> BackupMetadata {
        BackupMetadata(
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            description: description,
            deviceInfo: .current,
            settingsVersion: settings.version
        )
    }
} 