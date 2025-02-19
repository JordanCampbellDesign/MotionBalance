import Foundation
import Combine

class SetupCompletionChecker: ObservableObject {
    static let shared = SetupCompletionChecker()
    
    @Published private(set) var completionStatus: CompletionStatus = .notStarted
    @Published private(set) var stepStatuses: [StepStatus] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    enum CompletionStatus {
        case notStarted
        case inProgress(progress: Double)
        case completed
        case needsAttention([Issue])
        
        struct Issue {
            let step: TutorialStep
            let description: String
            let recommendation: String
        }
    }
    
    struct StepStatus {
        let step: TutorialStep
        var isCompleted: Bool
        var validationPassed: Bool
        var timestamp: Date?
    }
    
    init() {
        setupStepTracking()
    }
    
    private func setupStepTracking() {
        // Initialize step statuses
        stepStatuses = TutorialStep.allSteps.map { step in
            StepStatus(step: step, isCompleted: false, validationPassed: false)
        }
        
        // Monitor step completion
        $stepStatuses
            .map { statuses -> CompletionStatus in
                let completedCount = statuses.filter { $0.isCompleted && $0.validationPassed }.count
                let progress = Double(completedCount) / Double(statuses.count)
                
                if completedCount == statuses.count {
                    return .completed
                }
                
                let issues = statuses
                    .filter { !$0.validationPassed && $0.isCompleted }
                    .map { status in
                        CompletionStatus.Issue(
                            step: status.step,
                            description: "Validation failed for \(status.step.title)",
                            recommendation: "Please revisit this step"
                        )
                    }
                
                if !issues.isEmpty {
                    return .needsAttention(issues)
                }
                
                return .inProgress(progress: progress)
            }
            .assign(to: &$completionStatus)
    }
    
    func validateStep(_ step: TutorialStep) async -> Bool {
        guard let rule = step.validationRule else { return true }
        
        switch rule {
        case .deviceFlat:
            return await validateDevicePosition()
        case .bluetoothConnected:
            return await validateBluetoothConnection()
        case .calibrationComplete:
            return await validateCalibration()
        case .settingsConfigured:
            return validateSettings()
        }
    }
    
    private func validateDevicePosition() async -> Bool {
        // Implementation of device position validation
        return true
    }
    
    private func validateBluetoothConnection() async -> Bool {
        // Implementation of Bluetooth connection validation
        return true
    }
    
    private func validateCalibration() async -> Bool {
        // Implementation of calibration validation
        return true
    }
    
    private func validateSettings() -> Bool {
        // Implementation of settings validation
        return true
    }
} 