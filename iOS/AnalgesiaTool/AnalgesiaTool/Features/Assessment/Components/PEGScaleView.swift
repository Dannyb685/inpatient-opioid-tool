import SwiftUI

Slider(value: $painLevel, in: 0...10)
    .accessibilityIdentifier("peg_slider_pain")

struct PEGScaleView: View {
    @Binding var painLevel: Double      // P: Pain (avg past week)
    @Binding var enjoymentLevel: Double // E: Enjoyment of life
    @Binding var activityLevel: Double  // G: General activity
    
    // Clinical Calculation: Mean of the 3 distinct scores
    var pegScore: Double {
        (painLevel + enjoymentLevel + activityLevel) / 3.0
    }
    
    // Dynamic color coding for the total score
    private var scoreColor: Color {
        switch pegScore {
        case 0..<4: return .green
        case 4..<7: return .yellow
        case 7...10: return ClinicalTheme.rose500
        default: return .primary
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("PEG Assessment")
                        .font(.headline)
                    Text("Multidimensional Impact Scale")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                Spacer()
                
                // Real-time Score Badge
                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f", pegScore))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    Text("/ 10")
                        .font(.caption2)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // P: Pain
            PEGSliderRow(
                title: "Pain",
                subtitle: "Average intensity over the past week",
                value: $painLevel,
                color: ClinicalTheme.rose500,
                accessibilityId: "peg_slider_pain"
            )
            
            // E: Enjoyment
            PEGSliderRow(
                title: "Enjoyment",
                subtitle: "Interference with enjoyment of life",
                value: $enjoymentLevel,
                color: ClinicalTheme.amber500,
                accessibilityId: "peg_slider_enjoyment"
            )
            
            // G: General Activity
            PEGSliderRow(
                title: "General Activity",
                subtitle: "Interference with general activity",
                value: $activityLevel,
                color: ClinicalTheme.teal500,
                accessibilityId: "peg_slider_activity"
            )
        }
        .padding()
        .background(ClinicalTheme.backgroundInput)
        .cornerRadius(12)
    }
}

// Helper Subcomponent for consistent sliders
struct PEGSliderRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let color: Color
    var accessibilityId: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(value))")
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(ClinicalTheme.textSecondary)
            
            Slider(value: $value, in: 0...10, step: 1)
                // .tint(color) // iOS 15+
                .accentColor(color)
                .accessibilityIdentifier(accessibilityId ?? "")
            
            HStack {
                Text("No Interference").font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                Spacer()
                Text("Complete").font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
            }
        }
    }
}
