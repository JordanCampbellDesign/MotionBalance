import SwiftUI

struct ConnectionStatusView: View {
    @ObservedObject var bluetoothManager: BluetoothCentralManager
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
            }
            if let error = bluetoothManager.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch bluetoothManager.connectionState {
        case .connected:
            return .green
        case .connecting, .scanning:
            return .yellow
        case .disconnected:
            return .red
        }
    }
    
    private var statusText: String {
        switch bluetoothManager.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .scanning:
            return "Searching..."
        case .disconnected:
            return "Disconnected"
        }
    }
} 