//
//  ForgotPasswordViewModel.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/18/24.
//


import SwiftUI

class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var showingError = false
    @Published var showingSuccess = false
    @Published var errorMessage: String?
    
    private let authService = AuthenticationService.shared
    
    func resetPassword() {
        isLoading = true
        
        Task {
            do {
                try await authService.resetPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ForgotPasswordViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter your email address")) {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: { viewModel.resetPassword() }) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Reset Password")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Reset Password")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $viewModel.showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Password reset instructions have been sent to your email")
            }
        }
    }
}