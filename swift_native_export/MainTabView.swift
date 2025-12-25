import SwiftUI

struct MainTabView: View {
    init() {
        // Customize Tab Bar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(red: 0.11, green: 0.14, blue: 0.20)) // slate800
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
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
                    Image(systemName: "list.bullet.clipboard")
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
    }
}
