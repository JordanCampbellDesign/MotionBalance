import Foundation
import CoreMotion
import Combine

class SetupManager: ObservableObject {
    enum SetupStep: Int, CaseIterable {
        case welcome
        case devicePosition
        case calibration
        case bluetoothPairing
        case comfort
        case complete
        
        var title: String {
            switch self {
            case .welcome: return "Welcome to MotionBalance"
            case .devicePosition: return "Device Position"
            case .calibration: return "Calibration"
            case .bluetoothPairing: return "Connect to Mac"
            case .comfort: return "Comfort Settings"
            case .complete: return "Setup Complete"
            }
        }
    }
    
    @Published var currentStep: SetupStep = .welcome
    @Published var isCalibrating = false
    @Published var calibrationProgress: Double = 0
    @Published var deviceOrientation: DeviceOrientation = .unknown
    @Published var canProceed = false
    
    private let motionManager: MotionManager
    private var calibrationData: [MotionData] = []
    private let requiredCalibrationSamples = 100
    private var cancellables: Set<AnyCancellable> = []
    
    init(motionManager: MotionManager) {
        self.motionManager = motionManager
        setupOrientationTracking()
    }
    
    func nextStep() {
        guard let nextIndex = SetupStep.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
              let nextStep = SetupStep(rawValue: nextIndex) else {
            return
        }
        currentStep = nextStep
    }
    
    func startCalibration() {
        isCalibrating = true
        calibrationData.removeAll()
        
        // Start collecting motion data for calibration
        motionManager.startCalibration { [weak self] data in
            guard let self = self else { return }
            self.calibrationData.append(data)
            self.updateCalibrationProgress()
            
            if self.calibrationData.count >= self.requiredCalibrationSamples {
                self.finishCalibration()
            }
        }
    }
    
    private func updateCalibrationProgress() {
        calibrationProgress = Double(calibrationData.count) / Double(requiredCalibrationSamples)
    }
    
    private func finishCalibration() {
        isCalibrating = false
        
        // Calculate optimal settings based on calibration data
        let settings = calculateOptimalSettings()
        motionManager.settings = settings
        
        nextStep()
    }
    
    private func calculateOptimalSettings() -> MotionSettings {
        // Analyze calibration data to determine optimal settings
        let averageMovement = calculateAverageMovement()
        let noiseLevels = calculateNoiseLevels()
        
        return MotionSettings(
            dotCount: calculateOptimalDotCount(for: averageMovement),
            dotSize: calculateOptimalDotSize(for: noiseLevels),
            dotOpacity: 0.3,
            dotBlur: 1.0,
            filterWeight: calculateOptimalFilterWeight(for: noiseLevels),
            minimumMovementThreshold: calculateOptimalThreshold(for: noiseLevels),
            velocityThreshold: 0.1,
            maxVelocity: calculateOptimalMaxVelocity(for: averageMovement),
            smoothingFactor: calculateOptimalSmoothingFactor(for: noiseLevels),
            historySize: 5
        )
    }
    
    private func calculateAverageMovement() -> Double {
        // Calculate RMS of acceleration and rotation
        let accelerations = calibrationData.map { data in
            sqrt(pow(data.userAccelerationX, 2) +
                 pow(data.userAccelerationY, 2) +
                 pow(data.userAccelerationZ, 2))
        }
        
        return accelerations.reduce(0, +) / Double(accelerations.count)
    }
    
    private func calculateNoiseLevels() -> Double {
        // Calculate standard deviation of movement
        let movements = calibrationData.map { data in
            sqrt(pow(data.rotationRateX, 2) +
                 pow(data.rotationRateY, 2) +
                 pow(data.rotationRateZ, 2))
        }
        
        let mean = movements.reduce(0, +) / Double(movements.count)
        let variance = movements.map { pow($0 - mean, 2) }.reduce(0, +) / Double(movements.count)
        
        return sqrt(variance)
    }
    
    // Helper methods to calculate optimal settings based on calibration data
    private func calculateOptimalDotCount(for movement: Double) -> Int {
        // More dots for higher movement levels
        return Int(max(60, min(200, movement * 1000)))
    }
    
    private func calculateOptimalDotSize(for noise: Double) -> Double {
        // Larger dots for higher noise levels
        return max(2.0, min(8.0, 4.0 + noise * 2))
    }
    
    private func calculateOptimalFilterWeight(for noise: Double) -> Double {
        // More aggressive filtering for higher noise
        return max(0.1, min(0.3, 0.2 - noise * 0.1))
    }
    
    private func calculateOptimalThreshold(for noise: Double) -> Double {
        // Higher threshold for noisier environments
        return max(0.005, min(0.02, noise * 0.1))
    }
    
    private func calculateOptimalMaxVelocity(for movement: Double) -> Double {
        // Higher max velocity for more dynamic movement
        return max(30.0, min(70.0, movement * 100))
    }
    
    private func calculateOptimalSmoothingFactor(for noise: Double) -> Double {
        // More smoothing for higher noise levels
        return max(0.1, min(0.3, 0.15 + noise * 0.1))
    }
    
    private func setupOrientationTracking() {
        motionManager.startUpdates()
        
        // Observe motion data to determine orientation
        motionManager.$motionData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                let orientation = DeviceOrientation.determine(from: data.attitude)
                self?.deviceOrientation = orientation
                
                // Only allow proceeding when device is flat
                if self?.currentStep == .devicePosition {
                    self?.canProceed = (orientation == .flat)
                }
            }
            .store(in: &cancellables)
    }
    
    func previousStep() {
        guard let prevIndex = SetupStep.allCases.firstIndex(of: currentStep)?.advanced(by: -1),
              let prevStep = SetupStep(rawValue: prevIndex) else {
            return
        }
        currentStep = prevStep
        updateCanProceed()
    }
    
    private func updateCanProceed() {
        switch currentStep {
        case .welcome:
            canProceed = true
        case .devicePosition:
            canProceed = deviceOrientation == .flat
        case .calibration:
            canProceed = !isCalibrating
        case .bluetoothPairing:
            canProceed = bluetoothManager.isConnected
        case .comfort:
            canProceed = true
        case .complete:
            canProceed = true
        }
    }
    
    // Update observers
    private func setupStateObservers() {
        // Device orientation updates
        motionManager.$motionData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                let orientation = DeviceOrientation.determine(from: data.attitude)
                self?.deviceOrientation = orientation
                self?.updateCanProceed()
            }
            .store(in: &cancellables)
        
        // Bluetooth connection updates
        bluetoothManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateCanProceed()
            }
            .store(in: &cancellables)
    }
} 