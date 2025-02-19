import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetoothManager: BluetoothCentralManager
    @StateObject private var settings = SettingsManager()
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            HStack {
                ConnectionStatusView(bluetoothManager: bluetoothManager)
                Spacer()
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gear")
                }
            }
            Spacer()
        }
        .frame(width: 200, height: 100)
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: settings)
        }
    }
} 