
//  BatchOperationHandler.swift

import SwiftUI
import Combine

@MainActor
class BatchOperationState: ObservableObject {
    @Published var isProcessing = false
    @Published var processingPatients: Set<String> = []
    @Published var completedPatients: Set<String> = []
    @Published var failedPatients: Set<String> = []
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    func reset() {
        processingPatients.removeAll()
        completedPatients.removeAll()
        failedPatients.removeAll()
        isProcessing = false
    }
}

struct BatchOperationHandler {
    let viewModel: PatientViewModel
    let diseaseGroup: DiseaseGroup
    @Binding var selectedPatients: Set<String>
    @Binding var expandedPatients: Set<String>
    let operationState: BatchOperationState
    
    func performBatchOperation(isApproval: Bool) async {
        guard !selectedPatients.isEmpty else { return }
        
        // Reset state
        await MainActor.run {
            operationState.reset()
            operationState.isProcessing = true
        }
        
        // Suspend listener before batch operation
        await viewModel.suspendListener()
        
        var successCount = 0
        var failureCount = 0
        
        do {
            for patientName in selectedPatients {
                if let patient = await viewModel.patients.first(where: { $0.name == patientName }) {
                    do {
                        await MainActor.run {
                            operationState.processingPatients.insert(patientName)
                        }
                        
                        // Preserve expanded state
                        let wasExpanded = expandedPatients.contains(patientName)
                        
                        let updatedPatient = try await updatePatientRecommendation(patient, isApproval: isApproval)
                        try await viewModel.updatePatient(updatedPatient)
                        
                        // Update states
                        await MainActor.run {
                            operationState.processingPatients.remove(patientName)
                            operationState.completedPatients.insert(patientName)
                        }
                        
                        // Restore expanded state
                        if wasExpanded {
                            await MainActor.run {
                                expandedPatients.insert(patientName)
                            }
                        }
                        
                        successCount += 1
                        
                        // Add slight delay between operations
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    } catch {
                        await MainActor.run {
                            operationState.processingPatients.remove(patientName)
                            operationState.failedPatients.insert(patientName)
                        }
                        failureCount += 1
                        print("Failed to update patient \(patient.name): \(error)")
                    }
                }
            }
            
            // Brief pause to ensure all Firestore operations complete
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                operationState.isProcessing = false
                
                // Prepare completion message
                if successCount == selectedPatients.count {
                    operationState.alertMessage = isApproval
                        ? "All selected patients' recommendations approved"
                        : "All selected patients' recommendations disapproved"
                } else {
                    operationState.alertMessage = "\(successCount) patients updated successfully. \(failureCount) patients failed to update."
                }
                
                operationState.showingAlert = true
                selectedPatients.removeAll()
                viewModel.resumeListener()
            }
        } catch {
            await MainActor.run {
                operationState.isProcessing = false
                viewModel.resumeListener()
            }
        }
    }
    
    // Changed from private to internal access
    func updatePatientRecommendation(_ patient: Patient, isApproval: Bool) async throws -> Patient {
        var updatedPatient = patient
        
        if isApproval {
            let newMedications = diseaseGroup.recommendedMedications.map { medName in
                Medication(
                    name: medName,
                    dosage: "Dosage to be determined",
                    frequency: "Frequency to be determined"
                )
            }
            
            let existingMedNames = Set(patient.medications.map { $0.name })
            let medicationsToAdd = newMedications.filter { !existingMedNames.contains($0.name) }
            updatedPatient.medications.append(contentsOf: medicationsToAdd)
            updatedPatient.recommendationStatus = .approved
        } else {
            if patient.recommendationStatus == .approved {
                let recommendedMedNames = Set(diseaseGroup.recommendedMedications)
                updatedPatient.medications = patient.medications.filter { medication in
                    !recommendedMedNames.contains(medication.name)
                }
            }
            updatedPatient.recommendationStatus = .disapproved
        }
        
        return updatedPatient
    }
}
