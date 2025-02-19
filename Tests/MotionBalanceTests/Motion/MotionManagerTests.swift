import XCTest
import CoreMotion
@testable import MotionBalance

class MotionManagerTests: XCTestCase {
    var motionManager: MotionManager!
    var mockBluetoothManager: MockBluetoothPeripheralManager!
    
    override func setUp() {
        super.setUp()
        mockBluetoothManager = MockBluetoothPeripheralManager()
        motionManager = MotionManager(bluetoothManager: mockBluetoothManager)
    }
    
    override func tearDown() {
        motionManager = nil
        mockBluetoothManager = nil
        super.tearDown()
    }
    
    func testMotionDataFiltering() {
        // Test that motion data is properly filtered
        let rawData = MotionData(
            pitch: 0.5,
            roll: 0.3,
            yaw: 0.1,
            rotationRateX: 1.0,
            rotationRateY: 0.8,
            rotationRateZ: 0.6,
            userAccelerationX: 0.2,
            userAccelerationY: 0.1,
            userAccelerationZ: 0.3,
            timestamp: Date()
        )
        
        let filteredData = motionManager.filterMotionData(from: rawData)
        
        // Verify filtering results
        XCTAssertLessThan(abs(filteredData.rotationRateX), abs(rawData.rotationRateX))
        XCTAssertLessThan(abs(filteredData.userAccelerationX), abs(rawData.userAccelerationX))
    }
    
    func testBatteryOptimization() {
        // Test battery optimization behavior
        motionManager.batteryOptimizationEnabled = true
        XCTAssertEqual(motionManager.updateInterval, 1.0/30.0)
        
        motionManager.batteryOptimizationEnabled = false
        XCTAssertEqual(motionManager.updateInterval, 1.0/60.0)
    }
    
    func testCalibration() {
        let expectation = XCTestExpectation(description: "Calibration completed")
        var calibrationData: [MotionData] = []
        
        motionManager.startCalibration { data in
            calibrationData.append(data)
            if calibrationData.count >= 100 {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThanOrEqual(calibrationData.count, 100)
    }
}

// Mock Bluetooth manager for testing
class MockBluetoothPeripheralManager: BluetoothPeripheralManager {
    override func sendMotionData(_ data: MotionData) {
        // Mock implementation
    }
} 