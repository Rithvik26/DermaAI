//
//  BatchAnalysisTests.js
//  DermaAI
//
//  Created by Rithvik Golthi on 12/23/24.
//

// File: DermaAITests/TestCases/BatchAnalysisTests.js

import { testUser, generateTestPatients } from '../TestHelpers/TestUtils.js';
import { skinConditions } from '../TestData/MockPatientData.js';

async function runBatchAnalysisTests() {
    console.log("Starting Batch Analysis Tests");
    
    // Test Case 1: User Authentication
    console.log("\n1. Testing User Authentication");
    try {
        // Sign in with test credentials
        await Auth.signIn(testUser.email, testUser.password);
        console.log("✓ User authentication successful");
    } catch (error) {
        console.error("✗ Authentication failed:", error);
        return;
    }

    // Test Case 2: Generate and Add Test Patients
    console.log("\n2. Generating Test Patients");
    const testPatients = generateTestPatients(100);
    try {
        for (const patient of testPatients) {
            await PatientViewModel.addPatient(patient);
        }
        console.log("✓ Successfully added 100 test patients");
    } catch (error) {
        console.error("✗ Failed to add test patients:", error);
        return;
    }

    // Test Case 3: Batch Analysis
    console.log("\n3. Running Batch Analysis");
    try {
        const analysisResults = await PatientViewModel.analyzePatientsInBatch();
        console.log("✓ Batch analysis completed");
        
        // Verify results
        verifyAnalysisResults(analysisResults);
    } catch (error) {
        console.error("✗ Batch analysis failed:", error);
        return;
    }

    // Test Case 4: Export Results
    console.log("\n4. Testing Export Functionality");
    try {
        const exportedData = await PatientViewModel.saveCSVToFile();
        console.log("✓ Successfully exported results to CSV");
    } catch (error) {
        console.error("✗ Export failed:", error);
    }
}

function verifyAnalysisResults(results) {
    // Verify all conditions are properly categorized
    const conditions = Object.keys(skinConditions);
    
    for (const group of results) {
        // Check if the disease matches known conditions
        if (!conditions.includes(group.disease)) {
            console.error(`✗ Unknown condition found: ${group.disease}`);
            continue;
        }

        // Check if recommended medications match condition
        const knownMeds = skinConditions[group.disease].medications;
        const invalidMeds = group.recommendedMedications.filter(med =>
            !knownMeds.includes(med)
        );
        
        if (invalidMeds.length > 0) {
            console.error(`✗ Invalid medications for ${group.disease}:`, invalidMeds);
        }

        console.log(`✓ Verified group: ${group.disease}`);
        console.log(`  - Patient count: ${group.patients.length}`);
        console.log(`  - Recommendations: ${group.recommendedMedications.length}`);
    }
}

// Execute tests
runBatchAnalysisTests().catch(console.error);

export { runBatchAnalysisTests };
