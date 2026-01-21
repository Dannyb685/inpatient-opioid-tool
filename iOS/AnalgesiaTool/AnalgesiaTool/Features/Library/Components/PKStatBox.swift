import SwiftUI

struct PKStatBox: View {
    let label: String
    let value: String
    var isBar: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            
            if isBar {
                // Simple visual bar for Bioavailability
                HStack {
                    Capsule()
                        .fill(Color.teal)
                        .frame(width: 40, height: 6)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                }
            } else {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
