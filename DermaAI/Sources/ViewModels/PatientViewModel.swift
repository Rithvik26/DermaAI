import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class PatientViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var patients: [Patient] = []
    @Published var diagnosisGroups: [String: [Patient]] = [:]
    @Published var analysisResults: [DiseaseGroup] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showError = false
    @Published var searchText = ""

    
    // MARK: - Private Properties
    private let firestoreService: FirestoreService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    private var firestoreListener: ListenerRegistration?
#if DEBUG
private let apiKey = Bundle.main.infoDictionary?["FIREBASE_API_KEY"] as? String ?? ""
#else
private let apiKey = ProcessInfo.processInfo.environment["FIREBASE_API_KEY"] ?? ""
#endif
    private let db = Firestore.firestore()
    
    var filteredPatients: [Patient] {
            guard !searchText.isEmpty else { return patients }
            return patients.filter { patient in
                patient.name.localizedCaseInsensitiveContains(searchText) ||
                patient.diagnosisNotes.localizedCaseInsensitiveContains(searchText) ||
                patient.medications.contains { medication in
                    medication.name.localizedCaseInsensitiveContains(searchText) ||
                    medication.dosage.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    
    // MARK: - Initialization
    init(firestoreService: FirestoreService = .shared, authService: AuthenticationService = .shared) {
        self.firestoreService = firestoreService
        self.authService = authService
        setupAuthSubscription()
        
        // Immediately set up listener if user is already authenticated
        if let userId = authService.currentUser?.uid {
            Task {
                await setupFirestoreListener()
            }
        }
    }
    
    deinit {
            Task { @MainActor in
                cleanupFirestoreListener()
            }
        }
    
    
    
    // MARK: - Authentication Handling
    private func setupAuthSubscription() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                Task {
                    if user != nil {
                        await self.setupFirestoreListener()
                    } else {
                        self.cleanupFirestoreListener()
                        self.patients = []
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Firestore Listener Setup
    private func setupFirestoreListener() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No authenticated user found when setting up listener")
            return
        }
        
        // Clean up existing listener if any
        cleanupFirestoreListener()
        
        print("🔄 Setting up Firestore listener for user: \(userId)")
        
        firestoreListener = db.collection("patients")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Firestore listener error: \(error)")
                    self.handleError(error)
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("⚠️ No snapshot received")
                    return
                }
                
                print("📥 Received Firestore update with \(snapshot.documents.count) documents")
                
                Task {
                    do {
                        let updatedPatients = try await self.processPatientsSnapshot(snapshot)
                        await MainActor.run {
                            print("✅ Updating patients array with \(updatedPatients.count) patients")
                            self.patients = updatedPatients
                            self.updateDiagnosisGroups()
                        }
                    } catch {
                        print("❌ Error processing patients: \(error)")
                        self.handleError(error)
                    }
                }
            }
    }
    
    private func cleanupFirestoreListener() {
        firestoreListener?.remove()
        firestoreListener = nil
    }
    
    // MARK: - Patient Management
    func addPatient(_ patient: Patient) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        var newPatient = patient
        newPatient.userId = userId
        newPatient.createdAt = Date()
        
        do {
            print("🔒 Encrypting patient data for: \(patient.name)")
            let encryptedPatient = try await encryptPatientData(newPatient)
            
            print("💾 Adding patient to Firestore")
            try await withTimeout(seconds: 15) {
                try await self.firestoreService.addPatient(encryptedPatient)
            }
            print("✅ Successfully added patient: \(patient.name)")
        } catch {
            print("❌ Error adding patient: \(error)")
            throw error
        }
    }
    
    func updatePatient(_ patient: Patient) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        var updatedPatient = patient
        updatedPatient.userId = userId
        updatedPatient.updatedAt = Date()
        
        print("🔄 Updating patient: \(patient.name)")
        let encryptedPatient = try await encryptPatientData(updatedPatient)
        try await firestoreService.updatePatient(encryptedPatient)
        print("✅ Successfully updated patient: \(patient.name)")
    }
    
    func deletePatient(_ patient: Patient) async throws {
        isLoading = true
        defer { isLoading = false }
        
        print("🗑️ Deleting patient: \(patient.name)")
        try await firestoreService.deletePatient(patient)
        print("✅ Successfully deleted patient: \(patient.name)")
    }
    
    // MARK: - Helper Methods
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw FirestoreError.timeoutError
            }
            
            guard let result = try await group.next() else {
                throw FirestoreError.timeoutError
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private func encryptPatientData(_ patient: Patient) async throws -> Patient {
        var encryptedPatient = patient
        
        // Encrypt diagnosis notes
        encryptedPatient.diagnosisNotes = try firestoreService.encryptionService.encrypt(patient.diagnosisNotes)
        
        // Encrypt medications
        var encryptedMedications = patient.medications
        for i in 0..<encryptedMedications.count {
            let encryptedDosage = try firestoreService.encryptionService.encrypt(encryptedMedications[i].dosage)
            encryptedMedications[i].dosage = encryptedDosage
        }
        encryptedPatient.medications = encryptedMedications
        
        return encryptedPatient
    }
    
    private func processPatientsSnapshot(_ snapshot: QuerySnapshot) async throws -> [Patient] {
        var processedPatients: [Patient] = []
        print("🔄 Processing \(snapshot.documents.count) patients from Firestore")
        
        for document in snapshot.documents {
            do {
                let data = document.data()
                print("📄 Processing document: \(document.documentID)")
                
                // Create a copy of the data to modify
                var processedData = data
                
                // Try decrypting diagnosis notes if present
                if let encryptedDiagnosis = data["diagnosisNotes"] as? String {
                    do {
                        print("🔐 Attempting to decrypt diagnosis notes")
                        let decryptedDiagnosis = try firestoreService.encryptionService.decrypt(encryptedDiagnosis)
                        processedData["diagnosisNotes"] = decryptedDiagnosis
                    } catch {
                        print("⚠️ Failed to decrypt diagnosis notes, using original value")
                        processedData["diagnosisNotes"] = encryptedDiagnosis
                    }
                }
                
                // Try decrypting medications if present
                if let medications = data["medications"] as? [[String: Any]] {
                    print("🔐 Attempting to decrypt \(medications.count) medications")
                    do {
                        let decryptedMeds = try await decryptMedications(medications)
                        processedData["medications"] = decryptedMeds
                    } catch {
                        print("⚠️ Failed to decrypt medications, using original values")
                        processedData["medications"] = medications
                    }
                }
                
                // Ensure required fields are present
                guard let idString = processedData["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let name = processedData["name"] as? String else {
                    print("❌ Missing required fields in document")
                    continue
                }
                
                // Create patient with processed data
                if let patient = Patient(dictionary: processedData) {
                    print("✅ Successfully processed patient: \(patient.name)")
                    processedPatients.append(patient)
                } else {
                    print("⚠️ Failed to create patient from processed data")
                }
            } catch {
                print("❌ Error processing document \(document.documentID): \(error.localizedDescription)")
                // Continue processing other documents even if one fails
                continue
            }
        }
        
        let sortedPatients = processedPatients.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        print("✅ Processed total of \(sortedPatients.count) patients")
        return sortedPatients
    }

    private func decryptMedications(_ medications: [[String: Any]]) async throws -> [[String: Any]] {
        var decryptedMedications: [[String: Any]] = []
        
        for var medication in medications {
            if let encryptedDosage = medication["dosage"] as? String {
                do {
                    let decryptedDosage = try firestoreService.encryptionService.decrypt(encryptedDosage)
                    medication["dosage"] = decryptedDosage
                } catch {
                    print("⚠️ Failed to decrypt medication dosage, using original value")
                    // Keep the original encrypted value rather than failing
                    medication["dosage"] = encryptedDosage
                }
            }
            decryptedMedications.append(medication)
        }
        
        return decryptedMedications
    }
    
    private func updateDiagnosisGroups() {
        var newGroups: [String: [Patient]] = [:]
        for group in analysisResults {
            let matchedPatients = patients.filter { patient in
                group.patients.contains(patient.name)
            }
            newGroups[group.disease] = matchedPatients
        }
        diagnosisGroups = newGroups
    }
    
    private func handleError(_ error: Error) {
        errorMessage = switch error {
        case let firestoreError as FirestoreError:
            firestoreError.localizedDescription
        case let apiError as APIError:
            apiError.localizedDescription
        default:
            error.localizedDescription
        }
        showError = true
    }
    
    // MARK: - Analysis Methods
    func analyzePatientsInBatch() async throws {
        guard !patients.isEmpty else {
            throw APIError.invalidData
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let patientData = patients.map { patient in
            ["name": patient.name, "diagnosis": patient.diagnosisNotes]
        }
        
        do {
            let analysisResult = try await performBatchAnalysis(patientData: patientData)
            self.analysisResults = analysisResult
            self.updateDiagnosisGroups()
            
            Task {
                try? await self.storeAnalysisResults(analysisResult)
            }
        } catch {
            handleError(error)
            throw error
        }
    }
    
    private func performBatchAnalysis(patientData: [[String: String]]) async throws -> [DiseaseGroup] {
        guard let endpoint = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        
        let headers = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
            "anthropic-version": "2024-02-15"
        ]
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let patientList = patientData.map { "Patient \($0["name"] ?? ""): \($0["diagnosis"] ?? "")" }
            .joined(separator: "\n")
        
        let systemPrompt = "You are a dermatology expert. Analyze the patient diagnoses and group them by condition."
        
        let messageRequest = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1024,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": """
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
                    """]
            ]
        ] as [String: Any]
        
        return try await sendAnalysisRequest(request: request, messageRequest: messageRequest)
    }
    
    private func sendAnalysisRequest(request: URLRequest, messageRequest: [String: Any]) async throws -> [DiseaseGroup] {
        let jsonData = try JSONSerialization.data(withJSONObject: messageRequest)
        var request = request
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("API Error Response: \(errorStr)")
            }
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
    
    private func storeAnalysisResults(_ results: [DiseaseGroup]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let analysisData: [[String: Any]] = results.map { group in
            [
                "disease": group.disease,
                "patients": group.patients,
                "recommendedMedications": group.recommendedMedications,
                "timestamp": FieldValue.serverTimestamp()
            ]
        }
        
        try await db.collection("users").document(userId)
            .collection("analyses")
            .document(UUID().uuidString)
            .setData(["groups": analysisData])
    }
    
    // MARK: - API Testing
    func testAPI(messages: [[String: String]] = []) async throws -> String {
        guard let endpoint = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        
        let headers = [
            "Content-Type": "application/json",
            "x-api-key": apiKey,
                        "anthropic-version": "2024-02-15"
                    ]
                    
                    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
                    
                    let messageRequest = [
                        "model": "claude-3-5-sonnet-20241022",
                        "max_tokens": 1024,
                        "messages": [
                            [
                                "role": "user",
                                "content": "Please respond with 'Test successful' if you receive this message."
                            ]
                        ]
                    ] as [String: Any]
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: messageRequest)
                    request.httpBody = jsonData
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    if httpResponse.statusCode != 200 {
                        if let errorStr = String(data: data, encoding: .utf8) {
                            print("Error Response: \(errorStr)")
                        }
                        throw APIError.serverError(statusCode: httpResponse.statusCode)
                    }
                    
                    let claudeResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
                    return claudeResponse.content.first?.text ?? ""
                }
                
                // MARK: - Error Handling
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
            }
