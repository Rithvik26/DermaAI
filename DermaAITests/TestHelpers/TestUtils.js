//
//  TestUtils.js
//  DermaAI
//
//  Created by Rithvik Golthi on 12/23/24.
//

// File: DermaAITests/TestHelpers/TestUtils.js

import { skinConditions } from '../TestData/MockPatientData.js';

export const testUser = {
    email: "test@dermaai.com",
    password: "TestPassword123!"
};

function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}

function generateDosage() {
    const strengths = ["2.5%", "5%", "10%", "25mg", "50mg", "100mg"];
    return strengths[Math.floor(Math.random() * strengths.length)];
}

function generateFrequency() {
    const frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed"];
    return frequencies[Math.floor(Math.random() * frequencies.length)];
}

export function generateTestPatients(count = 100) {
    const patients = [];
    const conditions = Object.keys(skinConditions);
    
    for (let i = 0; i < count; i++) {
        const condition = conditions[Math.floor(Math.random() * conditions.length)];
        const conditionData = skinConditions[condition];
        
        // Generate random subset of symptoms
        const symptomCount = 2 + Math.floor(Math.random() * 3);
        const selectedSymptoms = shuffleArray([...conditionData.symptoms])
            .slice(0, symptomCount)
            .join(", ");
        
        // Generate random subset of medications
        const medCount = 1 + Math.floor(Math.random() * 3);
        const selectedMeds = shuffleArray([...conditionData.medications])
            .slice(0, medCount)
            .map(med => ({
                name: med,
                dosage: generateDosage(),
                frequency: generateFrequency()
            }));

        patients.push({
            id: `patient_${i + 1}`,
            name: `Test Patient ${i + 1}`,
            diagnosisNotes: `Patient presents with ${selectedSymptoms}. Clinical examination suggests ${condition}.`,
            medications: selectedMeds
        });
    }
    return patients;
}
