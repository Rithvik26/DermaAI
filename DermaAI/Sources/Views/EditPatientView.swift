import SwiftUICore
import SwiftUI
struct EditPatientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PatientViewModel
    let patient: Patient
    
    @State private var editedName: String
    @State private var editedDiagnosisNotes: String
    @State private var editedMedications: [Medication]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    init(patient: Patient, viewModel: PatientViewModel) {
        self.patient = patient
        self.viewModel = viewModel
        
        // Initialize state with decrypted values
        _editedName = State(initialValue: patient.name)
        _editedDiagnosisNotes = State(initialValue: (try? EncryptionService.shared.decrypt(patient.diagnosisNotes)) ?? patient.diagnosisNotes)
        
        // Decrypt medications
        let decryptedMeds = patient.medications.map { med in
            Medication(
                id: med.id,
                name: med.name,
                dosage: (try? EncryptionService.shared.decrypt(med.dosage)) ?? med.dosage,
                frequency: med.frequency
            )
        }
        _editedMedications = State(initialValue: decryptedMeds)
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Information")) {
                    TextField("Patient Name", text: $editedName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .disabled(isLoading)
                    
                    VStack(alignment: .leading) {
                        Text("Diagnosis Notes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $editedDiagnosisNotes)
                            .frame(height: 120)
                            .border(Color.gray.opacity(0.2))
                            .disabled(isLoading)
                    }
                }
                
                Section(header: Text("Medications")) {
                    ForEach(editedMedications.indices, id: \.self) { index in
                        VStack {
                            HStack {
                                TextField("Medication Name", text: Binding(
                                    get: { editedMedications[index].name },
                                    set: { editedMedications[index].name = $0 }
                                ))
                                .textContentType(.none)
                                .disabled(isLoading)
                                
                                Divider()
                                
                                TextField("Dosage", text: Binding(
                                    get: { editedMedications[index].dosage },
                                    set: { editedMedications[index].dosage = $0 }
                                ))
                                .textContentType(.none)
                                .frame(width: 100)
                                .disabled(isLoading)
                            }
                            
                            TextField("Frequency (e.g., twice daily)", text: Binding(
                                get: { editedMedications[index].frequency },
                                set: { editedMedications[index].frequency = $0 }
                            ))
                            .textContentType(.none)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .disabled(isLoading)
                        }
                    }
                    .onDelete { indexSet in
                        editedMedications.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        withAnimation {
                            editedMedications.append(Medication(name: "", dosage: "", frequency: ""))
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Medication")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Edit Patient")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveUpdatedPatient()
                    }
                    .disabled(editedName.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    
    private func saveUpdatedPatient() {
        guard !editedName.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a patient name"
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Create patient with unencrypted data - encryption happens in ViewModel
                let updatedPatient = Patient(
                    id: patient.id,
                    name: editedName.trimmingCharacters(in: .whitespaces),
                    diagnosisNotes: editedDiagnosisNotes.trimmingCharacters(in: .whitespaces),
                    medications: editedMedications.filter { !$0.name.isEmpty },
                    userId: AuthenticationService.shared.currentUser?.uid
                )
                
                try await viewModel.updatePatient(updatedPatient)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}
