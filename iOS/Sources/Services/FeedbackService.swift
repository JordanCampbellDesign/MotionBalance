import Foundation
import UIKit
import UserNotifications

class FeedbackService {
    static let shared = FeedbackService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func provideFeedback(for status: MotionManager.SafetyStatus) {
        switch status {
        case .normal:
            impactGenerator.impactOccurred(intensity: 0.3)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            scheduleNotification(
                title: "Motion Warning",
                body: status.message,
                identifier: "motion-warning"
            )
        case .excessive:
            notificationGenerator.notificationOccurred(.error)
            scheduleNotification(
                title: "Excessive Motion",
                body: status.message,
                identifier: "motion-excessive"
            )
        }
    }
    
    func provideFeedback(for status: MotionManager.WellbeingStatus) {
        switch status {
        case .good:
            break // No feedback needed
        case .needsBreak:
            notificationGenerator.notificationOccurred(.warning)
            scheduleNotification(
                title: "Break Recommended",
                body: status.message,
                identifier: "break-needed"
            )
        case .stopRecommended:
            notificationGenerator.notificationOccurred(.error)
            scheduleNotification(
                title: "Session Limit Reached",
                body: status.message,
                identifier: "session-limit"
            )
        }
    }
    
    private func scheduleNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }
} 