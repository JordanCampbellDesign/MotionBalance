import SwiftUI

struct SessionSummaryView: View {
    let metrics: MotionManager.EffectivenessMetrics
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section("Session Statistics") {
                    StatRow(
                        title: "Duration",
                        value: formatDuration(metrics.sessionDuration)
                    )
                    
                    StatRow(
                        title: "Average Motion Reduction",
                        value: "\(Int(metrics.motionReductionPercent * 100))%"
                    )
                    
                    StatRow(
                        title: "Average Response Time",
                        value: String(format: "%.1f ms", metrics.averageLatency * 1000)
                    )
                    
                    StatRow(
                        title: "Overall Stability",
                        value: String(format: "%.1f/10", metrics.stabilityScore * 10)
                    )
                }
                
                if let rating = metrics.userComfortRating {
                    Section("User Feedback") {
                        StatRow(
                            title: "Comfort Rating",
                            value: String(repeating: "★", count: rating)
                        )
                    }
                }
                
                Section {
                    Button("Start New Session") {
                        onDismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
} 