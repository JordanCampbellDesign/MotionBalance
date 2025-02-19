var body: some View {
    ZStack {
        // Existing content
        
        VStack {
            Spacer()
            
            MonitoringOverlayView(motionManager: motionManager)
                .padding()
        }
    }
} 