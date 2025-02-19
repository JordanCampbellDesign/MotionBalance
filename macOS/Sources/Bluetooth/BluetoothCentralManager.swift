import CoreBluetooth
import Combine

class BluetoothCentralManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private let motionCharacteristicUUID = CBUUID(string: "1A2B3C4D-1E2E-3E4E-5E6E-7E8E9EAEBECE")
    private let serviceUUID = CBUUID(string: "1A2B3C4D-1E2E-3E4E-5E6E-7E8E9EAEBECF")
    
    @Published var discoveredPeripheral: CBPeripheral?
    @Published var motionData: MotionData = .zero
    @Published var connectionState: ConnectionState = .disconnected {
        didSet {
            AnalyticsService.shared.trackConnectionState(state: connectionState)
        }
    }
    @Published var error: String?
    
    private var motionCharacteristic: CBCharacteristic?
    private var reconnectTimer: Timer?
    private let reconnectInterval: TimeInterval = 5.0
    
    enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        connectionState = .scanning
        error = nil
        
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        
        // Auto-retry scanning after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            if self?.connectionState == .scanning {
                self?.restartScanning()
            }
        }
    }
    
    private func restartScanning() {
        centralManager.stopScan()
        startScanning()
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: false) { [weak self] _ in
            self?.startScanning()
        }
    }
    
    private func handleError(_ error: Error, operation: String) {
        self.error = "\(operation) failed: \(error.localizedDescription)"
        connectionState = .disconnected
        scheduleReconnect()
        AnalyticsService.shared.trackError(
            domain: "bluetooth_\(operation.lowercased())",
            description: error.localizedDescription
        )
    }
    
    private func connect(to peripheral: CBPeripheral) {
        connectionState = .connecting
        centralManager.connect(peripheral, options: nil)
    }
}

extension BluetoothCentralManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            error = "Bluetooth is turned off"
            connectionState = .disconnected
        case .unauthorized:
            error = "Bluetooth permission denied"
            connectionState = .disconnected
        case .unsupported:
            error = "Bluetooth is not supported"
            connectionState = .disconnected
        default:
            error = "Bluetooth is not available"
            connectionState = .disconnected
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripheral = peripheral
        central.stopScan()
        connect(to: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            handleError(error, operation: "Connection")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        if error != nil {
            scheduleReconnect()
        }
    }
}

extension BluetoothCentralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            handleError(error, operation: "Service discovery")
            return
        }
        guard let service = peripheral.services?.first else {
            handleError(NSError(domain: "com.motionbalance", code: -1, userInfo: [NSLocalizedDescriptionKey: "No services found"]), operation: "Service discovery")
            return
        }
        peripheral.discoverCharacteristics([motionCharacteristicUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            handleError(error, operation: "Characteristic discovery")
            return
        }
        guard let characteristic = service.characteristics?.first else {
            handleError(NSError(domain: "com.motionbalance", code: -1, userInfo: [NSLocalizedDescriptionKey: "No characteristics found"]), operation: "Characteristic discovery")
            return
        }
        motionCharacteristic = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                   error: Error?) {
        guard let data = characteristic.value,
              let motionData = try? JSONDecoder().decode(MotionData.self, from: data) else { return }
        self.motionData = motionData
    }
} 