import SwiftUI

struct DiseaseGroupDetailView: View {
    let diseaseGroup: DiseaseGroup
    @ObservedObject var viewModel: PatientViewModel
    @State private var expandedPatients: Set<String> = []
    @State private var selectedPatients: Set<String> = []
    @State private var individualPatientLoading: [String: Bool] = [:]
    @State private var currentOperation: PatientOperation?
    @State private var operationQueue: [PatientOperation] = []
    @StateObject private var operationState = BatchOperationState()
    
    private struct PatientOperation: Equatable {
        let patient: Patient
        let isApproval: Bool
        
        static func == (lhs: PatientOperation, rhs: PatientOperation) -> Bool {
            return lhs.patient.id == rhs.patient.id && lhs.isApproval == rhs.isApproval
        }
    }
    
    private var matchedPatients: [(name: String, patient: Patient?)] {
        diseaseGroup.patients.map { patientName in
            (name: patientName,
             patient: viewModel.patients.first(where: { $0.name == patientName }))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                diseaseInfoSection
                
                if !selectedPatients.isEmpty {
                    batchOperationButtons
                }
                
                patientCardsList
            }
            .padding(.vertical)
        }
        .navigationTitle(diseaseGroup.disease)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if operationState.isProcessing {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView()
            }
        }
        .alert("Batch Operation", isPresented: $operationState.showingAlert) {
            Button("OK") { }
        } message: {
            Text(operationState.alertMessage)
        }
    }
    
    private var diseaseInfoSection: some View {
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
    }
    
    private var batchOperationButtons: some View {
        HStack {
            Button {
                performBatchOperation(isApproval: true)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Approve Selected (\(selectedPatients.count))")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(operationState.isProcessing)
            
            Button {
                performBatchOperation(isApproval: false)
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Disapprove Selected (\(selectedPatients.count))")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            .disabled(operationState.isProcessing)
        }
        .padding()
        .transition(.move(edge: .bottom))
        .animation(.default, value: selectedPatients)
    }
    
    private var patientCardsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(matchedPatients, id: \.name) { patientInfo in
                if let patient = patientInfo.patient {
                    PatientGroupCard(
                        patient: patient,
                        diseaseGroup: diseaseGroup,
                        isExpanded: expandedPatients.contains(patient.name),
                        isSelected: selectedPatients.contains(patient.name),
                        isLoading: operationState.processingPatients.contains(patient.name) ||
                        (individualPatientLoading[patient.name] ?? false),
                        onSelect: {
                            togglePatientSelection(patient.name)
                        },
                        onToggleExpand: {
                            toggleExpand(patient.name)
                        },
                        onApprove: {
                            queueOperation(PatientOperation(patient: patient, isApproval: true))
                        },
                        onDisapprove: {
                            queueOperation(PatientOperation(patient: patient, isApproval: false))
                        }
                    )
                    .padding(.horizontal)
                } else {
                    Text("Patient not found: \(patientInfo.name)")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func togglePatientSelection(_ patientName: String) {
        withAnimation {
            if selectedPatients.contains(patientName) {
                selectedPatients.remove(patientName)
            } else {
                selectedPatients.insert(patientName)
            }
        }
    }
    
    private func toggleExpand(_ patientName: String) {
        withAnimation {
            if expandedPatients.contains(patientName) {
                expandedPatients.remove(patientName)
            } else {
                expandedPatients.insert(patientName)
            }
        }
    }
    
    private func performBatchOperation(isApproval: Bool) {
        guard !selectedPatients.isEmpty else { return }
        
        // Reset state
        operationState.reset()
        operationState.isProcessing = true
        
        // Suspend listener before batch operation
        viewModel.suspendListener()
        
        Task {
            var successCount = 0
            var failureCount = 0
            
            for patientName in selectedPatients {
                if let patient = viewModel.patients.first(where: { $0.name == patientName }) {
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
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
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
        }
    }
    
    private func updatePatientRecommendation(_ patient: Patient, isApproval: Bool) async throws -> Patient {
        var updatedPatient = patient
        
        if isApproval {
            // Filter out existing medications to avoid duplicates
            let existingMedNames = Set(patient.medications.map { $0.name })
            let newMedications = diseaseGroup.recommendedMedications
                .filter { !existingMedNames.contains($0) }
                .map { medName in
                    Medication(
                        name: medName,
                        dosage: "Dosage to be determined",
                        frequency: "Frequency to be determined"
                    )
                }
            
            updatedPatient.medications.append(contentsOf: newMedications)
            updatedPatient.recommendationStatus = .approved
        } else {
            // Remove only the recommended medications that exist in the patient's current medications
            let recommendedMedNames = Set(diseaseGroup.recommendedMedications)
            updatedPatient.medications = patient.medications.filter { medication in
                !recommendedMedNames.contains(medication.name)
            }
            updatedPatient.recommendationStatus = .disapproved
        }
        
        return updatedPatient
    }
    
    private func queueOperation(_ operation: PatientOperation) {
        guard !operationQueue.contains(operation) else { return }
        
        operationQueue.append(operation)
        processNextOperation()
    }
    
    private func processNextOperation() {
        guard currentOperation == nil, let nextOperation = operationQueue.first else { return }
        
        currentOperation = nextOperation
        operationQueue.removeFirst()
        
        Task {
            await processOperation(nextOperation)
            await MainActor.run {
                currentOperation = nil
                processNextOperation()
            }
        }
    }
    
    private func processOperation(_ operation: PatientOperation) async {
        let wasExpanded = expandedPatients.contains(operation.patient.name)
        
        await MainActor.run {
            individualPatientLoading[operation.patient.name] = true
            viewModel.suspendListener()
        }
        
        do {
            let updatedPatient = try await updatePatientRecommendation(
                operation.patient,
                isApproval: operation.isApproval
            )
            try await viewModel.updatePatient(updatedPatient)
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                individualPatientLoading[operation.patient.name] = false
                if wasExpanded {
                    expandedPatients.insert(operation.patient.name)
                }
                viewModel.resumeListener()
            }
        } catch {
            await MainActor.run {
                individualPatientLoading[operation.patient.name] = false
                print("Failed to update patient: \(error.localizedDescription)")
                viewModel.resumeListener()
            }
        }
    }
}


// Patient card within the disease group
struct PatientGroupCard: View {
    let patient: Patient
    let diseaseGroup: DiseaseGroup
    let isExpanded: Bool
    let isSelected: Bool
    let isLoading: Bool
    let onSelect: () -> Void
    let onToggleExpand: () -> Void
    let onApprove: () -> Void
    let onDisapprove: () -> Void
    
    @State private var decryptedNotes: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .disabled(isLoading)
                
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: onToggleExpand) {
                        HStack {
                            Text(patient.name)
                                .font(.headline)
                            
                            if let status = patient.recommendationStatus {
                                Text(statusText(for: status))
                                    .font(.caption)
                                    .padding(4)
                                    .background(statusColor(for: status).opacity(0.2))
                                    .foregroundColor(statusColor(for: status))
                                    .cornerRadius(4)
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                            
                            Spacer()
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(decryptedNotes.isEmpty ? "Loading notes..." : decryptedNotes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .task {
                            do {
                                decryptedNotes = try EncryptionService.shared.decrypt(patient.diagnosisNotes)
                            } catch {
                                decryptedNotes = "Error decrypting notes"
                            }
                        }
                    
                    // Current Medications Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Medications:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if patient.medications.isEmpty {
                            Text("No current medications")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(patient.medications) { medication in
                                Text("• \(medication.name) (\(medication.dosage), \(medication.frequency))")
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Recommended Medications Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended Medications:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(diseaseGroup.recommendedMedications, id: \.self) { medication in
                            Text("• \(medication)")
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Button(action: onApprove) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Approve")
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .background(patient.recommendationStatus == .approved ? Color.gray : Color.blue)
                            .cornerRadius(8)
                        }
                        .disabled(isLoading || patient.recommendationStatus == .approved)
                        
                        Button(action: onDisapprove) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Disapprove")
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .background(patient.recommendationStatus == .disapproved ? Color.gray : Color.red)
                            .cornerRadius(8)
                        }
                        .disabled(isLoading || patient.recommendationStatus == .disapproved)
                    }
                }
                .padding(.top)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
    
    private func statusText(for status: Patient.RecommendationStatus) -> String {
        switch status {
        case .approved: return "Approved"
        case .disapproved: return "Disapproved"
        case .pending: return "Pending"
        }
    }
    
    private func statusColor(for status: Patient.RecommendationStatus) -> Color {
        switch status {
        case .approved: return .green
        case .disapproved: return .red
        case .pending: return .orange
        }
    }
}

#Preview {
    NavigationView {
        DiseaseGroupDetailView(
            diseaseGroup: DiseaseGroup(
                disease: "Sample Disease",
                patients: ["Patient 1", "Patient 2"],
                recommendedMedications: ["Med 1", "Med 2"]
            ),
            viewModel: PatientViewModel()
        )
    }
}
