import AppKit
import SwiftUI

class OverlayWindowManager {
    private var window: NSWindow?
    private let motionState: MotionCompensationState
    private let settings: SettingsManager
    
    init(bluetoothManager: BluetoothCentralManager, settings: SettingsManager) {
        self.motionState = MotionCompensationState(bluetoothManager: bluetoothManager, settings: settings)
        self.settings = settings
        setupWindow()
    }
    
    private func setupWindow() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(
            rootView: MotionCompensationView(motionState: motionState, settings: settings)
        )
        window.contentView = hostingView
        
        self.window = window
    }
    
    func show() {
        window?.orderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
} 