//
//  ClaudeResponse.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/14/24.
//


import Foundation
import FirebaseAuth

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
        
        // Filter patients for current user
        let userPatients = patients.filter { $0.userId == userId }
        guard !userPatients.isEmpty else {
            throw APIError.invalidData
        }
        
        // Prepare patient data for analysis
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
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        let headers = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": "2024-02-15"
        ]
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let patientList = patientData.map { "Patient \($0["name"] ?? ""): \($0["diagnosis"] ?? "")" }
            .joined(separator: "\n")
        
        let messageRequest = MessageRequest(
            model: "claude-3-5-sonnet-20241022",
            max_tokens: 1024,
            messages: [
                MessageRequest.Message(
                    role: "system",
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
        
        return try await sendAnalysisRequest(request: request, messageRequest: messageRequest)
    }
    
    private func sendAnalysisRequest(request: URLRequest, messageRequest: MessageRequest) async throws -> [DiseaseGroup] {
        let jsonData = try JSONEncoder().encode(messageRequest)
        var request = request
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let claudeResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        
        guard let content = claudeResponse.content.first?.text,
              let jsonStart = content.firstIndex(of: "{"),
              let jsonData = String(content[jsonStart...]).data(using: .utf8) else {
            throw APIError.invalidData
        }
        
        let analysisResponse = try JSONDecoder().decode(AnalysisResponse.self, from: jsonData)
        
        return analysisResponse.groups.map { group in
            DiseaseGroup(
                disease: group.disease,
                patients: group.patients,
                recommendedMedications: group.recommended_medications
            )
        }
    }
    
    // MARK: - Test Methods
    func testAPI() async throws -> String {
        guard let endpoint = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        
        let headers = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": "2024-02-15"
        ]
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let messageRequest = MessageRequest(
            model: "claude-3-5-sonnet-20241022",
            max_tokens: 1024,
            messages: [
                MessageRequest.Message(
                    role: "user",
                    content: "Please respond with 'Test successful' if you receive this message."
                )
            ]
        )
        
        let jsonData = try JSONEncoder().encode(messageRequest)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let claudeResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        return claudeResponse.content.first?.text ?? "No response"
    }
}
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
        self.timestamp = timestamp
    }
}

