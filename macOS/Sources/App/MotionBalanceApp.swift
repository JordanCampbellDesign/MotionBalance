import SwiftUI
import FirebaseCore

@main
struct MotionBalanceApp: App {
    @StateObject private var bluetoothManager = BluetoothCentralManager()
    private let overlayManager: OverlayWindowManager
    
    init() {
        FirebaseApp.configure()
        overlayManager = OverlayWindowManager(bluetoothManager: bluetoothManager)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(bluetoothManager: bluetoothManager)
                .onAppear {
                    overlayManager.show()
                }
        }
    }
} 