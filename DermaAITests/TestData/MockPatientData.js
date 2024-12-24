//
//  MockPatientData.js
//  DermaAI
//
//  Created by Rithvik Golthi on 12/23/24.
//

// File: DermaAITests/TestData/MockPatientData.js

const skinConditions = {
    "Acne Vulgaris": {
        symptoms: [
            "inflammatory papules",
            "pustules",
            "comedones",
            "oily skin",
            "facial redness"
        ],
        medications: [
            "Benzoyl Peroxide",
            "Tretinoin",
            "Clindamycin",
            "Isotretinoin",
            "Doxycycline"
        ]
    },
    "Atopic Dermatitis": {
        symptoms: [
            "dry itchy skin",
            "redness",
            "inflammation",
            "scaling",
            "cracking"
        ],
        medications: [
            "Topical Corticosteroids",
            "Tacrolimus",
            "Pimecrolimus",
            "Dupixent",
            "Antihistamines"
        ]
    },
    "Psoriasis": {
        symptoms: [
            "thick red patches",
            "silvery scales",
            "dry cracked skin",
            "itching",
            "burning"
        ],
        medications: [
            "Methotrexate",
            "Cyclosporine",
            "Adalimumab",
            "Topical Steroids",
            "Vitamin D Analogs"
        ]
    },
    "Rosacea": {
        symptoms: [
            "facial redness",
            "visible blood vessels",
            "bumps",
            "skin sensitivity",
            "burning sensation"
        ],
        medications: [
            "Metronidazole",
            "Azelaic Acid",
            "Ivermectin",
            "Brimonidine",
            "Doxycycline"
        ]
    },
    "Seborrheic Dermatitis": {
        symptoms: [
            "scaly patches",
            "redness",
            "dandruff",
            "itching",
            "greasy skin"
        ],
        medications: [
            "Ketoconazole",
            "Zinc Pyrithione",
            "Selenium Sulfide",
            "Hydrocortisone",
            "Antifungal Creams"
        ]
    },
    "Contact Dermatitis": {
        symptoms: [
            "red rash",
            "itching",
            "burning",
            "blisters",
            "skin tenderness"
        ],
        medications: [
            "Hydrocortisone",
            "Calamine Lotion",
            "Oral Antihistamines",
            "Topical Steroids",
            "Moisturizers"
        ]
    }
};

export { skinConditions };
