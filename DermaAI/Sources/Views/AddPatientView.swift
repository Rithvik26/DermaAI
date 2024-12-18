import SwiftUI

struct AddPatientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PatientViewModel
    @StateObject private var networkReachability = NetworkReachability.shared
    @State private var name = ""
    @State private var diagnosisNotes = ""
    @State private var medications: [Medication] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("Patient Information")) {
                        TextField("Patient Name", text: $name)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .disabled(isLoading)
                        
                        VStack(alignment: .leading) {
                            Text("Diagnosis Notes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextEditor(text: $diagnosisNotes)
                                .frame(height: 120)
                                .border(Color.gray.opacity(0.2))
                                .disabled(isLoading)
                        }
                    }
                    
                    Section(header: Text("Medications")) {
                        ForEach(medications.indices, id: \.self) { index in
                            VStack {
                                HStack {
                                    TextField("Medication Name", text: Binding(
                                        get: { medications[index].name },
                                        set: { medications[index].name = $0 }
                                    ))
                                    .textContentType(.none)
                                    .disabled(isLoading)
                                    
                                    Divider()
                                    
                                    TextField("Dosage", text: Binding(
                                        get: { medications[index].dosage },
                                        set: { medications[index].dosage = $0 }
                                    ))
                                    .textContentType(.none)
                                    .frame(width: 100)
                                    .disabled(isLoading)
                                }
                                
                                TextField("Frequency (e.g., twice daily)", text: Binding(
                                    get: { medications[index].frequency },
                                    set: { medications[index].frequency = $0 }
                                ))
                                .textContentType(.none)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .disabled(isLoading)
                            }
                        }
                        .onDelete { indexSet in
                            medications.remove(atOffsets: indexSet)
                        }
                        
                        Button(action: {
                            withAnimation {
                                medications.append(Medication(name: "", dosage: "", frequency: ""))
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
                
                if !networkReachability.isConnected {
                    VStack {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("You are offline")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top)
                }
            }
            .navigationTitle("Add New Patient")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePatient()
                    }
                    .disabled(name.isEmpty || isLoading || !networkReachability.isConnected)
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
                Button("OK") {
                    if !alertMessage.contains("error") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .interactiveDismissDisabled(isLoading)
        }
    }
    
    private func savePatient() {
        guard networkReachability.isConnected else {
            alertMessage = "You are currently offline. Please check your internet connection and try again."
            showAlert = true
            return
        }
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a patient name"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Add a timeout
        let task = Task {
            do {
                let newPatient = Patient(
                    id: UUID(),
                    name: name.trimmingCharacters(in: .whitespaces),
                    diagnosisNotes: diagnosisNotes.trimmingCharacters(in: .whitespaces),
                    medications: medications.filter { !$0.name.isEmpty },
                    userId: AuthenticationService.shared.currentUser?.uid,
                    createdAt: Date()
                )
                
                try await viewModel.addPatient(newPatient)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to add patient: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
        
        // Add timeout
        Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds timeout
            if !task.isCancelled {
                task.cancel()
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Operation timed out. Please try again."
                    showAlert = true
                }
            }
        }
    }
}
