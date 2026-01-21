import SwiftUI

/// A container that arranges its subviews in a horizontal flow, wrapping to the next line when necessary.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        if rows.isEmpty { return .zero }
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        for row in rows {
            let rowWidth = row.reduce(0) { $0 + $1.size.width } + CGFloat(row.count - 1) * spacing
            width = max(width, rowWidth)
            
            let rowHeight = row.map { $0.size.height }.max() ?? 0
            height += rowHeight
        }
        
        height += CGFloat(rows.count - 1) * lineSpacing
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        var y = bounds.minY
        
        for row in rows {
            let rowHeight = row.map { $0.size.height }.max() ?? 0
            var x = bounds.minX
            
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            
            y += rowHeight + lineSpacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutItem]] {
        var rows: [[LayoutItem]] = []
        var currentRow: [LayoutItem] = []
        var currentX: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentX = 0
            }
            
            currentRow.append(LayoutItem(view: subview, size: size))
            currentX += size.width + spacing
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct LayoutItem {
        let view: LayoutSubview
        let size: CGSize
    }
}
