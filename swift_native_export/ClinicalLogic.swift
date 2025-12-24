import Foundation
import Combine

struct Recommendation: Identifiable {
    let id = UUID()
    let name: String
    let reason: String
    let detail: String
    let type: RecType
    
    enum RecType {
        case safe
        case caution
    }
}

class ClinicalLogic: ObservableObject {
    @Published var age: String = ""
    @Published var sex: String = "Female"
    @Published var naive: Bool = false
    @Published var mat: Bool = false
    @Published var sleepApnea: Bool = false
    @Published var chf: Bool = false
    @Published var benzos: Bool = false
    @Published var renal: String = "Normal"
    @Published var hepatic: String = "Normal"
    @Published var route: String = "IV"
    @Published var hemo: String = "Stable"
    @Published var painType: String = "Nociceptive"
    @Published var indication: String = "Standard"
    @Published var gi: String = "Intact"
    
    @Published var recs: [Recommendation] = []
    @Published var prodigyScore: Int = 0
    @Published var prodigyRisk: String = "Low"
    @Published var monitoringRecs: [String] = []
    @Published var warnings: [String] = []
    @Published var adjuvants: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.CombineLatest4($age, $sex, $naive, $mat)
            .combineLatest(Publishers.CombineLatest3($sleepApnea, $chf, $benzos))
            .combineLatest(Publishers.CombineLatest3($renal, $hepatic, $route))
            .sink { [weak self] _ in self?.calculate() }
            .store(in: &cancellables)
    }

    func calculate() {
        var r: [Recommendation] = []
        
        // PRODIGY
        var score = 0
        if let ageNum = Int(age) {
            if ageNum >= 80 { score += 16 }
            else if ageNum >= 70 { score += 12 }
            else if ageNum >= 60 { score += 8 }
        }
        if sex == "Male" { score += 8 }
        if naive { score += 3 }
        if sleepApnea { score += 5 }
        if chf { score += 7 }
        
        self.prodigyScore = score
        self.prodigyRisk = score >= 15 ? "High" : score >= 8 ? "Intermediate" : "Low"
        
        // Basic Logic Port
        let isRenalBad = (renal != "Normal")
        let isHepaticFailure = (hepatic == "Failure")
        
        if isRenalBad {
            r.append(Recommendation(name: "Fentanyl IV", reason: "Renal safe", detail: "No active metabolites.", type: .safe))
            if !isHepaticFailure {
                r.append(Recommendation(name: "Hydromorphone", reason: "Monitor", detail: "Reduce dose 50%.", type: .caution))
            }
        } else {
            r.append(Recommendation(name: "Morphine", reason: "Standard", detail: "First line if renal OK.", type: .safe))
            r.append(Recommendation(name: "Oxycodone PO", reason: "Standard", detail: "Effective for moderate pain.", type: .safe))
        }
        
        if mat {
            r.append(Recommendation(name: "Buprenorphine", reason: "Continue", detail: "Avoid withdrawal.", type: .safe))
        }

        self.recs = r
    }
}
