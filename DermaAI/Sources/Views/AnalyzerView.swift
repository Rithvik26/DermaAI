import SwiftUI

struct AnalyzerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PatientViewModel
    @State private var isAnalyzing = false
    @State private var isTesting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingHelp = false
    
    var body: some View {
        NavigationView {
            Group {
                if isAnalyzing || isTesting {
                    loadingView
                } else if viewModel.analysisResults.isEmpty {
                    emptyStateView
                } else {
                    resultsView
                }
            }
            .navigationTitle("Disease Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.analysisResults.isEmpty {
                        Button("New Analysis") {
                            withAnimation {
                                viewModel.analysisResults = []
                            }
                            
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingHelp = true
                    } label: {
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
            .sheet(isPresented: $showingHelp) {
                helpView
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
                .disabled(viewModel.patients.isEmpty)
                
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
            ForEach(viewModel.analysisResults) { group in
                Section {
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
                } header: {
                    Text(group.disease)
                        .font(.headline)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var helpView: some View {
        NavigationView {
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
            }
            .navigationTitle("Analysis Help")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingHelp = false
                    }
                }
            }
        }
    }
    
    private func startAnalysis() {
        guard !viewModel.patients.isEmpty else {
            errorMessage = "No patients to analyze. Add some patients first."
            showError = true
            return
        }
        
        isAnalyzing = true
        Task {
            do {
                try await viewModel.analyzePatientsInBatch()
                await MainActor.run {
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "Analysis failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func testAPI() {
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
}

#Preview {
    AnalyzerView(viewModel: PatientViewModel())
}
