import CoreMotion
import CoreBluetooth

class DeviceCompatibilityChecker {
    static let shared = DeviceCompatibilityChecker()
    
    struct CompatibilityReport {
        let isCompatible: Bool
        let motionAvailable: Bool
        let bluetoothAvailable: Bool
        let issues: [String]
        
        var description: String {
            if isCompatible {
                return "Device is fully compatible"
            } else {
                return "Compatibility issues found:\n" + issues.joined(separator: "\n")
            }
        }
    }
    
    func checkCompatibility() -> CompatibilityReport {
        var issues: [String] = []
        
        // Check motion sensors
        let motionManager = CMMotionManager()
        let motionAvailable = motionManager.isDeviceMotionAvailable
        if !motionAvailable {
            issues.append("Device motion sensors not available")
        }
        
        // Check Bluetooth
        let bluetoothAvailable = CBCentralManager.authorization != .denied
        if !bluetoothAvailable {
            issues.append("Bluetooth access not authorized")
        }
        
        // Check iOS version
        if #available(iOS 15.0, *) {
            // Supported
        } else {
            issues.append("iOS 15.0 or later required")
        }
        
        // Check device capabilities
        if !CMMotionActivityManager.isActivityAvailable() {
            issues.append("Motion activity tracking not available")
        }
        
        return CompatibilityReport(
            isCompatible: issues.isEmpty,
            motionAvailable: motionAvailable,
            bluetoothAvailable: bluetoothAvailable,
            issues: issues
        )
    }
} 