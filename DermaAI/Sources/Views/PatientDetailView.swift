import SwiftUI

struct PatientDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let patient: Patient
    @ObservedObject var viewModel: PatientViewModel  // Make sure this is ObservedObject
    @State private var isEditing = false
    @State private var decryptedDiagnosisNotes: String = ""
    @State private var decryptedMedications: [Medication] = []
    @State private var showingDeleteAlert = false
    @State private var showingDeleteMedicationAlert = false
    @State private var medicationToDelete: Medication?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        Form {
            Section(header: Text("Diagnosis")) {
                Text(decryptedDiagnosisNotes.isEmpty ? "No diagnosis notes" : decryptedDiagnosisNotes)
                    .foregroundColor(decryptedDiagnosisNotes.isEmpty ? .secondary : .primary)
                if let group = patient.diagnosisGroup {
                    Text("Category: \(group)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Medications")) {
                if decryptedMedications.isEmpty {
                    Text("No medications")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(decryptedMedications) { medication in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(medication.name)
                                    .font(.headline)
                                Text("\(medication.dosage) - \(medication.frequency)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            
                            Spacer()
                            
                            // Delete medication button
                            Button(action: {
                                medicationToDelete = medication
                                showingDeleteMedicationAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(patient.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        isEditing = true
                    }) {
                        Label("Edit Patient", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete Patient", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditPatientView(patient: patient, viewModel: viewModel)
        }
        .adaptiveSheet(isPresented: $isEditing) {
            EditPatientView(patient: patient, viewModel: viewModel)
        }
        .alert("Delete Patient", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePatient()
            }
        } message: {
            Text("Are you sure you want to delete this patient? This action cannot be undone.")
        }
        .alert("Delete Medication", isPresented: $showingDeleteMedicationAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let medication = medicationToDelete {
                    deleteMedication(medication)
                }
            }
        } message: {
            if let medication = medicationToDelete {
                Text("Are you sure you want to delete \(medication.name)? This action cannot be undone.")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PatientUpdated"))) { notification in
                    if let updatedPatientId = notification.userInfo?["patientId"] as? UUID,
                       updatedPatientId == patient.id {
                        Task {
                            await decryptPatientData()
                        }
                    }
                }
        .task {
            await decryptPatientData()
        }
    }
    
    private func deletePatient() {
        Task {
            do {
                try await viewModel.deletePatient(patient)
                presentationMode.wrappedValue.dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func deleteMedication(_ medication: Medication) {
            Task {
                do {
                    try await viewModel.deleteMedication(medication, from: patient)
                    // Immediately update the local state after successful deletion
                    await MainActor.run {
                        decryptedMedications.removeAll { $0.id == medication.id }
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
        
    private func decryptPatientData() async {
            do {
                // Get the most recent patient data from viewModel
                if let updatedPatient = viewModel.patients.first(where: { $0.id == patient.id }) {
                    await MainActor.run {
                        // Decrypt diagnosis notes
                        decryptedDiagnosisNotes = (try? EncryptionService.shared.decrypt(updatedPatient.diagnosisNotes)) ?? updatedPatient.diagnosisNotes
                        
                        // Decrypt medications
                        decryptedMedications = updatedPatient.medications.map { med in
                            Medication(
                                id: med.id,
                                name: med.name,
                                dosage: (try? EncryptionService.shared.decrypt(med.dosage)) ?? med.dosage,
                                frequency: med.frequency
                            )
                        }
                    }
                }
            } catch {
                print("Error decrypting patient data: \(error)")
            }
        }
        
        private func decryptMedications(_ medications: [Medication]) async throws -> [Medication] {
            return try medications.map { medication in
                Medication(
                    id: medication.id,
                    name: medication.name,
                    dosage: try EncryptionService.shared.decrypt(medication.dosage),
                    frequency: medication.frequency
                )
            }
        }
}
