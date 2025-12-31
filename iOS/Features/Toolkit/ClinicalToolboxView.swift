import SwiftUI

struct ClinicalToolboxView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: String = "street"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(OUDStaticData.toolboxCategories) { category in
                            ToolboxTabButton(
                                title: category.title,
                                icon: category.icon,
                                isSelected: selectedTab == category.id
                            ) {
                                selectedTab = category.id
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                
                // Content Area
                TabView(selection: $selectedTab) {
                    ForEach(OUDStaticData.toolboxCategories) { category in
                        ReferenceListView(category: category)
                            .tag(category.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Clinical Toolbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ReferenceListView: View {
    let category: OUDReferenceCategory
    
    var body: some View {
        List(category.items) { item in
            HStack {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(item.value)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .listStyle(.plain)
    }
}

struct ToolboxTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue : Color.white)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}
