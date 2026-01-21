import SwiftUI

struct CitationFooter: View {
    let citations: [Citation]
    @State private var isExpanded: Bool = false
    
    // Initializer for Direct structured citations
    init(citations: [Citation]) {
        self.citations = citations
    }
    
    var body: some View {
        if !citations.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Sources (\(citations.count))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textMuted)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle()) // Make full width tappable
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(citations.enumerated()), id: \.offset) { index, citation in
                            CitationRow(index: index + 1, citation: citation)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
            }
            .padding(.top, 8)
        }
    }
}

// Subview for individual citation row
struct CitationRow: View {
    let index: Int
    let citation: Citation
    

    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("[\(index)]")
                .font(.caption)
                .bold()
                .foregroundColor(ClinicalTheme.teal500)
                .frame(minWidth: 20, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title & Source
                Group {
                    if !citation.year.isEmpty {
                        Text("\(citation.source) (\(citation.year))\(citation.section != nil ? " • Section \(citation.section!)" : "")")
                            .fontWeight(.semibold)
                    } else {
                        // Legacy Fallback
                        Text(citation.title)
                    }
                }
                .font(.caption)
                .foregroundColor(ClinicalTheme.textPrimary)
                
                if !citation.title.isEmpty && !citation.year.isEmpty {
                     Text(citation.title)
                        .font(.caption2)
                        .italic()
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                
                if let excerpt = citation.excerpt {
                    Text("\"\(excerpt)\"")
                        .font(.caption2)
                        .foregroundColor(ClinicalTheme.textMuted)
                        .padding(.leading, 4)
                        .overlay(Rectangle().frame(width: 2).foregroundColor(ClinicalTheme.divider), alignment: .leading)
                }
                
                HStack {
                    if let urlString = citation.url, let url = URL(string: urlString) {
                        Link("View Source", destination: url)
                            .font(.caption2)
                            .foregroundColor(ClinicalTheme.teal500)
                    }
                    
                    if !citation.lastVerified.isEmpty {
                        Spacer()
                        Text("Verified: \(citation.lastVerified)")
                            .font(.caption2)
                            .foregroundColor(ClinicalTheme.textMuted)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(8)
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(6)
    }
}
