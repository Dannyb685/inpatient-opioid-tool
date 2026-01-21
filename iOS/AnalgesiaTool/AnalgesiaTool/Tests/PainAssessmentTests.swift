import XCTest
@testable import AnalgesiaTool

final class PainAssessmentTests: XCTestCase {
    
    var store: AssessmentStore!
    
    override func setUp() {
        super.setUp()
        store = AssessmentStore()
    }
    
    override func tearDown() {
        store = nil
        super.tearDown()
    }
    
    // MARK: - Scale Selection Logic Tests
    
    func testStandardAdultDefaultsToNRS() {
        // GIVEN: A standard communicative adult
        store.communication = .verbal
        store.cognitiveStatus = .baseline
        store.age = "45"
        
        // THEN: Should show NRS
        XCTAssertEqual(store.recommendedScale, .nrs, "Standard adult should default to NRS")
    }
    
    func testElderlyRedirectionToVDS() {
        // GIVEN: An elderly patient (likely visual/motor deficits)
        store.age = "80"
        store.communication = .verbal
        store.cognitiveStatus = .mildImpairment
        
        // THEN: Should PREFER VDS over NRS/VAS to reduce error rates
        XCTAssertEqual(store.recommendedScale, .vds, "Geriatric/Mild Impairment should default to VDS")
    }
    
    func testDementiaTriggersPAINAD() {
        // GIVEN: Advanced dementia context
        store.cognitiveStatus = .advancedDementia
        
        // THEN: Must use behavioral observation
        XCTAssertEqual(store.recommendedScale, .painad, "Advanced Dementia must trigger PAINAD")
    }
    
    func testIntubationSwitchesCriticalCareScale() {
        // GIVEN: Non-communicative patient
        store.communication = .nonCommunicative
        
        // WHEN: Intubated
        store.intubation = .intubated
        XCTAssertEqual(store.recommendedScale, .cpot, "Intubated should offer CPOT")
        
        // WHEN: Extubated
        store.intubation = .none // Extubated / Spontaneous
        XCTAssertEqual(store.recommendedScale, .bpsNi, "Extubated should offer BPS-NI")
    }
    
    func testChronicOpioidProfileTriggersPEG() {
        // GIVEN: Chronic pain context
        store.analgesicProfile = .chronicRx
        store.communication = .verbal
        
        // THEN: Should offer multidimensional scale
        XCTAssertEqual(store.recommendedScale, .peg, "Chronic Opioid Therapy should trigger PEG scale")
    }
    
    func testManualOverrideRespectsUserSelection() {
        // GIVEN: Standard adult (should be NRS)
        store.communication = .verbal
        store.age = "30"
        XCTAssertEqual(store.recommendedScale, .nrs)
        
        // WHEN: User manually selects CPOT
        store.manualScaleOverride = .cpot
        
        // THEN: Store should recommend CPOT regardless of rules
        XCTAssertEqual(store.recommendedScale, .cpot, "Manual override must take precedence")
        
        // WHEN: Cleared
        store.manualScaleOverride = nil
        XCTAssertEqual(store.recommendedScale, .nrs, "Clearing override restores default logic")
    }
    
    // MARK: - Scoring & Export Tests
    
    func testVASAutoSeverityFlagging() {
        // GIVEN: Manual Override to VAS to ensure matching logic path
        store.manualScaleOverride = .vas // Force logic to use VAS severity path
        
        // WHEN: Score is 7.6 (76mm converted to 0-10)
        store.customPainScore = 7.6
        
        // THEN: Should be Severe (>= 7.5cm)
        let export = store.exportPainData()
        XCTAssertEqual(export.severityCategory, "Severe", "VAS > 7.5 must be flagged as Severe")
        
        // WHEN: Score is 3.4
        store.customPainScore = 3.4
        
        // THEN: Should be Mild (<= 3.4cm)
        let export2 = store.exportPainData()
        XCTAssertEqual(export2.severityCategory, "Mild", "VAS <= 3.4 must be flagged as Mild")
    }
    
    func testPEGScoringAverage() {
        // GIVEN: PEG selected (manually or logically)
        store.manualScaleOverride = .peg
        store.customPainScore = 6.0 // (6+8+4)/3 = 18/3 = 6.0
        
        // THEN: Export should reflect raw score
        let export = store.exportPainData()
        XCTAssertEqual(export.rawScore, 6.0, accuracy: 0.1)
    }
}
