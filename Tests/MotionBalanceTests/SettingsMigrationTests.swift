import XCTest
@testable import MotionBalance

class SettingsMigrationTests: XCTestCase {
    func testMigrateFromV0() throws {
        // Create V0 settings JSON
        let v0JSON = """
        {
            "dotCount": 80,
            "dotSize": 3.5
        }
        """
        
        let data = v0JSON.data(using: .utf8)!
        let settings = try JSONDecoder().decode(MotionSettings.self, from: data)
        
        // Verify migration
        XCTAssertEqual(settings.dotCount, 80)
        XCTAssertEqual(settings.dotSize, 3.5)
        XCTAssertEqual(settings.dotOpacity, 0.3) // Default value
        XCTAssertEqual(settings.dotBlur, 1.0)    // Default value
    }
    
    func testMigrateFromUnknownVersion() throws {
        let unknownJSON = """
        {
            "version": 999,
            "dotCount": 80
        }
        """
        
        let data = unknownJSON.data(using: .utf8)!
        let settings = try JSONDecoder().decode(MotionSettings.self, from: data)
        
        // Should use defaults for unknown version
        XCTAssertEqual(settings, .default)
    }
    
    func testCurrentVersion() throws {
        let currentSettings = MotionSettings.default
        let data = try JSONEncoder().encode(currentSettings)
        let decoded = try JSONDecoder().decode(MotionSettings.self, from: data)
        
        XCTAssertEqual(currentSettings.dotCount, decoded.dotCount)
        XCTAssertEqual(currentSettings.dotSize, decoded.dotSize)
        XCTAssertEqual(currentSettings.dotOpacity, decoded.dotOpacity)
        // ... test other properties
    }
} 