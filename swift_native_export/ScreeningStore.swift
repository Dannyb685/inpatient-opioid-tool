import Foundation
import Combine

struct QuestionViewModel: Identifiable {
    let id: String
    let text: String
    var isYes: Bool = false
}

class ScreeningStore: ObservableObject {
    @Published var questions: [QuestionViewModel] = [
        QuestionViewModel(id: "d1", text: "Have you used drugs other than those required for medical reasons?"),
        QuestionViewModel(id: "d2", text: "Do you abuse more than one drug at a time?"),
        QuestionViewModel(id: "d3", text: "Are you unable to get through the week without using drugs?"),
        QuestionViewModel(id: "d4", text: "Have you ever had blackouts or flashbacks as a result of drug use?"),
        QuestionViewModel(id: "d5", text: "Do you ever feel bad or guilty about your drug use?"),
        QuestionViewModel(id: "d6", text: "Does your spouse (or parents) ever complain about your involvement with drugs?"),
        QuestionViewModel(id: "d7", text: "Have you neglected your family because of your use of drugs?"),
        QuestionViewModel(id: "d8", text: "Have you engaged in illegal activities in order to obtain drugs?"),
        QuestionViewModel(id: "d9", text: "Have you ever experienced withdrawal symptoms (felt sick) when you stopped taking drugs?"),
        QuestionViewModel(id: "d10", text: "Have you had medical problems as a result of your drug use (e.g., memory loss, hepatitis, convulsions, bleeding)?")
    ]
    
    var riskScore: Int {
        questions.filter { $0.isYes }.count
    }
    
    var riskLevel: String {
        switch riskScore {
        case 0: return "Low Risk"
        case 1...2: return "Low/Moderate Risk"
        case 3...5: return "Moderate Risk"
        case 6...10: return "Substantial Risk"
        default: return "Unknown"
        }
    }
    
    init() {}
}
