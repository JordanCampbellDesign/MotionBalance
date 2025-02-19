import Foundation
import CoreMotion

enum DeviceOrientation: String {
    case unknown = "Unknown"
    case flat = "Flat"
    case upright = "Upright"
    case tilted = "Tilted"
    
    static func determine(from attitude: CMAttitude) -> DeviceOrientation {
        let pitch = abs(attitude.pitch)
        let roll = abs(attitude.roll)
        
        if pitch < 0.2 && roll < 0.2 {
            return .flat
        } else if pitch > 1.3 { // ~75 degrees
            return .upright
        } else {
            return .tilted
        }
    }
} 