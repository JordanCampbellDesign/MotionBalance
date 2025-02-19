import Foundation

struct MotionSettings: Codable {
    // Version for settings migration
    private let version: Int = 1
    
    // Visual settings
    var dotCount: Int
    var dotSize: Double
    var dotOpacity: Double
    var dotBlur: Double
    
    // Motion filtering settings
    var filterWeight: Double
    var minimumMovementThreshold: Double
    var velocityThreshold: Double
    var maxVelocity: Double
    var smoothingFactor: Double
    var historySize: Int
    
    static let `default` = MotionSettings(
        dotCount: 100,
        dotSize: 4.0,
        dotOpacity: 0.3,
        dotBlur: 1.0,
        filterWeight: 0.2,
        minimumMovementThreshold: 0.01,
        velocityThreshold: 0.1,
        maxVelocity: 50.0,
        smoothingFactor: 0.15,
        historySize: 5
    )
    
    // Migration support
    enum CodingKeys: String, CodingKey {
        case version
        case dotCount, dotSize, dotOpacity, dotBlur
        case filterWeight, minimumMovementThreshold
        case velocityThreshold, maxVelocity
        case smoothingFactor, historySize
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 0
        
        switch version {
        case 0:
            // Migrate from version 0 (original version)
            self = try MotionSettings.migrateFromV0(container)
        case 1:
            // Current version
            self = try MotionSettings.decodeV1(container)
        default:
            // Unknown version, use defaults
            self = .default
        }
    }
    
    private static func migrateFromV0(_ container: KeyedDecodingContainer<CodingKeys>) throws -> MotionSettings {
        // Example migration from version 0
        let dotCount = try container.decodeIfPresent(Int.self, forKey: .dotCount) ?? 100
        let dotSize = try container.decodeIfPresent(Double.self, forKey: .dotSize) ?? 4.0
        // ... migrate other values ...
        
        return MotionSettings(
            dotCount: dotCount,
            dotSize: dotSize,
            dotOpacity: 0.3, // Use new default
            dotBlur: 1.0,    // Use new default
            filterWeight: 0.2,
            minimumMovementThreshold: 0.01,
            velocityThreshold: 0.1,
            maxVelocity: 50.0,
            smoothingFactor: 0.15,
            historySize: 5
        )
    }
    
    private static func decodeV1(_ container: KeyedDecodingContainer<CodingKeys>) throws -> MotionSettings {
        return MotionSettings(
            dotCount: try container.decode(Int.self, forKey: .dotCount),
            dotSize: try container.decode(Double.self, forKey: .dotSize),
            dotOpacity: try container.decode(Double.self, forKey: .dotOpacity),
            dotBlur: try container.decode(Double.self, forKey: .dotBlur),
            filterWeight: try container.decode(Double.self, forKey: .filterWeight),
            minimumMovementThreshold: try container.decode(Double.self, forKey: .minimumMovementThreshold),
            velocityThreshold: try container.decode(Double.self, forKey: .velocityThreshold),
            maxVelocity: try container.decode(Double.self, forKey: .maxVelocity),
            smoothingFactor: try container.decode(Double.self, forKey: .smoothingFactor),
            historySize: try container.decode(Int.self, forKey: .historySize)
        )
    }
} 