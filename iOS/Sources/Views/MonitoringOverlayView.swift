import SwiftUI

struct MonitoringOverlayView: View {
    @ObservedObject var motionManager: MotionManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Safety Status
            SafetyStatusView(status: motionManager.safetyStatus)
            
            // Wellbeing Status
            WellbeingStatusView(status: motionManager.userWellbeing)
            
            // Metrics
            MetricsView(metrics: motionManager.effectivenessMetrics)
            
            // Comfort Rating
            if motionManager.effectivenessMetrics.userComfortRating == nil {
                ComfortRatingView(onRating: motionManager.submitComfortRating)
            }
        }
        .padding()
        .background(backgroundStyle)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    private var backgroundStyle: some View {
        colorScheme == .dark ?
            Color.black.opacity(0.8) :
            Color.white.opacity(0.9)
    }
}

struct SafetyStatusView: View {
    let status: MotionManager.SafetyStatus
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            Text(status.message)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var statusIcon: String {
        switch status {
        case .normal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .excessive: return "xmark.octagon.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .normal: return .green
        case .warning: return .yellow
        case .excessive: return .red
        }
    }
}

struct WellbeingStatusView: View {
    let status: MotionManager.WellbeingStatus
    
    var body: some View {
        HStack {
            Image(systemName: wellbeingIcon)
                .foregroundColor(wellbeingColor)
            
            Text(status.message)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var wellbeingIcon: String {
        switch status {
        case .good: return "heart.fill"
        case .needsBreak: return "timer"
        case .stopRecommended: return "hand.raised.fill"
        }
    }
    
    private var wellbeingColor: Color {
        switch status {
        case .good: return .green
        case .needsBreak: return .yellow
        case .stopRecommended: return .red
        }
    }
}

struct MetricsView: View {
    let metrics: MotionManager.EffectivenessMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MetricRow(
                icon: "chart.line.downtrend.xyaxis",
                label: "Motion Reduction",
                value: "\(Int(metrics.motionReductionPercent * 100))%"
            )
            
            MetricRow(
                icon: "clock",
                label: "Average Latency",
                value: String(format: "%.1f ms", metrics.averageLatency * 1000)
            )
            
            MetricRow(
                icon: "gauge",
                label: "Stability Score",
                value: String(format: "%.1f", metrics.stabilityScore * 10)
            )
            
            MetricRow(
                icon: "timer",
                label: "Session Duration",
                value: sessionDurationString
            )
        }
    }
    
    private var sessionDurationString: String {
        let minutes = Int(metrics.sessionDuration / 60)
        return "\(minutes)m"
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct ComfortRatingView: View {
    let onRating: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("How are you feeling?")
                .font(.caption)
            
            HStack {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        onRating(rating)
                    } label: {
                        Image(systemName: "face.\(ratingIcon(for: rating))")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rate comfort level \(rating)")
                }
            }
        }
    }
    
    private func ratingIcon(for rating: Int) -> String {
        switch rating {
        case 1: return "dizzy"
        case 2: return "sad"
        case 3: return "neutral"
        case 4: return "happy"
        case 5: return "satisfied"
        default: return "neutral"
        }
    }
} 