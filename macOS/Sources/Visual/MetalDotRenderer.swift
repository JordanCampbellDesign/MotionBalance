import MetalKit
import simd

class MetalDotRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private var dotPositionsBuffer: MTLBuffer
    private let maxDots = 200
    
    struct Vertex {
        let position: SIMD2<Float>
        let color: SIMD4<Float>
    }
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        // Create vertex data for a single dot (square made of two triangles)
        let vertices = [
            Vertex(position: SIMD2(-1, -1), color: SIMD4(1, 1, 1, 0.3)),
            Vertex(position: SIMD2( 1, -1), color: SIMD4(1, 1, 1, 0.3)),
            Vertex(position: SIMD2(-1,  1), color: SIMD4(1, 1, 1, 0.3)),
            Vertex(position: SIMD2( 1,  1), color: SIMD4(1, 1, 1, 0.3))
        ]
        
        let vertexBufferSize = vertices.count * MemoryLayout<Vertex>.stride
        guard let vertexBuffer = device.makeBuffer(bytes: vertices,
                                                 length: vertexBufferSize,
                                                 options: .storageModeShared) else {
            return nil
        }
        self.vertexBuffer = vertexBuffer
        
        // Create buffer for dot positions
        let positionsBufferSize = maxDots * MemoryLayout<SIMD2<Float>>.stride
        guard let positionsBuffer = device.makeBuffer(length: positionsBufferSize,
                                                    options: .storageModeShared) else {
            return nil
        }
        self.dotPositionsBuffer = positionsBuffer
        
        // Create pipeline state
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            return nil
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            return nil
        }
    }
    
    func updateDotPositions(_ positions: [CGPoint]) {
        let floatPositions = positions.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
        dotPositionsBuffer.contents().copyMemory(from: floatPositions,
                                               byteCount: positions.count * MemoryLayout<SIMD2<Float>>.stride)
    }
    
    func render(in view: MTKView, dotCount: Int) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(dotPositionsBuffer, offset: 0, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangleStrip,
                                   vertexStart: 0,
                                   vertexCount: 4,
                                   instanceCount: dotCount)
        
        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
} 