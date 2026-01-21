import SwiftUI

// MARK: - Layout Options
enum SelectionLayout {
    case auto
    case segmented
    case grid
    case verticalStack
}

struct SelectionView<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    let title: String?
    let options: [T]
    @Binding var selection: T
    @EnvironmentObject var themeManager: ThemeManager
    let titleMapper: ((T) -> String)?
    let colorMapper: ((T) -> Color)?
    let layout: SelectionLayout
    let footerContent: AnyView?
    let isEmbedded: Bool
    
    // Standard Init
    init(
        title: String? = nil,
        options: [T],
        selection: Binding<T>,
        layout: SelectionLayout = .auto,
        titleMapper: ((T) -> String)? = nil,
        colorMapper: ((T) -> Color)? = nil,
        isEmbedded: Bool = false
    ) {
        self.title = title
        self.options = options
        self._selection = selection
        self.layout = layout
        self.titleMapper = titleMapper
        self.colorMapper = colorMapper
        self.footerContent = nil
        self.isEmbedded = isEmbedded
    }
    
    // Init with Footer
    init<Content: View>(
        title: String? = nil,
        options: [T],
        selection: Binding<T>,
        layout: SelectionLayout = .auto,
        titleMapper: ((T) -> String)? = nil,
        colorMapper: ((T) -> Color)? = nil,
        isEmbedded: Bool = false,
        @ViewBuilder footer: () -> Content
    ) {
        self.title = title
        self.options = options
        self._selection = selection
        self.layout = layout
        self.titleMapper = titleMapper
        self.colorMapper = colorMapper
        self.footerContent = AnyView(footer())
        self.isEmbedded = isEmbedded
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.teal500)
            }
            
            // Determine active layout
            let activeLayout: SelectionLayout = {
                if layout == .auto {
                    return options.count <= 3 ? .segmented : .grid
                }
                return layout
            }()
            
            switch activeLayout {
            case .segmented:
                // MARK: - TRUE SEGMENTED CONTROL STYLE
                HStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.element) { index, option in
                        selectionButton(for: option, isSegmented: true)
                        // Add divider except for last item
                        if index < options.count - 1 {
                            Rectangle()
                                .fill(ClinicalTheme.divider)
                                .frame(width: 1)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .background(ClinicalTheme.backgroundInput)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                
            case .grid:
                // MARK: - UNIFORM GRID STYLE
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(options) { option in
                         selectionButton(for: option, isSegmented: false)
                    }
                }
                
            case .verticalStack:
                // MARK: - VERTICAL STACKED SELECTORS (New Clinical Standard)
                VStack(spacing: 8) {
                    ForEach(options) { option in
                        selectionButton(for: option, isSegmented: false)
                    }
                }
                
            case .auto:
                EmptyView() // Should be handled by activeLayout calculation
            }
            
            // Footer Content
            if let footer = footerContent {
                footer
            }
        }
        // Conditional Modifier application
        .modifier(CardModifier(isEmbedded: isEmbedded))
    }

// Helper Modifier to apply conditional card styling
struct CardModifier: ViewModifier {
    let isEmbedded: Bool
    
    func body(content: Content) -> some View {
        if isEmbedded {
            content
        } else {
            content
                .clinicalCard()
                .padding(.horizontal)
        }
    }
}
    
    // Updated Selection Button to handle both styles
    private func selectionButton(for option: T, isSegmented: Bool) -> some View {
        let isSelected = selection == option
        let baseColor = colorMapper?(option) ?? ClinicalTheme.teal500
        let label = titleMapper?(option) ?? option.rawValue
        
        return Button(action: {
            // Motion: Ease-out duration 200ms
            withAnimation(.easeOut(duration: 0.2)) {
                selection = option
            }
            let gen = UIImpactFeedbackGenerator(style: .light); gen.impactOccurred()
        }) {
            if isSegmented {
                // Segmented Item
                HStack(spacing: 8) {
                    if isSelected {
                         Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 20, height: 20)
                    }
                    Text(label)
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .lineSpacing(2) // Relaxed leading
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(isSelected ? .white : ClinicalTheme.textPrimary)
                .padding(.vertical, 12) // py-3
                .padding(.horizontal, 16) // px-4
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44) // Touch Target
                .background(isSelected ? baseColor : Color.clear)
                .contentShape(Rectangle())
            } else {
                // Grid Item (Fixed Height -> Flexible)
                HStack(spacing: 8) { // gap-2 (8px)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 20, height: 20) // Fixed Icon Size
                    }
                    Text(label)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2) // Relaxed leading
                        .fixedSize(horizontal: false, vertical: true) // Allow multiline
                }
                .foregroundColor(isSelected ? .white : ClinicalTheme.textPrimary)
                .padding(.horizontal, 16) // px-4
                .padding(.vertical, 12) // py-3
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44) // Touch Target
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? baseColor : ClinicalTheme.backgroundInput)
                        // Motion: Shadow-sm
                        .shadow(color: isSelected ? baseColor.opacity(0.2) : Color.clear, radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? baseColor : Color.clear, lineWidth: 1)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FlowLayout is defined in UI/Common/FlowLayout.swift
