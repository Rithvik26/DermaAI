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
    // Add to PatientViewModel class
    @MainActor
    func batchDeletePatients(_ patients: [Patient]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        for patient in patients {
            do {
                try await firestoreService.deletePatient(patient)
            } catch {
                print("Error deleting patient \(patient.name): \(error.localizedDescription)")
                throw error
            }
        }
    }
    // In PatientViewModel class
    func deleteMedication(_ medication: Medication, from patient: Patient) async throws {
        isLoading = true
        defer { isLoading = false }
        
        var updatedPatient = patient
        updatedPatient.medications.removeAll { $0.id == medication.id }
        
        // Encrypt the updated medications if necessary
        var encryptedMedications: [Medication] = []
        for var med in updatedPatient.medications {
            med.dosage = try firestoreService.encryptionService.encrypt(med.dosage)
            encryptedMedications.append(med)
        }
        updatedPatient.medications = encryptedMedications
        
        // Update the patient in Firestore
        try await updatePatient(updatedPatient)
        
        // Update the local patients array immediately
        if let index = patients.firstIndex(where: { $0.id == patient.id }) {
            patients[index] = updatedPatient
        }
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
    // In PatientViewModel
    func analyzePatientsInBatch() async throws {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let analysisResult = try await ClaudeAPIService.shared.analyzePatientsData(patients)
                self.analysisResults = analysisResult
                self.updateDiagnosisGroups()
                
                // Store results without waiting
                Task {
                    await storeAnalysisResults(analysisResult)
                }
            } catch {
                handleError(error)
                throw error
            }
        }

        private func storeAnalysisResults(_ results: [DiseaseGroup]) async {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            do {
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
                
                print("✅ Analysis results stored successfully")
            } catch {
                print("❌ Failed to store analysis results: \(error.localizedDescription)")
                // Handle error but don't throw since this is a background operation
                errorMessage = "Failed to save analysis results: \(error.localizedDescription)"
                showError = true
            }
        }
    
    func testAPI() async throws -> String {
        return try await ClaudeAPIService.shared.testAPI()
    }
    
    
}
