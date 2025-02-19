import Foundation

enum MotionPreset: String, CaseIterable {
    case gentle = "Gentle"
    case moderate = "Moderate"
    case responsive = "Responsive"
    
    var settings: MotionSettings {
        switch self {
        case .gentle:
            return MotionSettings(
                dotCount: 80,
                dotSize: 4.0,
                dotOpacity: 0.25,
                dotBlur: 1.2,
                filterWeight: 0.15,
                minimumMovementThreshold: 0.015,
                velocityThreshold: 0.15,
                maxVelocity: 40.0,
                smoothingFactor: 0.12,
                historySize: 6
            )
            
        case .moderate:
            return MotionSettings.default
            
        case .responsive:
            return MotionSettings(
                dotCount: 120,
                dotSize: 3.5,
                dotOpacity: 0.35,
                dotBlur: 0.8,
                filterWeight: 0.25,
                minimumMovementThreshold: 0.008,
                velocityThreshold: 0.08,
                maxVelocity: 60.0,
                smoothingFactor: 0.18,
                historySize: 4
            )
        }
    }
} 