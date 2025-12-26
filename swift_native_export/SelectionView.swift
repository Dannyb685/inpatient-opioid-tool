import SwiftUI

struct SelectionView<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    let title: String?
    let options: [T]
    @Binding var selection: T
    @EnvironmentObject var themeManager: ThemeManager
    let titleMapper: ((T) -> String)?
    let colorMapper: ((T) -> Color)?
    
    // Thresholds for layout switching
    private let horizontalCharLimit = 25
    private let singleItemCharLimit = 12
    
    init(
        title: String? = nil,
        options: [T],
        selection: Binding<T>,
        titleMapper: ((T) -> String)? = nil,
        colorMapper: ((T) -> Color)? = nil
    ) {
        self.title = title
        self.options = options
        self._selection = selection
        self.titleMapper = titleMapper
        self.colorMapper = colorMapper
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.teal500)
            }
            
            if shouldUseVerticalLayout {
                VStack(spacing: 8) {
                    ForEach(options) { option in
                        selectionButton(for: option)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(options) { option in
                            selectionButton(for: option)
                        }
                    }
                }
            }
        }
        .clinicalCard()
        .padding(.horizontal)
    }
    
    private var shouldUseVerticalLayout: Bool {
        let totalChars = options.reduce(0) { $0 + $1.rawValue.count }
        let hasLongItem = options.contains { $0.rawValue.count > singleItemCharLimit }
        return totalChars > horizontalCharLimit || hasLongItem
    }
    
    private func selectionButton(for option: T) -> some View {
        let isSelected = selection == option
        let baseColor = colorMapper?(option) ?? ClinicalTheme.teal500
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selection = option
            }
        }) {
            HStack {
                // Radio circle for vertical layout
                if shouldUseVerticalLayout {
                    Circle()
                        .strokeBorder(isSelected ? baseColor : ClinicalTheme.textMuted, lineWidth: 2)
                        .background(Circle().fill(isSelected ? baseColor : Color.clear))
                        .frame(width: 18, height: 18)
                }
                
                Text(titleMapper?(option) ?? option.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? (shouldUseVerticalLayout ? ClinicalTheme.textPrimary : .white) : ClinicalTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(shouldUseVerticalLayout ? .leading : .center)
                
                if shouldUseVerticalLayout { Spacer() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(shouldUseVerticalLayout ? ClinicalTheme.backgroundInput : (isSelected ? baseColor : ClinicalTheme.backgroundInput))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? baseColor : ClinicalTheme.cardBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
