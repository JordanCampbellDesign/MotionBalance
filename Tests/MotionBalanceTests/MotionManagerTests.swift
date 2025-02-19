import XCTest
import CoreMotion
import Combine
@testable import MotionBalance

class MotionManagerTests: XCTestCase {
    var motionManager: MotionManager!
    var mockBluetoothManager: MockBluetoothPeripheralManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockBluetoothManager = MockBluetoothPeripheralManager()
        motionManager = MotionManager(bluetoothManager: mockBluetoothManager)
        cancellables = []
    }
    
    override func tearDown() {
        motionManager = nil
        mockBluetoothManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testBatteryOptimization() {
        // Simulate low battery
        UIDevice.current.batteryLevel = 0.15
        
        let expectation = XCTestExpectation(description: "Battery optimization enabled")
        
        motionManager.$batteryOptimizationEnabled
            .dropFirst()
            .sink { isEnabled in
                XCTAssertTrue(isEnabled)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        motionManager.checkBatteryLevel()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAccuracyTracking() {
        let motion = CMDeviceMotion()
        // Simulate noisy data
        motion.userAcceleration = CMAcceleration(x: 2.0, y: 2.0, z: 2.0)
        
        let expectation = XCTestExpectation(description: "Low accuracy error")
        
        motionManager.$error
            .dropFirst()
            .sink { error in
                XCTAssertEqual(error, .lowAccuracy)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        motionManager.updateAccuracyTracking(with: motion)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFilteringSettings() {
        let settings = MotionSettings(
            dotCount: 100,
            dotSize: 4.0,
            dotOpacity: 0.3,
            dotBlur: 1.0,
            filterWeight: 0.5,
            minimumMovementThreshold: 0.02,
            velocityThreshold: 0.1,
            maxVelocity: 50.0,
            smoothingFactor: 0.15,
            historySize: 5
        )
        
        motionManager.settings = settings
        
        // Test filtering with known values
        let filtered = motionManager.filterValue(1.0, previous: 0.0)
        XCTAssertEqual(filtered, 0.5, accuracy: 0.001)
    }
}

// Mock Bluetooth Manager for testing
class MockBluetoothPeripheralManager: BluetoothPeripheralManager {
    var sentData: [MotionData] = []
    
    override func sendMotionData(_ data: MotionData) {
        sentData.append(data)
    }
} 