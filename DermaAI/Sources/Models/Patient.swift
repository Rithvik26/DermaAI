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
    var userId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var recommendationStatus: RecommendationStatus?
    
    // Add this enum inside the Patient struct
    enum RecommendationStatus: String, Codable {
        case approved
        case disapproved
        case pending
    }
    
    init(id: UUID = UUID(), name: String, diagnosisNotes: String, medications: [Medication], diagnosisGroup: String? = nil, userId: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, recommendationStatus: RecommendationStatus? = nil) {
        self.id = id
        self.name = name
        self.diagnosisNotes = diagnosisNotes
        self.medications = medications
        self.diagnosisGroup = diagnosisGroup
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recommendationStatus = recommendationStatus
    }
    
    // Update dictionary conversion
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
        if let status = recommendationStatus {
            dict["recommendationStatus"] = status.rawValue
        }
        
        return dict
    }
    
    // Update initializer from dictionary
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
        
        if let statusString = dictionary["recommendationStatus"] as? String {
            self.recommendationStatus = RecommendationStatus(rawValue: statusString)
        }
        
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
}
