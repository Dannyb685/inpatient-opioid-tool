import Foundation

public enum OpioidMolecule: String, CaseIterable, Codable, Identifiable {
    case morphine
    case hydromorphone
    case oxycodone
    case hydrocodone
    case codeine
    case fentanyl
    case methadone
    case buprenorphine
    case tramadol
    case tapentadol
    case levorphanol
    case meperidine
    case suzetrigine
    case sufentanil
    case alfentanil
    case remifentanil
    case naloxone
    case naltrexone
    case other
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .morphine: return "Morphine"
        case .hydromorphone: return "Hydromorphone"
        case .oxycodone: return "Oxycodone"
        case .hydrocodone: return "Hydrocodone"
        case .codeine: return "Codeine"
        case .fentanyl: return "Fentanyl"
        case .methadone: return "Methadone"
        case .buprenorphine: return "Buprenorphine"
        case .tramadol: return "Tramadol"
        case .tapentadol: return "Tapentadol"
        case .levorphanol: return "Levorphanol"
        case .meperidine: return "Meperidine"
        case .suzetrigine: return "Suzetrigine"
        case .sufentanil: return "Sufentanil"
        case .alfentanil: return "Alfentanil"
        case .remifentanil: return "Remifentanil"
        case .naloxone: return "Naloxone"
        case .naltrexone: return "Naltrexone"
        case .other: return "Other"
        }
    }
}
