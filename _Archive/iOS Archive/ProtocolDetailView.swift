import SwiftUI

struct ProtocolDetailView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .foregroundColor(ClinicalTheme.textPrimary)
                    .lineSpacing(6)
            }
            .clinicalCard()
            .padding()
        }
        .slateBackground()
        .navigationTitle(title)
    }
}
