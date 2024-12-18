//
//  Patient.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/14/24.
//
import Foundation
import Firebase

struct Patient: Identifiable, Codable {
    var id: UUID
    var name: String
    var diagnosisNotes: String
    var medications: [Medication]
    var diagnosisGroup: String?
    var userId: String? // Add this for Firebase user association
    var createdAt: Date?
    var updatedAt: Date?
    
    init(id: UUID = UUID(), name: String, diagnosisNotes: String, medications: [Medication], diagnosisGroup: String? = nil, userId: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.diagnosisNotes = diagnosisNotes
        self.medications = medications
        self.diagnosisGroup = diagnosisGroup
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Add Firestore data conversion
    init?(dictionary: [String: Any]) {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dictionary["name"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.diagnosisNotes = dictionary["diagnosisNotes"] as? String ?? ""
        self.userId = dictionary["userId"] as? String
        self.diagnosisGroup = dictionary["diagnosisGroup"] as? String
        
        // Convert medications array
        if let medicationsData = dictionary["medications"] as? [[String: Any]] {
            self.medications = medicationsData.compactMap { Medication(dictionary: $0) }
        } else {
            self.medications = []
        }
        
        // Handle timestamps
        if let timestamp = dictionary["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        }
        if let timestamp = dictionary["updatedAt"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        }
    }
    
    // Convert to Firestore data
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "diagnosisNotes": diagnosisNotes,
            "medications": medications.map { $0.dictionary }
        ]
        
        if let userId = userId {
            dict["userId"] = userId
        }
        if let diagnosisGroup = diagnosisGroup {
            dict["diagnosisGroup"] = diagnosisGroup
        }
        if let createdAt = createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }
        if let updatedAt = updatedAt {
            dict["updatedAt"] = Timestamp(date: updatedAt)
        }
        
        return dict
    }
}
