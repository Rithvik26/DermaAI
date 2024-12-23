
import SwiftUI

struct DiseaseGroupDetailView: View {
    let diseaseGroup: DiseaseGroup
    @ObservedObject var viewModel: PatientViewModel
    @State private var expandedPatients: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        List {
            ForEach(diseaseGroup.patients, id: \.self) { patientName in
                if let patient = viewModel.patients.first(where: { $0.name == patientName }) {
                    PatientGroupCard(
                        patient: patient,
                        isExpanded: expandedPatients.contains(patientName),
                        recommendedMedications: diseaseGroup.recommendedMedications,
                        onToggleExpand: { toggleExpand(patientName) },
                        onApprove: { approveMedications(for: patient) },
                        onDisapprove: { disapproveMedications(for: patient) }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .navigationTitle(diseaseGroup.disease)
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView()
            }
        }
    }
    
    private func toggleExpand(_ patientName: String) {
        if expandedPatients.contains(patientName) {
            expandedPatients.remove(patientName)
        } else {
            expandedPatients.insert(patientName)
        }
    }
    
    private func approveMedications(for patient: Patient) {
        isLoading = true
        
        Task {
            do {
                var updatedPatient = patient
                let newMedications = diseaseGroup.recommendedMedications.map { medName in
                    Medication(
                        name: medName,
                        dosage: "Dosage to be determined",
                        frequency: "Frequency to be determined"
                    )
                }
                
                // Add only medications that don't already exist
                let existingMedNames = Set(patient.medications.map { $0.name })
                let medicationsToAdd = newMedications.filter { !existingMedNames.contains($0.name) }
                updatedPatient.medications.append(contentsOf: medicationsToAdd)
                
                try await viewModel.updatePatient(updatedPatient)
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Medications added successfully"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to add medications: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func disapproveMedications(for patient: Patient) {
        alertMessage = "Recommendations discarded for \(patient.name)"
        showingAlert = true
    }
}

struct PatientGroupCard: View {
    let patient: Patient
    let isExpanded: Bool
    let recommendedMedications: [String]
    let onToggleExpand: () -> Void
    let onApprove: () -> Void
    let onDisapprove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: onToggleExpand) {
                HStack {
                    Text(patient.name)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                // Diagnosis Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Diagnosis Summary")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(try! EncryptionService.shared.decrypt(patient.diagnosisNotes))
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                
                // Recommended Medications
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Medications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ForEach(recommendedMedications, id: \.self) { medication in
                        Text("• \(medication)")
                            .font(.body)
                    }
                }
                .padding(.vertical, 4)
                
                // Action Buttons
                HStack {
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: onDisapprove) {
                        Label("Disapprove", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
        .animation(.spring(), value: isExpanded)
    }
}