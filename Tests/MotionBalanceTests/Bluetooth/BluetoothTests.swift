import XCTest
import CoreBluetooth
@testable import MotionBalance

class BluetoothTests: XCTestCase {
    var centralManager: BluetoothCentralManager!
    var peripheralManager: BluetoothPeripheralManager!
    
    override func setUp() {
        super.setUp()
        centralManager = BluetoothCentralManager()
        peripheralManager = BluetoothPeripheralManager()
    }
    
    func testConnectionFlow() {
        let connectionExpectation = XCTestExpectation(description: "Bluetooth connection established")
        
        centralManager.onConnectionStateChanged = { state in
            if state == .connected {
                connectionExpectation.fulfill()
            }
        }
        
        peripheralManager.startAdvertising()
        centralManager.startScanning()
        
        wait(for: [connectionExpectation], timeout: 5.0)
        XCTAssertEqual(centralManager.connectionState, .connected)
    }
    
    func testDataTransmission() {
        let dataReceivedExpectation = XCTestExpectation(description: "Motion data received")
        
        // Setup connection first
        testConnectionFlow()
        
        centralManager.onMotionDataReceived = { data in
            dataReceivedExpectation.fulfill()
        }
        
        let testData = MotionData.zero
        peripheralManager.sendMotionData(testData)
        
        wait(for: [dataReceivedExpectation], timeout: 2.0)
    }
} 