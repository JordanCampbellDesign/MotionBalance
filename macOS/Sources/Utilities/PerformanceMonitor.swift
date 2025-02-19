import Foundation
import QuartzCore

class PerformanceMonitor: ObservableObject {
    @Published var frameRate: Double = 0
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: UInt64 = 0
    
    private var displayLink: CVDisplayLink?
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private let updateInterval: CFTimeInterval = 1.0
    
    private var lastAnalyticsUpdate: Date = Date()
    private let analyticsInterval: TimeInterval = 60 // Log every minute
    
    init() {
        setupDisplayLink()
        startMonitoring()
    }
    
    private func setupDisplayLink() {
        var displayLink: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        self.displayLink = displayLink
        
        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, displayLinkContext -> CVReturn in
            let monitor = unsafeBitCast(displayLinkContext, to: PerformanceMonitor.self)
            monitor.updateMetrics()
            return kCVReturnSuccess
        }
        
        CVDisplayLinkSetOutputCallback(displayLink!, callback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    }
    
    func startMonitoring() {
        CVDisplayLinkStart(displayLink!)
    }
    
    func stopMonitoring() {
        CVDisplayLinkStop(displayLink!)
    }
    
    private func updateMetrics() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - lastFrameTime
        
        if elapsed >= updateInterval {
            let fps = Double(frameCount) / elapsed
            let cpu = getCPUUsage()
            let memory = getMemoryUsage()
            
            DispatchQueue.main.async {
                self.frameRate = fps
                self.cpuUsage = cpu
                self.memoryUsage = memory
                
                // Log analytics periodically
                if Date().timeIntervalSince(self.lastAnalyticsUpdate) >= self.analyticsInterval {
                    AnalyticsService.shared.trackPerformanceMetrics(
                        fps: fps,
                        cpu: cpu,
                        memory: memory
                    )
                    self.lastAnalyticsUpdate = Date()
                }
            }
            
            frameCount = 0
            lastFrameTime = currentTime
        }
    }
    
    private func getCPUUsage() -> Double {
        var cpuInfo = processor_info_array_t?(nil)
        var numCpuInfo = mach_msg_type_number_t(0)
        var numCpus = 0
        
        let result = host_processor_info(mach_host_self(),
                                       PROCESSOR_CPU_LOAD_INFO,
                                       &numCpus,
                                       &cpuInfo,
                                       &numCpuInfo)
        
        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            var totalUsage: Double = 0
            for i in 0..<Int(numCpus) {
                let offset = Int(CPU_STATE_MAX * i)
                let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
                let system = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
                let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
                let total = user + system + idle
                totalUsage += (user + system) / total
            }
            
            let average = totalUsage / Double(numCpus)
            vm_deallocate(mach_task_self_,
                         vm_address_t(UInt(bitPattern: cpuInfo)),
                         vm_size_t(numCpuInfo * Int(MemoryLayout<integer_t>.stride)))
            return average * 100
        }
        
        return 0
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_,
                         task_flavor_t(TASK_VM_INFO),
                         intPtr,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return info.phys_footprint
        }
        return 0
    }
    
    deinit {
        stopMonitoring()
    }
} 