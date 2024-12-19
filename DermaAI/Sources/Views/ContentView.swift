import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PatientViewModel
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingAddPatient = false
    @State private var showingAnalyzer = false
    @State private var showingSignOutAlert = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                List {
                    ForEach(viewModel.filteredPatients) { patient in
                        NavigationLink(destination: PatientDetailView(patient: patient, viewModel: viewModel)) {
                            PatientRowView(patient: patient)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            do {
                                // Convert filtered indices to original array indices
                                let patientsToDelete = indexSet.map { viewModel.filteredPatients[$0] }
                                for patient in patientsToDelete {
                                    try await viewModel.deletePatient(patient)
                                }
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("DermaAI")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingAnalyzer = true }) {
                            Label("Analyze Patients", systemImage: "waveform.path.ecg")
                        }
                        
                        Button(action: {
                            showingSignOutAlert = true
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPatient = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPatient) {
                AddPatientView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAnalyzer) {
                AnalyzerView(viewModel: viewModel)
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        do {
                            try await authService.signOut()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
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
