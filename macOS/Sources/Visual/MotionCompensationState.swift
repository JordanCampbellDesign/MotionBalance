import SwiftUI
import Combine

class MotionCompensationState: ObservableObject {
    @Published var dotPositions: [CGPoint] = []
    private var screenSize: CGSize
    private var cancellables = Set<AnyCancellable>()
    private let bluetoothManager: BluetoothCentralManager
    private let settings: SettingsManager
    
    // Interpolation properties
    private var currentVelocity: CGPoint = .zero
    private var targetVelocity: CGPoint = .zero
    private var velocityHistory: [CGPoint] = []
    private var displayLink: CVDisplayLink?
    private let interpolationQueue = DispatchQueue(label: "com.motionbalance.interpolation")
    
    init(bluetoothManager: BluetoothCentralManager, settings: SettingsManager) {
        self.bluetoothManager = bluetoothManager
        self.settings = settings
        self.screenSize = NSScreen.main?.frame.size ?? .zero
        
        setupDots()
        setupMotionSubscription()
        setupDisplayLink()
        
        // Listen for settings changes
        settings.$settings
            .sink { [weak self] _ in
                self?.setupDots() // Recreate dots when count changes
            }
            .store(in: &cancellables)
    }
    
    private func setupDots() {
        dotPositions = (0..<settings.settings.dotCount).map { _ in
            CGPoint(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: 0...screenSize.height)
            )
        }
    }
    
    private func setupDisplayLink() {
        var displayLink: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        self.displayLink = displayLink
        
        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, displayLinkContext -> CVReturn in
            let state = unsafeBitCast(displayLinkContext, to: MotionCompensationState.self)
            state.interpolationQueue.async {
                state.updateInterpolation()
            }
            return kCVReturnSuccess
        }
        
        CVDisplayLinkSetOutputCallback(displayLink!, callback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink!)
    }
    
    private func setupMotionSubscription() {
        bluetoothManager.$motionData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] motionData in
                self?.updateTargetVelocity(with: motionData)
            }
            .store(in: &cancellables)
    }
    
    private func updateTargetVelocity(with motionData: MotionData) {
        let newVelocity = CGPoint(
            x: -CGFloat(motionData.rotationRateX * 10),
            y: -CGFloat(motionData.rotationRateY * 10)
        )
        
        // Add to history with current settings
        velocityHistory.append(newVelocity)
        if velocityHistory.count > settings.settings.historySize {
            velocityHistory.removeFirst()
        }
        
        // Calculate average velocity
        let avgVelocity = velocityHistory.reduce(CGPoint.zero) { sum, velocity in
            CGPoint(x: sum.x + velocity.x, y: sum.y + velocity.y)
        }
        let count = CGFloat(velocityHistory.count)
        targetVelocity = CGPoint(
            x: avgVelocity.x / count,
            y: avgVelocity.y / count
        )
        
        // Apply threshold and limit maximum velocity using current settings
        if abs(targetVelocity.x) < settings.settings.velocityThreshold { targetVelocity.x = 0 }
        if abs(targetVelocity.y) < settings.settings.velocityThreshold { targetVelocity.y = 0 }
        
        targetVelocity.x = min(settings.settings.maxVelocity, max(-settings.settings.maxVelocity, targetVelocity.x))
        targetVelocity.y = min(settings.settings.maxVelocity, max(-settings.settings.maxVelocity, targetVelocity.y))
    }
    
    private func updateInterpolation() {
        // Interpolate between current and target velocity using current settings
        let dx = targetVelocity.x - currentVelocity.x
        let dy = targetVelocity.y - currentVelocity.y
        
        currentVelocity.x += dx * settings.settings.smoothingFactor
        currentVelocity.y += dy * settings.settings.smoothingFactor
        
        // Update positions with interpolated velocity
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateDotPositions()
        }
    }
    
    private func updateDotPositions() {
        dotPositions = dotPositions.map { point in
            var newPoint = point
            newPoint.x += currentVelocity.x
            newPoint.y += currentVelocity.y
            
            // Wrap around screen edges
            newPoint.x = (newPoint.x + screenSize.width).truncatingRemainder(dividingBy: screenSize.width)
            newPoint.y = (newPoint.y + screenSize.height).truncatingRemainder(dividingBy: screenSize.height)
            
            return newPoint
        }
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
} 