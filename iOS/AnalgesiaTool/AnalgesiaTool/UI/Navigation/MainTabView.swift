import SwiftUI

struct MainTabView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    @State private var selectedTab = 0
    @EnvironmentObject var assessmentStore: AssessmentStore // Injected from App
    @StateObject private var calculatorStore = CalculatorStore() // Shared State for Tabs
    
    // Safety Alerts
    enum ActiveAlert: Identifiable {
        case mismatch, disclaimer
        var id: Int { hashValue }
    }
    @State private var activeAlert: ActiveAlert?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Assessment
            RiskAssessmentView()
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Assessment")
                }
                .tag(0)
            
            // Tab 3: MME Calc
            CalculatorView(sharedStore: calculatorStore)
                .tabItem {
                    Image(systemName: "pills")
                    Text("MME Calc")
                }
                .tag(2)
                
            // Tab 4: OUD Consult
            OUDConsultView()
                .tabItem {
                    Image(systemName: "cross.case.fill")
                    Text("OUD Consult")
                }
                .tag(3)
                
            // Tab 5: Library
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Library")
                }
                .tag(4)
        }
        .environmentObject(calculatorStore) // Inject shared Calculator State for Settings/Debug
        .accentColor(ClinicalTheme.teal500)
        .onAppear {
            updateTabBar()
            // Legal Requirement: Show disclaimer every time app opens
            activeAlert = .disclaimer
        }
        .onChange(of: selectedTab) { _, newTab in 
            if newTab == 2 {
                // User Request: Removed "Missing Data" check to allow starting in Calculator.
                // Logic Flow:
                // 1. If Dirty State -> Ask to Overwrite
                // 2. If Clean State -> Seed (Even if empty)
                
                if calculatorStore.hasActiveDrugs && (
                    String(calculatorStore.age) != assessmentStore.age ||
                    calculatorStore.renalStatus != assessmentStore.renalFunction ||
                    calculatorStore.hepaticStatus != assessmentStore.hepaticFunction ||
                    calculatorStore.analgesicProfile != assessmentStore.analgesicProfile
                ) {
                     // 2. Dirty State Check -> Confirm
                     activeAlert = .mismatch
                } else {
                     // 3. Clean -> Seed Auto
                     calculatorStore.seed(from: assessmentStore)
                }
            }
        }
        .onChange(of: themeManager.isDarkMode) { _, _ in updateTabBar() }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .mismatch:
                return Alert(
                    title: Text("Patient Context Changed"),
                    message: Text("Assessment data is different from the current Calculator session.\n\nUpdate Calculator context? This will NOT clear your drug list, but may change safety factors."),
                    primaryButton: .default(Text("Update")) {
                        calculatorStore.seed(from: assessmentStore)
                    },
                    secondaryButton: .cancel(Text("Keep Current"))
                )
            case .disclaimer:
                return Alert(
                    title: Text("Clinical Disclaimer"),
                    message: Text("This tool is intended for ADULT patients (18+) only. It is NOT validated for pediatric use.\n\nCalculations are estimates. Clinical judgment is mandatory."),
                    dismissButton: .default(Text("I Understand")) {
                        hasAcceptedDisclaimer = true
                    }
                )
            }
        }
    }


    private func updateTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground() // Use system default material (translucent blur)
        
        // Optional: Force a specific blur style if needed, but default is usually best for native feel.
        // appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Configuration for Navigation Bar to match theme
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        // Ensure title contrast
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}
