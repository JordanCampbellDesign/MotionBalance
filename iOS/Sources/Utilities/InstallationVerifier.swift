import Foundation
import CoreMotion
import CoreBluetooth
import Metal

class InstallationVerifier {
    static let shared = InstallationVerifier()
    
    struct VerificationResult {
        var issues: [Issue] = []
        var recommendations: [String] = []
        var isFullyFunctional: Bool { issues.isEmpty }
        
        struct Issue {
            let severity: Severity
            let component: Component
            let description: String
            let resolution: String
            
            enum Severity: String {
                case critical
                case warning
                case info
            }
            
            enum Component: String {
                case motion
                case bluetooth
                case metal
                case permissions
                case system
            }
        }
    }
    
    func verifyInstallation() async -> VerificationResult {
        var result = VerificationResult()
        
        // Check system requirements
        if #available(iOS 15.0, macOS 12.0, *) {
            // Supported
        } else {
            result.issues.append(.init(
                severity: .critical,
                component: .system,
                description: "Operating system too old",
                resolution: "Update to iOS 15.0/macOS 12.0 or later"
            ))
        }
        
        // Check motion sensors
        let motionManager = CMMotionManager()
        if !motionManager.isDeviceMotionAvailable {
            result.issues.append(.init(
                severity: .critical,
                component: .motion,
                description: "Motion sensors unavailable",
                resolution: "Device must have gyroscope and accelerometer"
            ))
        }
        
        // Check Bluetooth
        let bluetoothState = await checkBluetoothStatus()
        switch bluetoothState {
        case .unauthorized:
            result.issues.append(.init(
                severity: .critical,
                component: .bluetooth,
                description: "Bluetooth access denied",
                resolution: "Enable Bluetooth in Settings"
            ))
        case .poweredOff:
            result.issues.append(.init(
                severity: .warning,
                component: .bluetooth,
                description: "Bluetooth is turned off",
                resolution: "Turn on Bluetooth"
            ))
        case .unsupported:
            result.issues.append(.init(
                severity: .critical,
                component: .bluetooth,
                description: "Bluetooth LE not supported",
                resolution: "Device must support Bluetooth LE"
            ))
        default:
            break
        }
        
        // Check Metal support (macOS)
        #if os(macOS)
        if !MTLCreateSystemDefaultDevice() {
            result.issues.append(.init(
                severity: .critical,
                component: .metal,
                description: "Metal graphics not supported",
                resolution: "Device must support Metal graphics"
            ))
        }
        #endif
        
        // Add recommendations
        if result.issues.isEmpty {
            result.recommendations.append("Ensure both devices are within Bluetooth range (about 30 feet)")
            result.recommendations.append("Keep iPhone flat and stable during use")
            result.recommendations.append("Consider using a phone stand or mount")
        }
        
        return result
    }
    
    private func checkBluetoothStatus() async -> CBManagerState {
        await withCheckedContinuation { continuation in
            let manager = CBCentralManager(delegate: nil, queue: nil)
            continuation.resume(returning: manager.state)
        }
    }
} 