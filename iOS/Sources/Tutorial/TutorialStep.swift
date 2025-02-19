struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    var interaction: InteractionType?
    var validationRule: ValidationRule?
    
    enum InteractionType {
        case devicePosition
        case bluetoothSetup
        case calibration
        case comfortSettings
    }
    
    enum ValidationRule {
        case deviceFlat
        case bluetoothConnected
        case calibrationComplete
        case settingsConfigured
    }
    
    static let allSteps: [TutorialStep] = [
        .welcome,
        .devicePosition,
        .bluetoothSetup,
        .calibration,
        .comfortSettings,
        .completion
    ]
    
    static let welcome = TutorialStep(
        title: "Welcome to MotionBalance",
        description: "Let's set up your motion sickness reduction system.",
        icon: "hand.wave"
    )
    
    static let devicePosition = TutorialStep(
        title: "Position Your Device",
        description: "Place your iPhone flat and stable. We'll help you find the optimal position.",
        icon: "iphone.gen2",
        interaction: .devicePosition,
        validationRule: .deviceFlat
    )
    
    static let bluetoothSetup = TutorialStep(
        title: "Connect to Mac",
        description: "Let's establish a connection with your Mac.",
        icon: "macbook.and.iphone",
        interaction: .bluetoothSetup,
        validationRule: .bluetoothConnected
    )
    
    static let calibration = TutorialStep(
        title: "Quick Calibration",
        description: "We'll calibrate the motion sensors for optimal performance.",
        icon: "arrow.triangle.2.circlepath",
        interaction: .calibration,
        validationRule: .calibrationComplete
    )
    
    static let comfortSettings = TutorialStep(
        title: "Personalize",
        description: "Adjust the settings to match your comfort preferences.",
        icon: "slider.horizontal.3",
        interaction: .comfortSettings,
        validationRule: .settingsConfigured
    )
    
    static let completion = TutorialStep(
        title: "All Set!",
        description: "You're ready to use MotionBalance. You can adjust settings anytime.",
        icon: "checkmark.circle.fill"
    )
} 