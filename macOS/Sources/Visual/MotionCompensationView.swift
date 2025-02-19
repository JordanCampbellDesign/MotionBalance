import SwiftUI
import MetalKit

struct MotionCompensationView: View {
    @ObservedObject var motionState: MotionCompensationState
    @ObservedObject var settings: SettingsManager
    
    var body: some View {
        MetalDotView(
            dotPositions: motionState.dotPositions,
            dotCount: settings.settings.dotCount
        )
        .ignoresSafeArea()
    }
}

struct MetalDotView: NSViewRepresentable {
    let dotPositions: [CGPoint]
    let dotCount: Int
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.enableSetNeedsDisplay = true
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0.01)
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.dotPositions = dotPositions
        context.coordinator.dotCount = dotCount
        nsView.setNeedsDisplay(nsView.bounds)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(renderer: MetalDotRenderer()!)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        let renderer: MetalDotRenderer
        var dotPositions: [CGPoint] = []
        var dotCount: Int = 0
        
        init(renderer: MetalDotRenderer) {
            self.renderer = renderer
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            renderer.updateDotPositions(dotPositions)
            renderer.render(in: view, dotCount: dotCount)
        }
    }
} 