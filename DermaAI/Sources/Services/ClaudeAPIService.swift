import Foundation
import FirebaseAuth

// MARK: - Disease Group Model
struct DiseaseGroup: Identifiable, Codable {
    let id: UUID
    let disease: String
    let patients: [String]
    let recommendedMedications: [String]
    let timestamp: Date?
    
    init(id: UUID = UUID(), disease: String, patients: [String], recommendedMedications: [String], timestamp: Date? = nil) {
        self.id = id
        self.disease = disease
        self.patients = patients
        self.recommendedMedications = recommendedMedications
        self.timestamp = timestamp ?? Date()
    }
    
    // Add a method to convert to dictionary without server timestamp
    func toDictionary() -> [String: Any] {
        return [
            "disease": disease,
            "patients": patients,
            "recommendedMedications": recommendedMedications,
            "timestamp": timestamp ?? Date()  // Use regular Date instead of FieldValue.serverTimestamp()
        ]
    }
}

class ClaudeAPIService {
    static let shared = ClaudeAPIService()
    private let networkReachability = NetworkReachability.shared
#if DEBUG
    private let apiKey = Bundle.main.infoDictionary?["ANTHROPIC_API_KEY"] as? String ?? ""
#else
    private let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
#endif
    
    private init() {}
    
    // MARK: - Analysis Methods
    func analyzePatientsData(_ patients: [Patient]) async throws -> [DiseaseGroup] {
        guard !patients.isEmpty else {
            throw APIError.invalidData
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw APIError.authenticationError
        }
        
        let userPatients = patients.filter { $0.userId == userId }
        guard !userPatients.isEmpty else {
            throw APIError.invalidData
        }
        
        print("🔍 Analyzing \(userPatients.count) patients")
        let patientData = try await decryptAndFormatPatientData(userPatients)
        return try await performAnalysis(patientData: patientData)
    }
    
    private func decryptAndFormatPatientData(_ patients: [Patient]) async throws -> [[String: String]] {
        return try patients.map { patient in
            let decryptedNotes = try EncryptionService.shared.decrypt(patient.diagnosisNotes)
            return [
                "name": patient.name,
                "diagnosis": decryptedNotes
            ]
        }
    }
    
    private func performAnalysis(patientData: [[String: String]]) async throws -> [DiseaseGroup] {
        guard let endpoint = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw APIError.invalidURL
        }
        
        print("🌐 Preparing analysis request")
        
        let patientList = patientData.map { "Patient \($0["name"] ?? ""): \($0["diagnosis"] ?? "")" }
            .joined(separator: "\n")
        
        let messageRequest = MessageRequest(
            model: "claude-3-sonnet-20240229",
            max_tokens: 1024,
            messages: [
                MessageRequest.Message(
                    role: "assistant",
                    content: "You are a dermatology expert. Analyze the patient diagnoses and group them by condition."
                ),
                MessageRequest.Message(
                    role: "user",
                    content: """
                    Analyze these dermatological diagnoses and group patients by common skin conditions:
                    
                    \(patientList)
                    
                    Respond with only a JSON object in this exact format:
                    {
                        "groups": [
                            {
                                "disease": "Disease Name",
                                "patients": ["Patient Name 1", "Patient Name 2"],
                                "recommended_medications": ["Medication 1", "Medication 2"]
                            }
                        ]
                    }
                    """
                )
            ]
        )
        
        let response: ClaudeAPIResponse = try await sendRequest(
            to: endpoint,
            body: messageRequest
        )
        
        guard let content = response.content.first?.text,
              let jsonStart = content.firstIndex(of: "{"),
              let jsonData = String(content[jsonStart...]).data(using: .utf8) else {
            throw APIError.invalidData
        }
        
        let analysisResponse = try JSONDecoder().decode(AnalysisResponse.self, from: jsonData)
        
        return analysisResponse.groups.map { group in
            DiseaseGroup(
                disease: group.disease,
                patients: group.patients,
                recommendedMedications: group.recommended_medications,
                timestamp: Date()  // Use current date instead of server timestamp
            )
        }
    }
    
    private func sendRequest<T: Encodable, R: Decodable>(
        to endpoint: URL,
        body: T
    ) async throws -> R {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        print("📤 Request Headers:")
        print("Content-Type: application/json")
        print("anthropic-version: 2023-06-01")
        print("x-api-key length: \(apiKey.count)")
        
        let jsonData = try JSONEncoder().encode(body)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📥 Response Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorBody = String(data: data, encoding: .utf8) {
                print("❌ Error Response Body: \(errorBody)")
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        do {
            print("✅ Successfully received and decoded response")
            return try decoder.decode(R.self, from: data)
        } catch {
            print("❌ Decoding Error: \(error)")
            throw APIError.decodingError(error as! DecodingError)
        }
    }
    
    // MARK: - Test API Connection
    func testAPI() async throws -> String {
        guard !apiKey.isEmpty else {
            throw APIError.authenticationError
        }
        
        guard let endpoint = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw APIError.invalidURL
        }
        
        print("🔑 Testing API with key length: \(apiKey.count)")
        
        let messageRequest = MessageRequest(
            model: "claude-3-sonnet-20240229",
            max_tokens: 1024,
            messages: [
                MessageRequest.Message(
                    role: "user",
                    content: "Please respond with 'Test successful' if you receive this message."
                )
            ]
        )
        
        do {
            let response: ClaudeAPIResponse = try await sendRequest(
                to: endpoint,
                body: messageRequest
            )
            return response.content.first?.text ?? "No response"
        } catch {
            print("❌ API Test Failed: \(error.localizedDescription)")
            throw error
        }
    }
}
