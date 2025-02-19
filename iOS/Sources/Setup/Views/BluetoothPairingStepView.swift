import SwiftUI

struct BluetoothPairingStepView: View {
    @ObservedObject var bluetoothManager: BluetoothPeripheralManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: connectionIcon)
                .font(.system(size: 60))
                .foregroundColor(connectionColor)
                .symbolEffect(.pulse, options: .repeating, value: bluetoothManager.isScanning)
            
            Text(connectionStatus)
                .font(.headline)
            
            if !bluetoothManager.isConnected {
                Button(action: bluetoothManager.startAdvertising) {
                    Text("Start Pairing")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            Text(connectionInstructions)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var connectionIcon: String {
        if bluetoothManager.isConnected {
            return "macbook.and.iphone"
        } else if bluetoothManager.isScanning {
            return "antenna.radiowaves.left.and.right"
        } else {
            return "antenna.radiowaves.left.and.right.slash"
        }
    }
    
    private var connectionColor: Color {
        if bluetoothManager.isConnected {
            return .green
        } else if bluetoothManager.isScanning {
            return .blue
        } else {
            return .red
        }
    }
    
    private var connectionStatus: String {
        if bluetoothManager.isConnected {
            return "Connected to Mac"
        } else if bluetoothManager.isScanning {
            return "Searching for Mac..."
        } else {
            return "Not Connected"
        }
    }
    
    private var connectionInstructions: String {
        if bluetoothManager.isConnected {
            return "Successfully connected to your Mac"
        } else if bluetoothManager.isScanning {
            return "Make sure your Mac app is running and Bluetooth is enabled"
        } else {
            return "Tap Start Pairing to connect to your Mac"
        }
    }
} 