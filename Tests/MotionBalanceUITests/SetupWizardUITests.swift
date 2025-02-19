import XCTest

class SetupWizardUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testSetupWizardFlow() {
        // Test welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to MotionBalance"].exists)
        
        // Navigate through steps
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists)
        
        // Test device position step
        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Position Your Device"].exists)
        
        // Test calibration step
        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Calibration"].exists)
        
        // Test Bluetooth pairing step
        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Connect to Mac"].exists)
        
        // Test comfort settings step
        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Comfort Settings"].exists)
        
        // Test completion
        nextButton.tap()
        XCTAssertTrue(app.staticTexts["Setup Complete!"].exists)
    }
    
    func testAccessibility() {
        // Test accessibility labels and hints
        XCTAssertTrue(app.buttons["Next"].isAccessibilityElement)
        XCTAssertTrue(app.buttons["Back"].isAccessibilityElement)
        
        // Test VoiceOver support
        let elements = app.descendants(matching: .any)
        elements.allElementsBoundByAccessibilityElement.forEach { element in
            XCTAssertFalse(element.identifier.isEmpty, "All elements should have accessibility identifiers")
        }
    }
} 