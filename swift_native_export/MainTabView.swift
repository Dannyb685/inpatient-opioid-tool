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
    
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            // Theme Toggle Overlay
            Button(action: {
                withAnimation {
                    themeManager.isDarkMode.toggle()
                }
            }) {
                Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(themeManager.isDarkMode ? .yellow : ClinicalTheme.slate700)
                    .padding(8)
                    .background(ClinicalTheme.slate800)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.top, 50) // Adjust for status bar/safe area (approx)
            .padding(.trailing, 16)
        }
    }
}
