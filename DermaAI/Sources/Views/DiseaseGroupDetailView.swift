import SwiftUI

struct DiseaseGroupDetailView: View {
    let diseaseGroup: DiseaseGroup
    @ObservedObject var viewModel: PatientViewModel
    @State private var expandedPatients: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private var matchedPatients: [(name: String, patient: Patient?)] {
        diseaseGroup.patients.map { patientName in
            (name: patientName,
             patient: viewModel.patients.first(where: { $0.name == patientName }))
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Debug information section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Disease: \(diseaseGroup.disease)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Total Patients in Group: \(diseaseGroup.patients.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text("Recommended Medications:")
                        .font(.subheadline)
                        .padding(.horizontal)
                    
                    ForEach(diseaseGroup.recommendedMedications, id: \.self) { med in
                        Text("• \(med)")
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground))
                
                // Patient cards
                ForEach(matchedPatients, id: \.name) { patientInfo in
                    if let patient = patientInfo.patient {
                        PatientGroupCard(
                            patient: patient,
                            isExpanded: expandedPatients.contains(patientInfo.name),
                            recommendedMedications: diseaseGroup.recommendedMedications,
                            recommendationStatus: patient.recommendationStatus,
                            onToggleExpand: { toggleExpand(patientInfo.name) },
                            onApprove: { approveMedications(for: patient) },
                            onDisapprove: { disapproveMedications(for: patient) }
                        )
                        .padding(.horizontal)
                    } else {
                        Text("Patient not found: \(patientInfo.name)")
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
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
                updatedPatient.recommendationStatus = .approved
                
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
        isLoading = true
        
        Task {
            do {
                var updatedPatient = patient
                
                // If the patient previously approved recommendations, remove them
                if patient.recommendationStatus == .approved {
                    // Get the set of recommended medication names
                    let recommendedMedNames = Set(diseaseGroup.recommendedMedications)
                    
                    // Filter out medications that were part of the recommendations
                    updatedPatient.medications = patient.medications.filter { medication in
                        !recommendedMedNames.contains(medication.name)
                    }
                }
                
                updatedPatient.recommendationStatus = .disapproved
                
                try await viewModel.updatePatient(updatedPatient)
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = patient.recommendationStatus == .approved ?
                        "Recommended medications have been removed" :
                        "Recommendations have been marked as disapproved"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to update patient: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}
struct PatientGroupCard: View {
    let patient: Patient
    let isExpanded: Bool
    let recommendedMedications: [String]
    let recommendationStatus: Patient.RecommendationStatus?
    let onToggleExpand: () -> Void
    let onApprove: () -> Void
    let onDisapprove: () -> Void
    
    @State private var decryptedNotes: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            Button(action: onToggleExpand) {
                HStack {
                    Text(patient.name)
                        .font(.headline)
                    
                    if let status = recommendationStatus {
                        Text(statusText(for: status))
                            .font(.caption)
                            .padding(4)
                            .background(statusColor(for: status).opacity(0.2))
                            .foregroundColor(statusColor(for: status))
                            .cornerRadius(4)
                    }
                    
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
                    if !decryptedNotes.isEmpty {
                        Text(decryptedNotes)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
                .task {
                    do {
                        decryptedNotes = try EncryptionService.shared.decrypt(patient.diagnosisNotes)
                    } catch {
                        decryptedNotes = "Error decrypting notes"
                    }
                }
                
                // Current Medications
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Medications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if patient.medications.isEmpty {
                        Text("No current medications")
                            .italic()
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(patient.medications) { medication in
                            Text("• \(medication.name)")
                                .font(.body)
                        }
                    }
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
                
                // Status message based on current state
                if let status = recommendationStatus {
                    HStack {
                        Image(systemName: statusIcon(for: status))
                        Text(statusMessage(for: status))
                            .font(.caption)
                    }
                    .foregroundColor(statusColor(for: status))
                    .padding(.top, 2)
                }
                
                // Action Buttons - Always visible
                HStack(spacing: 12) {
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(recommendationStatus == .approved ? .gray : .blue)
                    
                    Button(action: onDisapprove) {
                        Label("Disapprove", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(recommendationStatus == .disapproved ? .gray : .red)
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
    
    private func statusText(for status: Patient.RecommendationStatus) -> String {
        switch status {
        case .approved:
            return "Approved"
        case .disapproved:
            return "Disapproved"
        case .pending:
            return "Pending"
        }
    }
    
    private func statusMessage(for status: Patient.RecommendationStatus) -> String {
        switch status {
        case .approved:
            return "Recommendations approved and medications added"
        case .disapproved:
            return "Recommendations marked as disapproved"
        case .pending:
            return "Awaiting review"
        }
    }
    
    private func statusIcon(for status: Patient.RecommendationStatus) -> String {
        switch status {
        case .approved:
            return "checkmark.circle.fill"
        case .disapproved:
            return "xmark.circle.fill"
        case .pending:
            return "clock.fill"
        }
    }
    
    private func statusColor(for status: Patient.RecommendationStatus) -> Color {
        switch status {
        case .approved:
            return .green
        case .disapproved:
            return .red
        case .pending:
            return .orange
        }
    }
}
