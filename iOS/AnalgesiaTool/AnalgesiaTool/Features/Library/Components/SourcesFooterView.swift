import SwiftUI

struct SourcesFooterView: View {
    let citations: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            Button(action: { withAnimation { isExpanded.toggle() }}) {
                HStack {
                    Text("References & Sources")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 16)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(citations, id: \.self) { source in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(source)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}
