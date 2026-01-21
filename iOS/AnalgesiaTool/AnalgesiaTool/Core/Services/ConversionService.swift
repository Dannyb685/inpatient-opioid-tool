import Foundation

// MARK: - 1. The Data Models

// The Root JSON Wrapper
struct DrugDatabaseSchema: Codable {
    let version: String
    let lastUpdated: String
    let globalWarnings: [String]
    let evidenceQualityDefinitions: [String: String]
    
    // Compartment A: The Math (Legacy)
    let conversionFactors: [String: DrugSchema]
    
    // Compartment B: The Rich UI (New)
    let clinicalPharmacology: [String: DrugPharmacology]?
}

// Legacy Math Schema
struct DrugSchema: Codable {
    let routes: [ConversionFactor]
}

// Rich UI Schema (The "Master Card")
struct DrugPharmacology: Codable, Identifiable {
    // We explicitly set the ID after loading from the dictionary key
    var id: String = UUID().uuidString 
    
    let familyId: String?     // e.g. "morphine_generic"
    let name: String
    let subtitle: String?
    let route: String?        // "IV", "PO"
    
    let mmeFactor: Double?    // Display only
    let pkProfile: PharmacologyPKProfile?
    let safetyProfile: PharmacologySafetyProfile?
    let citations: [String]?
}

struct PharmacologyPKProfile: Codable {
    let onset: String
    let peak: String?
    let duration: String
    let bioavailability: String? // Nil for IV
}

struct PharmacologySafetyProfile: Codable {
    let renalNote: String?
    let boxedWarning: String?
}



// The Math Rule
struct ConversionFactor: Codable, Identifiable {
    var id: String { "\(route)_\(factor)" }
    
    let route: String
    let factor: Double
    let unit: String
    let evidenceQuality: String
    let source: String
    let citation: String
    let clinicalContext: String
    let warnings: [String]?
}

// MARK: - 2. The Service

class ConversionService {
    static let shared = ConversionService()
    
    // The "Math" Dictionary
    private var conversionTable: [String: DrugSchema] = [:]
    
    // The "UI" Dictionary
    private var masterDrugRegistry: [String: DrugPharmacology] = [:]
    
    // Global Metadata
    private var databaseMetadata: DrugDatabaseSchema?
    
    init() {
        loadData()
    }
    
    func loadData() {
        // 1. Locate JSON
        // SSOT STRATEGY: Aggressively search for the drug_database.json in standard bundles
        let candidateBundles = [
            Bundle.main,
            Bundle(for: ConversionService.self)
        ]
        
        var targetURL: URL? = nil
        
        for bundle in candidateBundles {
            if let url = bundle.url(forResource: "drug_database", withExtension: "json") {
                targetURL = url
                break
            }
        }
        
        if targetURL == nil {
             print("⚠️ ConversionService: drug_database.json not found in main bundle. Checking other bundles...")
        }
        
        guard let url = targetURL,
              let data = try? Data(contentsOf: url) else {
            print("❌ ConversionService: Critical Error - drug_database.json not found.")
            return
        }
        
        // 2. Decode
        do {
            let decoder = JSONDecoder()
            // Note: Your JSON is camelCase, so we don't need .convertFromSnakeCase
            let schema = try decoder.decode(DrugDatabaseSchema.self, from: data)
            
            // SECURITY: Validate Factors before accepting schema
            try validateFactors(schema)
            
            self.databaseMetadata = schema
            
            // 3. Store Math
            self.conversionTable = schema.conversionFactors
            
            // 4. Store UI Cards (and inject IDs)
            if let registry = schema.clinicalPharmacology {
                for (key, var drug) in registry {
                    drug.id = key // Inject the dictionary key (e.g., "morphine_iv") as the ID
                    self.masterDrugRegistry[key] = drug
                }
            }
            
            print("✅ ConversionService: Loaded \(conversionTable.count) Math Entries & \(masterDrugRegistry.count) UI Cards.")
            
        } catch {
            print("❌ ConversionService: JSON Decoding Error: \(error)")
        }
    }
    
    // MARK: - Public API (Math)
    
    func getFactor(drugId: String, route: String) -> ConversionFactor? {
        guard let schema = conversionTable[drugId] else { return nil }
        
        // 1. Exact Match
        if let match = schema.routes.first(where: { $0.route == route }) {
            return match
        }
        
        // 2. Fuzzy Logic for IV (Fallback safety)
        if route.contains("iv") {
             return schema.routes.first(where: { $0.route == "iv" || $0.route == "iv_continuous" })
        }
        
        return nil
    }
    
    // MARK: - Public API (UI)
    
    func getDrug(id: String) -> DrugPharmacology? {
        return masterDrugRegistry[id]
    }
    
    /// Returns all UI cards, sorted by name, for the Library List
    func getAllDrugs() -> [DrugPharmacology] {
        return Array(masterDrugRegistry.values).sorted {
            ($0.name + ($0.subtitle ?? "")).localizedStandardCompare($1.name + ($1.subtitle ?? "")) == .orderedAscending
        }
    }
    
    func getGlobalWarnings() -> [String] {
        return databaseMetadata?.globalWarnings ?? []
    }
    
    // MARK: - Validation Logic
    
    private func validateFactors(_ schema: DrugDatabaseSchema) throws {
        for (drugId, drugSchema) in schema.conversionFactors {
            for conversion in drugSchema.routes {
                if conversion.factor <= 0 {
                    // FIX: Guard Clause for Zero-MME Drugs
                    // Buprenorphine (Partial Agonist), Suzetrigine (Non-Opioid), etc.
                    // These have factor 0.0 effectively (handled via special logic), but should not break validation.
                    if isZeroFactorPermitted(drugId) {
                        continue
                    }
                    
                    // Logic from User Request: Throw if <= 0 and NOT permitted
                    throw NSError(domain: "ConversionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid factor (<= 0) for \(drugId)"])
                }
            }
        }
    }
    
    private func isZeroFactorPermitted(_ drugId: String) -> Bool {
        // defined permitted IDs
        let permittedContexts = [
            "buprenorphine",
            "butrans",
            "sublingual_fentanyl",
            "suzetrigine"
        ]
        
        if permittedContexts.contains(drugId) { return true }
        if drugId.contains("buprenorphine") { return true }
        
        // Check Clinical Data Type if available (Fallback)
        if let drug = ClinicalData.drugData.first(where: { $0.id == drugId }) {
            if drug.type == "Partial Agonist" || drug.type == "NAV1.8 Inhibitor" {
                return true
            }
        }
        
        return false
    }
}
