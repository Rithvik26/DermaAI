import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel: PatientViewModel
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingAddPatient = false
    @State private var showingAnalyzer = false
    @State private var showingSettings = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var selectedPatients: Set<Patient.ID> = []
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    
    var userInitial: String {
        if let displayName = Auth.auth().currentUser?.displayName,
           !displayName.isEmpty {
            return String(displayName.prefix(1).uppercased())
        }
        if let email = Auth.auth().currentUser?.email,
           !email.isEmpty {
            return String(email.prefix(1).uppercased())
        }
        return "U"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                if viewModel.filteredPatients.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        if viewModel.searchText.isEmpty {
                            Text("No patients yet")
                                .font(.headline)
                            Text("Add your first patient to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No matching patients")
                                .font(.headline)
                            Text("Try adjusting your search")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    List(selection: $selectedPatients) {
                        ForEach(viewModel.filteredPatients) { patient in
                            NavigationLink(destination: PatientDetailView(patient: patient, viewModel: viewModel)) {
                                PatientRowView(patient: patient)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .navigationTitle("DermaAI")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        // User Profile Button
                        Button(action: { showingSettings = true }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Text(userInitial)
                                        .foregroundColor(.white)
                                        .font(.headline)
                                )
                                .shadow(radius: 2)
                        }
                        .disabled(isEditing)
                        
                        Button(action: { showingAnalyzer = true }) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 20))
                        }
                        .disabled(isEditing)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !viewModel.filteredPatients.isEmpty {
                            Button(action: {
                                isEditing.toggle()
                                if !isEditing {
                                    selectedPatients.removeAll()
                                }
                            }) {
                                Text(isEditing ? "Done" : "Select")
                            }
                        }
                        
                        if !isEditing {
                            Button(action: { showingAddPatient = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
                
                // Delete button appears when in edit mode and items are selected
                if isEditing && !selectedPatients.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive, action: {
                            showingDeleteConfirmation = true
                        }) {
                            Text("Delete Selected (\(selectedPatients.count))")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPatient) {
                AddPatientView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAnalyzer) {
                AnalyzerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                UserSettingsView()
            }
            .alert("Delete Patients", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedPatients()
                }
            } message: {
                Text("Are you sure you want to delete \(selectedPatients.count) patient\(selectedPatients.count == 1 ? "" : "s")? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func deleteSelectedPatients() {
        let patientsToDelete = viewModel.filteredPatients.filter { selectedPatients.contains($0.id) }
        
        Task {
            do {
                try await viewModel.batchDeletePatients(patientsToDelete)
                selectedPatients.removeAll()
                isEditing = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}


// Custom SearchBar View
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search patients...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
