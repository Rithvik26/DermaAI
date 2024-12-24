import SwiftUI

struct AnalyzerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PatientViewModel
    @State private var isAnalyzing = false
    @State private var isTesting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingExportSuccess = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @StateObject private var networkReachability = NetworkReachability.shared
    
    var body: some View {
        Group {
            if isAnalyzing || isTesting {
                loadingView
            } else if !viewModel.hasLoadedAnalysis {
                ProgressView("Loading previous analysis...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.analysisResults.isEmpty {
                emptyStateView
            } else {
                resultsView
            }
        }
        .navigationTitle("Disease Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if !viewModel.analysisResults.isEmpty {
                        Button(action: exportData) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        
                        Button("New Analysis") {
                            withAnimation {
                                viewModel.analysisResults = []
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: AnalysisHelpView()) {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("Try Again", role: .none) {
                if !isTesting {
                    startAnalysis()
                } else {
                    testAPI()
                }
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("Share") {
                showingShareSheet = true
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Patient data has been exported to CSV file. You can share it using the Share button.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = exportedFileURL {
                ShareSheet(items: [fileURL])
            }
        }
        .overlay {
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
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            if isAnalyzing {
                Text("Analyzing \(viewModel.patients.count) patient diagnoses...")
                    .font(.headline)
                Text("This may take a moment")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Testing API Connection...")
                    .font(.headline)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Analyze \(viewModel.patients.count) Patients")
                .font(.title2)
            
            Text("Group patients by common conditions and get treatment recommendations")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: startAnalysis) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Start Batch Analysis")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(viewModel.patients.isEmpty || !networkReachability.isConnected)
                
                Button(action: testAPI) {
                    HStack {
                        Image(systemName: "network")
                        Text("Test API Connection")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .disabled(!networkReachability.isConnected)
            }
            .padding(.horizontal)
            
            if viewModel.patients.isEmpty {
                Text("Add patients to begin analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
        }
        .padding()
    }
    
    private var resultsView: some View {
        List {
            Text("\(viewModel.analysisResults.count) Disease Groups Found")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            
            ForEach(viewModel.analysisResults) { group in
                Section {
                    NavigationLink(
                        destination: DiseaseGroupDetailView(
                            diseaseGroup: group,
                            viewModel: viewModel
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Patients subsection
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Patients (\(group.patients.count))", systemImage: "person.2")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(group.patients, id: \.self) { patient in
                                    Text("• " + patient)
                                        .font(.system(.body, design: .rounded))
                                }
                            }
                            
                            Divider()
                            
                            // Medications subsection
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Recommended Medications", systemImage: "pills")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(group.recommendedMedications, id: \.self) { medication in
                                    Text("• " + medication)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text(group.disease)
                        .font(.headline)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func startAnalysis() {
        guard networkReachability.isConnected else {
            errorMessage = "You are currently offline. Please check your internet connection and try again."
            showError = true
            return
        }
        
        guard !viewModel.patients.isEmpty else {
            errorMessage = "No patients to analyze. Add some patients first."
            showError = true
            return
        }
        
        isAnalyzing = true
        
        // Suspend listener before analysis
        viewModel.suspendListener()
        
        Task {
            do {
                try await viewModel.analyzePatientsInBatch()
                await MainActor.run {
                    isAnalyzing = false
                    // Resume listener after analysis
                    viewModel.resumeListener()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                    showError = true
                    // Resume listener on error
                    viewModel.resumeListener()
                }
            }
        }
    }
    
    private func testAPI() {
        guard networkReachability.isConnected else {
            errorMessage = "You are currently offline. Please check your internet connection and try again."
            showError = true
            return
        }
        
        isTesting = true
        Task {
            do {
                let response = try await viewModel.testAPI()
                await MainActor.run {
                    isTesting = false
                    if response.contains("Test successful") {
                        errorMessage = "API test successful! You can now run the analysis."
                        showError = true
                    } else {
                        errorMessage = "API test failed: Unexpected response"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    errorMessage = "API test failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func exportData() {
        if let fileURL = viewModel.saveCSVToFile() {
            exportedFileURL = fileURL
            showingExportSuccess = true
        } else {
            errorMessage = "Failed to export data"
            showError = true
        }
    }
}

// Create a separate view for Analysis Help
struct AnalysisHelpView: View {
    var body: some View {
        List {
            Section(header: Text("About the Analysis")) {
                Text("The analyzer uses advanced AI to group patients based on their diagnostic notes and symptoms. It identifies common patterns and suggests appropriate treatments.")
            }
            
            Section(header: Text("How it Works")) {
                Text("1. Collects all patient diagnostic notes")
                Text("2. Analyzes symptoms and conditions")
                Text("3. Groups similar cases together")
                Text("4. Suggests common treatments")
            }
            
            Section(header: Text("Important Notes")) {
                Text("• All suggestions should be reviewed by a medical professional")
                Text("• This tool is for assistance only and does not replace clinical judgment")
                Text("• Results are based on provided diagnostic notes")
            }
            
            Section(header: Text("Export Features")) {
                Text("• Export patient data to CSV format")
                Text("• Includes diagnosis summaries and recommendations")
                Text("• Share via email or other apps")
                Text("• Data is encrypted for security")
            }
        }
        .navigationTitle("Analysis Help")
    }
}

#Preview {
    NavigationView {
        AnalyzerView(viewModel: PatientViewModel())
    }
}
