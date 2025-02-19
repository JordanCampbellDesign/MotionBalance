import Foundation

class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    @Published var analyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: "analyticsEnabled")
            if !analyticsEnabled {
                clearAnalyticsData()
            }
        }
    }
    
    private init() {
        self.analyticsEnabled = UserDefaults.standard.bool(forKey: "analyticsEnabled")
    }
    
    private func clearAnalyticsData() {
        // Clear any cached analytics data
        Analytics.resetAnalyticsData()
    }
} 