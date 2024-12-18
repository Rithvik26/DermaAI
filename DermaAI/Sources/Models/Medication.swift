//
//  Medication.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/14/24.
//


import Foundation

struct Medication: Identifiable, Codable {
    var id: UUID
    var name: String
    var dosage: String
    var frequency: String
    
    init(id: UUID = UUID(), name: String, dosage: String, frequency: String) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
    }
    
    // Add Firestore data conversion
    init?(dictionary: [String: Any]) {
        guard let idString = dictionary["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dictionary["name"] as? String,
              let dosage = dictionary["dosage"] as? String,
              let frequency = dictionary["frequency"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
    }
    
    // Convert to Firestore data
    var dictionary: [String: Any] {
        [
            "id": id.uuidString,
            "name": name,
            "dosage": dosage,
            "frequency": frequency
        ]
    }
}
