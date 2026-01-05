
//
//  ContextBadge.swift
//  AnalgesiaTool
//

import SwiftUI

struct ContextBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
            .fixedSize(horizontal: true, vertical: false) // Prevent compression
    }
}
