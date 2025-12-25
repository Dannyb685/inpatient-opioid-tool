import SwiftUI

struct SegmentedButton<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = option
                        }
                    }) {
                        Text(label(option))
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selection == option
                                ? ClinicalTheme.teal500
                                : ClinicalTheme.slate800
                            )
                            .foregroundColor(
                                selection == option
                                ? .white
                                : ClinicalTheme.slate400
                            )
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selection == option
                                        ? ClinicalTheme.teal500
                                        : ClinicalTheme.slate700,
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
        }
    }
}
