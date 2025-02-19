import CoreMotion
import Combine

enum MotionError: Error {
    case sensorUnavailable
    case sensorError(Error)
    case insufficientPermissions
    case lowAccuracy
    case batteryLow
    
    var localizedDescription: String {
        switch self {
        case .sensorUnavailable:
            return "Motion sensors are not available on this device"
        case .sensorError(let error):
            return "Sensor error: \(error.localizedDescription)"
        case .insufficientPermissions:
            return "Motion sensor access not authorized"
        case .lowAccuracy:
            return "Motion sensor accuracy is too low"
        case .batteryLow:
            return "Battery level too low for continuous motion tracking"
        }
    }
}

typealias CalibrationCallback = (MotionData) -> Void

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let bluetoothManager: BluetoothPeripheralManager
    private var cancellables = Set<AnyCancellable>()
    
    // Motion filtering properties
    private var lastMotionData: MotionData = .zero
    @Published var settings: MotionSettings {
        didSet {
            updateSensorConfiguration()
        }
    }
    
    // State tracking
    @Published var motionData: MotionData = .zero
    @Published var error: MotionError?
    @Published var isRunning = false
    @Published private(set) var batteryOptimizationEnabled = false
    
    // Battery optimization
    private let batteryUpdateInterval: TimeInterval = 30
    private let minimumBatteryLevel: Float = 0.2
    private var lastBatteryCheck = Date()
    private var batteryMonitorTimer: Timer?
    
    // Accuracy tracking
    private var accuracyBuffer: [Double] = []
    private let accuracyBufferSize = 100
    private let minimumAccuracyThreshold = 0.8
    
    // Add new properties
    private var calibrationCallback: CalibrationCallback?
    private var isCalibrating = false
    
    // Safety monitoring
    @Published private(set) var safetyStatus: SafetyStatus = .normal {
        didSet {
            if oldValue != safetyStatus {
                FeedbackService.shared.provideFeedback(for: safetyStatus)
            }
        }
    }
    @Published private(set) var userWellbeing: WellbeingStatus = .good {
        didSet {
            if oldValue != userWellbeing {
                FeedbackService.shared.provideFeedback(for: userWellbeing)
            }
        }
    }
    private var excessiveMotionCount = 0
    private var usageStartTime: Date?
    private let recommendedBreakInterval: TimeInterval = 20 * 60 // 20 minutes
    private let maxContinuousUsage: TimeInterval = 60 * 60 // 1 hour
    
    // Effectiveness tracking
    @Published private(set) var effectivenessMetrics: EffectivenessMetrics
    private var motionIntensityBuffer: [Double] = []
    private let metricsUpdateInterval: TimeInterval = 60 // 1 minute
    
    enum SafetyStatus {
        case normal
        case warning(String)
        case excessive(String)
        
        var message: String {
            switch self {
            case .normal:
                return "Motion levels are normal"
            case .warning(let msg), .excessive(let msg):
                return msg
            }
        }
    }
    
    enum WellbeingStatus {
        case good
        case needsBreak(TimeInterval)
        case stopRecommended
        
        var message: String {
            switch self {
            case .good:
                return "Everything looks good"
            case .needsBreak(let minutes):
                return "Consider taking a break in \(Int(minutes/60)) minutes"
            case .stopRecommended:
                return "You've been using the app for a while. Consider stopping for today."
            }
        }
    }
    
    struct EffectivenessMetrics {
        var motionReductionPercent: Double = 0
        var averageLatency: TimeInterval = 0
        var stabilityScore: Double = 0
        var userComfortRating: Int?
        var sessionDuration: TimeInterval = 0
        
        mutating func update(with motionData: MotionData, visualLatency: TimeInterval) {
            // Update metrics based on new data
            self.averageLatency = (self.averageLatency + visualLatency) / 2
            // ... other updates ...
        }
    }
    
    init(bluetoothManager: BluetoothPeripheralManager, settings: MotionSettings = .default) {
        self.bluetoothManager = bluetoothManager
        self.settings = settings
        queue.name = "com.motionbalance.motionqueue"
        queue.qualityOfService = .userInteractive
        
        setupBatteryMonitoring()
        setupNotifications()
        self.effectivenessMetrics = EffectivenessMetrics()
        setupSafetyMonitoring()
        startUsageTracking()
    }
    
    func startUpdates() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw MotionError.sensorUnavailable
        }
        
        // Check authorization if needed (iOS 17+)
        if #available(iOS 17.0, *) {
            let status = await CMMotionActivityManager.authorizationStatus()
            guard status == .authorized else {
                throw MotionError.insufficientPermissions
            }
        }
        
        updateSensorConfiguration()
        setupMotionUpdates()
        isRunning = true
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
    }
    
    private func updateSensorConfiguration() {
        // Adjust update interval based on battery optimization
        motionManager.deviceMotionUpdateInterval = batteryOptimizationEnabled ? 1.0 / 30.0 : 1.0 / 60.0
        
        // Configure sensor usage
        motionManager.showsDeviceMovementDisplay = true
        motionManager.deviceMotionUpdateInterval = settings.filterWeight
    }
    
    private func setupMotionUpdates() {
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = .sensorError(error)
                }
                return
            }
            
            guard let motion = motion else { return }
            
            // Check sensor accuracy
            self.updateAccuracyTracking(with: motion)
            
            let filteredData = self.filterMotionData(
                pitch: motion.attitude.pitch,
                roll: motion.attitude.roll,
                yaw: motion.attitude.yaw,
                rotationRateX: motion.rotationRate.x,
                rotationRateY: motion.rotationRate.y,
                rotationRateZ: motion.rotationRate.z,
                userAccelerationX: motion.userAcceleration.x,
                userAccelerationY: motion.userAcceleration.y,
                userAccelerationZ: motion.userAcceleration.z
            )
            
            DispatchQueue.main.async {
                self.motionData = filteredData
                
                if self.isCalibrating {
                    self.calibrationCallback?(filteredData)
                } else if self.error == nil {
                    self.bluetoothManager.sendMotionData(filteredData)
                }
            }
        }
    }
    
    private func updateAccuracyTracking(with motion: CMDeviceMotion) {
        // Calculate a simple accuracy metric based on noise levels
        let accelerationMagnitude = sqrt(
            pow(motion.userAcceleration.x, 2) +
            pow(motion.userAcceleration.y, 2) +
            pow(motion.userAcceleration.z, 2)
        )
        
        accuracyBuffer.append(accelerationMagnitude)
        if accuracyBuffer.count > accuracyBufferSize {
            accuracyBuffer.removeFirst()
        }
        
        // Check if motion data is too noisy
        let averageNoise = accuracyBuffer.reduce(0, +) / Double(accuracyBuffer.count)
        if averageNoise > minimumAccuracyThreshold {
            DispatchQueue.main.async {
                self.error = .lowAccuracy
            }
        } else {
            DispatchQueue.main.async {
                if self.error == .lowAccuracy {
                    self.error = nil
                }
            }
        }
    }
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        batteryMonitorTimer = Timer.scheduledTimer(withTimeInterval: batteryUpdateInterval, repeats: true) { [weak self] _ in
            self?.checkBatteryLevel()
        }
        
        checkBatteryLevel()
    }
    
    private func checkBatteryLevel() {
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel < minimumBatteryLevel {
            error = .batteryLow
            batteryOptimizationEnabled = true
        } else if batteryOptimizationEnabled && batteryLevel > minimumBatteryLevel + 0.1 {
            batteryOptimizationEnabled = false
            error = nil
        }
        
        updateSensorConfiguration()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.batteryOptimizationEnabled = true
                self?.updateSensorConfiguration()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkBatteryLevel() // This will reset optimization if battery is good
            }
            .store(in: &cancellables)
    }
    
    private func filterMotionData(
        pitch: Double, roll: Double, yaw: Double,
        rotationRateX: Double, rotationRateY: Double, rotationRateZ: Double,
        userAccelerationX: Double, userAccelerationY: Double, userAccelerationZ: Double
    ) -> MotionData {
        // Apply low-pass filter and threshold using current settings
        let filteredRotationX = filterValue(rotationRateX, previous: lastMotionData.rotationRateX)
        let filteredRotationY = filterValue(rotationRateY, previous: lastMotionData.rotationRateY)
        let filteredRotationZ = filterValue(rotationRateZ, previous: lastMotionData.rotationRateZ)
        
        let filteredAccelX = filterValue(userAccelerationX, previous: lastMotionData.userAccelerationX)
        let filteredAccelY = filterValue(userAccelerationY, previous: lastMotionData.userAccelerationY)
        let filteredAccelZ = filterValue(userAccelerationZ, previous: lastMotionData.userAccelerationZ)
        
        let newMotionData = MotionData(
            pitch: filterValue(pitch, previous: lastMotionData.pitch),
            roll: filterValue(roll, previous: lastMotionData.roll),
            yaw: filterValue(yaw, previous: lastMotionData.yaw),
            rotationRateX: filteredRotationX,
            rotationRateY: filteredRotationY,
            rotationRateZ: filteredRotationZ,
            userAccelerationX: filteredAccelX,
            userAccelerationY: filteredAccelY,
            userAccelerationZ: filteredAccelZ,
            timestamp: Date()
        )
        
        lastMotionData = newMotionData
        return newMotionData
    }
    
    private func filterValue(_ current: Double, previous: Double) -> Double {
        // Apply threshold to reduce noise using current settings
        if abs(current - previous) < settings.minimumMovementThreshold {
            return previous
        }
        
        // Low-pass filter using current settings
        return previous + (current - previous) * settings.filterWeight
    }
    
    func startCalibration(_ callback: @escaping CalibrationCallback) {
        calibrationCallback = callback
        isCalibrating = true
        
        // Use higher precision during calibration
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        setupMotionUpdates()
    }
    
    func stopCalibration() {
        isCalibrating = false
        calibrationCallback = nil
        updateSensorConfiguration() // Reset to normal settings
    }
    
    private func setupSafetyMonitoring() {
        // Monitor motion data for safety thresholds
        $motionData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.checkSafetyThresholds(for: data)
                self?.updateEffectivenessMetrics(with: data)
            }
            .store(in: &cancellables)
    }
    
    private func checkSafetyThresholds(for data: MotionData) {
        let totalAcceleration = sqrt(
            pow(data.userAccelerationX, 2) +
            pow(data.userAccelerationY, 2) +
            pow(data.userAccelerationZ, 2)
        )
        
        let totalRotation = sqrt(
            pow(data.rotationRateX, 2) +
            pow(data.rotationRateY, 2) +
            pow(data.rotationRateZ, 2)
        )
        
        if totalAcceleration > 3.0 || totalRotation > 5.0 {
            excessiveMotionCount += 1
            if excessiveMotionCount > 10 {
                safetyStatus = .excessive("Motion is too intense. Consider slowing down.")
            } else {
                safetyStatus = .warning("Motion is becoming intense")
            }
        } else {
            excessiveMotionCount = max(0, excessiveMotionCount - 1)
            if excessiveMotionCount == 0 {
                safetyStatus = .normal
            }
        }
    }
    
    private func startUsageTracking() {
        usageStartTime = Date()
        
        // Check wellbeing status periodically
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateWellbeingStatus()
        }
    }
    
    private func updateWellbeingStatus() {
        guard let startTime = usageStartTime else { return }
        
        let usageDuration = Date().timeIntervalSince(startTime)
        effectivenessMetrics.sessionDuration = usageDuration
        
        switch usageDuration {
        case 0..<recommendedBreakInterval:
            userWellbeing = .good
        case recommendedBreakInterval..<maxContinuousUsage:
            let timeUntilMax = maxContinuousUsage - usageDuration
            userWellbeing = .needsBreak(timeUntilMax)
        default:
            userWellbeing = .stopRecommended
        }
    }
    
    private func updateEffectivenessMetrics(with data: MotionData) {
        // Calculate motion intensity
        let intensity = sqrt(
            pow(data.userAccelerationX, 2) +
            pow(data.userAccelerationY, 2) +
            pow(data.userAccelerationZ, 2)
        )
        
        motionIntensityBuffer.append(intensity)
        if motionIntensityBuffer.count > 600 { // 10 minutes of data at 1Hz
            motionIntensityBuffer.removeFirst()
        }
        
        // Calculate stability score
        let averageIntensity = motionIntensityBuffer.reduce(0, +) / Double(motionIntensityBuffer.count)
        let stabilityScore = 1.0 - min(1.0, averageIntensity / 2.0)
        
        effectivenessMetrics.stabilityScore = stabilityScore
        
        // Estimate motion reduction based on visual compensation
        let compensationLatency = Date().timeIntervalSince(data.timestamp)
        effectivenessMetrics.update(with: data, visualLatency: compensationLatency)
    }
    
    func submitComfortRating(_ rating: Int) {
        effectivenessMetrics.userComfortRating = rating
        // Could send to analytics here
    }
    
    func resetSession() {
        usageStartTime = Date()
        motionIntensityBuffer.removeAll()
        excessiveMotionCount = 0
        effectivenessMetrics = EffectivenessMetrics()
        safetyStatus = .normal
        userWellbeing = .good
    }
    
    deinit {
        stopUpdates()
        batteryMonitorTimer?.invalidate()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }
} 