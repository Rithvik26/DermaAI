//
//  AnalysisResponse.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/15/24.
//


// AnalysisResponse.swift

import Foundation

struct AnalysisResponse: Codable {
    let groups: [GroupData]
    
    struct GroupData: Codable {
        let disease: String
        let patients: [String]
        let recommended_medications: [String]
        
        enum CodingKeys: String, CodingKey {
            case disease
            case patients
            case recommended_medications
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case groups
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.groups = try container.decode([GroupData].self, forKey: .groups)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(groups, forKey: .groups)
    }
}

// Example JSON response structure:
/*
{
    "groups": [
        {
            "disease": "Acne Vulgaris",
            "patients": ["John Doe", "Jane Smith"],
            "recommended_medications": ["Benzoyl Peroxide", "Tretinoin"]
        },
        {
            "disease": "Eczema",
            "patients": ["Alice Johnson"],
            "recommended_medications": ["Hydrocortisone", "Moisturizer"]
        }
    ]
}
*/
