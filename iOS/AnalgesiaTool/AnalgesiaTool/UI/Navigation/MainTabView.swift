import SwiftUI

struct MainTabView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    @State private var showDisclaimer = false
    
    // Shared State for Tabs (LIFTED)
    @StateObject private var calculatorStore = CalculatorStore()

    var body: some View {
        TabView {
            // Tab 1: Assessment
            RiskAssessmentView()
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Assessment")
                }
            


            // Tab 3: MME Calc
            CalculatorView(sharedStore: calculatorStore)
                .tabItem {
                    Image(systemName: "pills")
                    Text("MME Calc")
                }
                
            // Tab 4: OUD Consult
            OUDConsultView()
                .tabItem {
                    Image(systemName: "cross.case.fill")
                    Text("OUD Consult")
                }
                
            // Tab 5: Library
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Library")
                }
        }
        .accentColor(ClinicalTheme.teal500)
        .onAppear {
            updateTabBar()
            // Legal Requirement: Show disclaimer every time app opens
            showDisclaimer = true
        }
        .onChange(of: themeManager.isDarkMode) { _, _ in updateTabBar() }
        .alert(isPresented: $showDisclaimer) {
            Alert(
                title: Text("Clinical Disclaimer"),
                message: Text("This tool is intended for ADULT patients (18+) only. It is NOT validated for pediatric use.\n\nCalculations are estimates. Clinical judgment is mandatory."),
                dismissButton: .default(Text("I Understand")) {
                    hasAcceptedDisclaimer = true
                }
            )
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
