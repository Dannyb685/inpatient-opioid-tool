import SwiftUI

struct MainTabView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        TabView {
            // Tab 1: Assessment
            RiskAssessmentView()
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Assessment")
                }
            
            // Tab 2: Screening
            ScreeningView()
                .tabItem {
                    Image(systemName: "list.clipboard")
                    Text("Screening")
                }
            
            // Tab 3: MME Calc
            CalculatorView()
                .tabItem {
                    Image(systemName: "pills")
                    Text("MME Calc")
                }
                
            // Tab 4: Protocols
            ProtocolsView()
                .tabItem {
                    Image(systemName: "arrow.triangle.branch")
                    Text("Protocols")
                }

            // Tab 5: Reference
            ReferenceView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Reference")
                }
        }
        .accentColor(ClinicalTheme.teal500)
        .onAppear { updateTabBar() }
        .onChange(of: themeManager.isDarkMode) { _, _ in updateTabBar() }
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
