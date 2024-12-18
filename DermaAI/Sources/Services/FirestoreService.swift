import FirebaseFirestore
import FirebaseAuth
import Combine
import Network

class FirestoreService {
    static let shared = FirestoreService()
    let encryptionService = EncryptionService.shared
    private let networkReachability = NetworkReachability.shared
    
    // Collections
    private let patientsCollection = "patients"
    private let auditLogsCollection = "auditLogs"
    private let db = Firestore.firestore()
    
    private init() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
        
        // Ensure we have a valid auth state
        if Auth.auth().currentUser == nil {
            print("⚠️ Warning: No authenticated user when initializing FirestoreService")
        }
    }
    
    func addPatient(_ patient: Patient) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Authentication error: No current user")
            throw FirestoreError.notAuthenticated
        }
        
        guard networkReachability.isConnected else {
            print("❌ Network error: Device is offline")
            throw FirestoreError.offlineError
        }
        
        let docRef = db.collection(patientsCollection).document(patient.id.uuidString)
        
        var patientData = patient.dictionary
        patientData["userId"] = userId // Ensure userId is set
        patientData["createdAt"] = FieldValue.serverTimestamp()
        
        print("📝 Attempting to add patient with ID: \(patient.id.uuidString)")
        
        do {
            try await docRef.setData(patientData)
            print("✅ Successfully added patient")
            try await self.logAction(action: "create", patientId: patient.id.uuidString)
        } catch {
            print("❌ Firestore error: \(error)")
            throw error
        }
    }

    
    func updatePatient(_ patient: Patient) async throws {
        guard networkReachability.isConnected else {
            throw FirestoreError.offlineError
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        let docRef = db.collection(patientsCollection).document(patient.id.uuidString)
        
        // Verify ownership
        let doc = try await docRef.getDocument()
        guard let data = doc.data(),
              let docUserId = data["userId"] as? String,
              docUserId == userId else {
            throw FirestoreError.notAuthorized
        }
        
        // Prepare update data
        var patientData = patient.dictionary
        patientData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await withTimeout(seconds: 10) {
            try await docRef.updateData(patientData)
            try await self.logAction(action: "update", patientId: patient.id.uuidString)
        }
    }
    
    func deletePatient(_ patient: Patient) async throws {
        guard networkReachability.isConnected else {
            throw FirestoreError.offlineError
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.notAuthenticated
        }
        
        let docRef = db.collection(patientsCollection).document(patient.id.uuidString)
        
        // Verify ownership
        let doc = try await docRef.getDocument()
        guard let data = doc.data(),
              let docUserId = data["userId"] as? String,
              docUserId == userId else {
            throw FirestoreError.notAuthorized
        }
        
        try await withTimeout(seconds: 10) {
            try await docRef.delete()
            try await self.logAction(action: "delete", patientId: patient.id.uuidString)
        }
    }
    
    private func waitForOnlineState() async throws {
        let timeout = 5.0 // 5 seconds timeout
        let startTime = Date()
        
        while !networkReachability.isConnected {
            if Date().timeIntervalSince(startTime) > timeout {
                throw FirestoreError.offlineError
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the actual operation
            group.addTask {
                try await operation()
            }
            
            // Add a timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            // Return the first completed result or throw the first error
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            // Cancel any remaining tasks
            group.cancelAll()
            
            return result
        }
    }
    
    // MARK: - Audit Logging
    private func logAction(action: String, patientId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let log = [
            "userId": userId,
            "action": action,
            "patientId": patientId,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        try await db.collection(auditLogsCollection).addDocument(data: log)
    }
}

struct TimeoutError: Error {}

enum FirestoreError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case documentNotFound
    case invalidData
    case timeoutError
    case offlineError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .notAuthorized:
            return "User is not authorized to access this document"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format or document already exists"
        case .timeoutError:
            return "Operation timed out. Please try again"
        case .offlineError:
            return "You are currently offline. Please check your internet connection and try again"
        case .networkError:
            return "Network error occurred. Please check your connection and try again"
        }
    }
}
