import CoreBluetooth
import Combine

class BluetoothPeripheralManager: NSObject, ObservableObject {
    private var peripheralManager: CBPeripheralManager!
    private let motionCharacteristicUUID = CBUUID(string: "1A2B3C4D-1E2E-3E4E-5E6E-7E8E9EAEBECE")
    private let serviceUUID = CBUUID(string: "1A2B3C4D-1E2E-3E4E-5E6E-7E8E9EAEBECF")
    private var motionCharacteristic: CBMutableCharacteristic!
    private var motionService: CBMutableService!
    
    @Published var isAdvertising = false
    private var motionManager: MotionManager?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var error: String?
    @Published var isReady = false
    private var retryCount = 0
    private let maxRetries = 3
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        setupService()
    }
    
    private func setupService() {
        motionCharacteristic = CBMutableCharacteristic(
            type: motionCharacteristicUUID,
            properties: [.notify, .read],
            value: nil,
            permissions: [.readable]
        )
        
        motionService = CBMutableService(type: serviceUUID, primary: true)
        motionService.characteristics = [motionCharacteristic]
    }
    
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else { return }
        
        peripheralManager.add(motionService)
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "MotionBalance"
        ]
        
        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
    }
    
    func sendMotionData(_ data: MotionData) {
        guard isReady, let encodedData = try? JSONEncoder().encode(data) else {
            return
        }
        
        let success = peripheralManager.updateValue(
            encodedData,
            for: motionCharacteristic,
            onSubscribedCentrals: nil
        )
        
        if !success {
            // Queue is full, wait and retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.sendMotionData(data)
            }
        }
    }
    
    private func retryAdvertising() {
        guard retryCount < maxRetries else {
            error = "Failed to start advertising after multiple attempts"
            return
        }
        
        retryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.startAdvertising()
        }
    }
}

extension BluetoothPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            startAdvertising()
        case .poweredOff:
            error = "Bluetooth is turned off"
            isAdvertising = false
            isReady = false
        case .unauthorized:
            error = "Bluetooth permission denied"
            isAdvertising = false
            isReady = false
        case .unsupported:
            error = "Bluetooth is not supported"
            isAdvertising = false
            isReady = false
        default:
            error = "Bluetooth is not available"
            isAdvertising = false
            isReady = false
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            self.error = "Failed to add service: \(error.localizedDescription)"
            retryAdvertising()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            self.error = "Failed to start advertising: \(error.localizedDescription)"
            retryAdvertising()
        } else {
            isReady = true
            retryCount = 0
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Mac connected and subscribed")
        isReady = true
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Mac unsubscribed")
    }
} 