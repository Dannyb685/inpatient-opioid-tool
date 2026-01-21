import SwiftUI

struct ValidationRunnerView: View {
    @EnvironmentObject var assessmentStore: AssessmentStore
    @EnvironmentObject var calculatorStore: CalculatorStore
    @Environment(\.presentationMode) var presentationMode
    
    // State to track last run test
    @State private var lastRunTest: String? = nil
    @State private var feedbackMessage: String = ""
    @State private var feedbackColor: Color = .clear

    @State private var showFeedback: Bool = false
    
    // Stress Test Log State
    @State private var showStressTestLog: Bool = false
    @State private var stressTestLog: String = ""
    
    var body: some View {
        List {
            Section(header: Text("Instructions")) {
                Text("Tap a test case to INJECT its parameters into the live app. Then navigate to the relevant tab (Assessment or Calculator) to verify the UI.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: runFullStressTest) {
                    HStack {
                        Image(systemName: "checklist")
                        Text("Run Full Stress Test Suite")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(ClinicalTheme.blue500)
                    .cornerRadius(8)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
            
            // 1. Assessment Tests
            Section(header: Text("Assessment Logic (\(ClinicalValidationEngine.shared.testCases.count))")) {
                ForEach(ClinicalValidationEngine.shared.testCases, id: \.name) { test in
                    runnerRow(title: test.name, icon: "play.circle", color: ClinicalTheme.blue500) {
                         runAssessmentTest(test)
                    }
                }
            }
            
            // 2. Calculator Tests
            Section(header: Text("Calculator Logic (\(ClinicalValidationEngine.shared.calculatorTestCases.count))")) {
                ForEach(ClinicalValidationEngine.shared.calculatorTestCases, id: \.name) { test in
                    runnerRow(title: test.name, icon: "function", color: ClinicalTheme.teal500) {
                        runCalculatorTest(test)
                    }
                }
            }
            
            // 3. Taper Tests
            Section(header: Text("Taper & Rotation (\(ClinicalValidationEngine.shared.taperTestCases.count))")) {
                ForEach(ClinicalValidationEngine.shared.taperTestCases, id: \.name) { test in
                    runnerRow(title: test.name, icon: "chart.line.downtrend.xyaxis", color: .orange) {
                        runCalculatorTest(test)
                    }
                }
            }
            
            // 4. OUD Protocol Tests (O1-O10)
            Section(header: Text("OUD Protocols (\(ClinicalValidationEngine.shared.oudTestCases.count))")) {
                 ForEach(ClinicalValidationEngine.shared.oudTestCases, id: \.name) { test in
                     runnerRow(title: test.name, icon: "cross.case.fill", color: ClinicalTheme.purple500) {
                         runOUDTest(test)
                     }
                 }
            }
            
            // 5. OUD Logic Tests (L1-L3)
            Section(header: Text("OUD Intelligence (\(ClinicalValidationEngine.oudLogicTests.count))")) {
                 ForEach(ClinicalValidationEngine.oudLogicTests, id: \.name) { test in
                     runnerRow(title: test.name, icon: "brain.head.profile", color: .purple) {
                         runOUDComplexTest(test)
                     }
                 }
            }
            
            // 6. Transparency Audits (TR1-TR3)
            Section(header: Text("Stewardship & Transparency (\(ClinicalValidationEngine.transparencyTestCases.count))")) {
                ForEach(ClinicalValidationEngine.transparencyTestCases, id: \.name) { test in
                    runnerRow(title: test.name, icon: "magnifyingglass.circle", color: ClinicalTheme.teal500) {
                        runTransparencyTest(test)
                    }
                }
            }
            
            // 7. Methadone Tests
            Section(header: Text("Methadone Logic (\(ClinicalValidationEngine.shared.methadoneTestCases.count))")) {
                 Text("Stateless logic verification.")
                    .font(.caption).italic().foregroundColor(.secondary)
                    
                ForEach(ClinicalValidationEngine.shared.methadoneTestCases, id: \.name) { test in
                    runnerRow(title: test.name, icon: "testtube.2", color: .purple) {
                        runMethadoneSetup(test)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Clinical Validation Runner")
        .overlay(feedbackOverlay)
        .sheet(isPresented: $showStressTestLog) {
            stressTestLogView
        }
    }
    
    // MARK: - Components
    
    func runnerRow(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ClinicalTheme.textPrimary)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
            }
        }
    }
    
    var feedbackOverlay: some View {
        VStack {
            if showFeedback {
                Text(feedbackMessage)
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(feedbackColor)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showFeedback = false }
                        }
                    }
            }
            Spacer()
        }
    }
    
    var stressTestLogView: some View {
        NavigationView {
            ScrollView {
                Text(stressTestLog)
                    .font(.custom("Menlo", size: 12))
                    .padding()
            }
            .navigationTitle("Stress Test Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { showStressTestLog = false }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { UIPasteboard.general.string = stressTestLog }) {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
    
    // MARK: - Runners
    
    func runAssessmentTest(_ test: AssessmentTestCase) {
        withAnimation {
            test.setup(assessmentStore)
            assessmentStore.calculate()
        }
        handleResult(test.verify(assessmentStore))
    }
    
    func runCalculatorTest(_ test: CalculatorTestCase) {
        withAnimation {
            test.setup(calculatorStore)
            calculatorStore.calculate()
        }
        handleResult(test.verify(calculatorStore))
    }
    
    func runTransparencyTest(_ test: TransparencyTestCase) {
        withAnimation {
            test.setup(calculatorStore)
            calculatorStore.calculate()
        }
        handleResult(test.verify(calculatorStore))
    }
    
    func runMethadoneSetup(_ test: MethadoneTestCase) {
        let res = MethadoneCalculator.calculate(
            totalMME: test.mme, 
            patientAge: test.age, 
            method: test.method,
            hepaticStatus: test.hepaticStatus,
            renalStatus: test.renalStatus,
            isPregnant: test.isPregnant,
            benzos: test.benzos,
            isOUD: test.isOUD,
            qtcProlonged: test.qtcProlonged
        )
        handleResult(test.verify(res))
    }
    
    func runOUDTest(_ test: OUDTestCase) {
        let store = OUDConsultStore()
        test.setup(store)
        handleResult(test.verify(store))
    }
    
    func runOUDComplexTest(_ test: OUDComplexTestCase) {
        // Run Logic
        let store = OUDConsultStore()
        
        // Setup via entries
        store.reset()
        store.entries = test.entries
        // Map other props? OUDComplexTest usually has `entries` and `cows`.
        store.cowsSelections = [99: test.cows]
        // hasUlcers in Logic test maps to what?
        // The plan from OUDComplexTestCase is generated:
        store.physiology = OUDCalculator.assess(entries: test.entries, hasUlcers: test.hasUlcers, isPregnant: false, isBreastfeeding: false, hasLiverFailure: false, hasAcutePain: false)
        
        if let phys = store.physiology {
            let plan = ProtocolGenerator.generate(profile: phys, cows: test.cows, isERSetting: false)
            store.generatedPlan = plan
            handleResult(test.verify(plan))
        } else {
            showToast("Setup Failed: Invalid Physiology", color: .red)
        }
    }
    
    func runFullStressTest() {
        let log = ClinicalValidationEngine.shared.runStressTest()
        self.stressTestLog = log
        self.showStressTestLog = true
    }
    
    func handleResult(_ result: ClinicalValidationResult) {
        switch result {
        case .pass: showToast("Logic Verified", color: ClinicalTheme.teal500)
        case .fail(let msg): showToast("Logic Fail: \(msg)", color: .red)
        }
    }
    
    func showToast(_ msg: String, color: Color) {
        self.feedbackMessage = msg
        self.feedbackColor = color
        withAnimation { self.showFeedback = true }
    }
}
