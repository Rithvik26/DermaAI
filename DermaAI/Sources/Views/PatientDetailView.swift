import SwiftUI

struct PatientDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let patient: Patient
    let viewModel: PatientViewModel
    @State private var isEditing = false
    @State private var decryptedDiagnosisNotes: String = ""
    @State private var decryptedMedications: [Medication] = []
    
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
                        VStack(alignment: .leading) {
                            Text(medication.name)
                                .font(.headline)
                            Text("\(medication.dosage) - \(medication.frequency)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(patient.name)
        .toolbar {
            Button("Edit") {
                isEditing = true
            }
        }
        .sheet(isPresented: $isEditing) {
            EditPatientView(patient: patient, viewModel: viewModel)
        }
        .task {
            await decryptPatientData()
        }
    }
    
    private func decryptPatientData() async {
        do {
            // Decrypt diagnosis notes
            decryptedDiagnosisNotes = try EncryptionService.shared.decrypt(patient.diagnosisNotes)
            
            // Decrypt medications
            decryptedMedications = try await decryptMedications(patient.medications)
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
