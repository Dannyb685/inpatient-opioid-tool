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
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) // Make it look like a banner
            }
            
            // 1. Assessment Tests
            Section(header: Text("Assessment Logic (\(ClinicalValidationEngine.shared.testCases.count))")) {
                ForEach(ClinicalValidationEngine.shared.testCases, id: \.name) { test in
                    Button(action: { runAssessmentTest(test) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(test.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "play.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // 2. Calculator Tests
            Section(header: Text("Calculator Logic (\(ClinicalValidationEngine.shared.calculatorTestCases.count))")) {
                ForEach(ClinicalValidationEngine.shared.calculatorTestCases, id: \.name) { test in
                    Button(action: { runCalculatorTest(test) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(test.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "function")
                                .foregroundColor(.teal)
                        }
                    }
                }
            }
            
            // 3. Taper Tests
            Section(header: Text("Taper & Rotation (\(ClinicalValidationEngine.shared.taperTestCases.count))")) {
                ForEach(ClinicalValidationEngine.shared.taperTestCases, id: \.name) { test in
                    Button(action: { runCalculatorTest(test) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(test.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            // 4. Methadone Tests
            Section(header: Text("Methadone Logic (\(ClinicalValidationEngine.shared.methadoneTestCases.count))")) {
                 Text("Note: Methadone logic is stateless function-based (View-driven). These tests run in isolation and inject input only.")
                    .font(.caption).italic().foregroundColor(.secondary)
                    
                ForEach(ClinicalValidationEngine.shared.methadoneTestCases, id: \.name) { test in
                    Button(action: { runMethadoneSetup(test) }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(test.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "testtube.2")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Clinical Validation Runner")
        .overlay(
            VStack {
                if showFeedback {
                    Text(feedbackMessage)
                        .font(.headline)
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
        )
        .sheet(isPresented: $showStressTestLog) {
            NavigationView {
                ScrollView {
                    Text(stressTestLog)
                        .font(.custom("Menlo", size: 12)) // Monospaced for log alignment
                        .padding()
                }
                .navigationTitle("Stress Test Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") { showStressTestLog = false }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                             UIPasteboard.general.string = stressTestLog
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Runners
    
    func runAssessmentTest(_ test: AssessmentTestCase) {
        // 1. Inject
        withAnimation {
            test.setup(assessmentStore)
            assessmentStore.calculate()
        }
        
        // 2. Verify (Internal check)
        let result = test.verify(assessmentStore)
        
        // 3. Feedback
        switch result {
        case .pass:
            showToast("✅ Injected & Passed Logic Check", color: .green)
        case .fail(let msg):
            showToast("❌ Logic Fail: \(msg)", color: .red) // Allow user to see logic failure even if visual differs
        }
    }
    
    func runCalculatorTest(_ test: CalculatorTestCase) {
        withAnimation {
            test.setup(calculatorStore)
            calculatorStore.calculate()
        }
        
        let result = test.verify(calculatorStore)
        switch result {
        case .pass: showToast("✅ Calc Injected & Verfied", color: .teal)
        case .fail(let msg): showToast("❌ Calc Logic Fail: \(msg)", color: .red)
        }
    }
    
    func runMethadoneSetup(_ test: MethadoneTestCase) {
        // Methadone Controller is usually MethadoneView which has local state.
        // We can simulate the INPUTS in the CalculatorStore if possible, or just toast result.
        // Actually, we can run the logic function and show result.
        
        let res = calculateMethadoneConversion(totalMME: test.mme, patientAge: test.age, method: test.method)
        let verify = test.verify(res)
        
        switch verify {
        case .pass: showToast("✅ Logic Passed (State Isolated)", color: .purple)
        case .fail(let msg): showToast("❌ Logic Fail: \(msg)", color: .red)
        }
    }
    
    func runOUDTest(_ test: OUDTestCase) {
        // Run logic on isolated store (since OUD View is not in Environment here yet)
        let store = OUDConsultStore()
        test.setup(store)
        let result = test.verify(store)
        
        switch result {
        case .pass: showToast("✅ OUD Logic Passed", color: .indigo)
        case .fail(let msg): showToast("❌ OUD Fail: \(msg)", color: .red)
        }
    }
    
    func runFullStressTest() {
        let log = ClinicalValidationEngine.shared.runStressTest()
        self.stressTestLog = log
        self.showStressTestLog = true
    }
    
    func showToast(_ msg: String, color: Color) {
        self.feedbackMessage = msg
        self.feedbackColor = color
        withAnimation {
            self.showFeedback = true
        }
    }
}
