import Foundation

struct MotionData: Codable {
    let pitch: Double
    let roll: Double
    let yaw: Double
    let rotationRateX: Double
    let rotationRateY: Double
    let rotationRateZ: Double
    let userAccelerationX: Double
    let userAccelerationY: Double
    let userAccelerationZ: Double
    let timestamp: Date
    
    static let zero = MotionData(
        pitch: 0, roll: 0, yaw: 0,
        rotationRateX: 0, rotationRateY: 0, rotationRateZ: 0,
        userAccelerationX: 0, userAccelerationY: 0, userAccelerationZ: 0,
        timestamp: Date()
    )
} 