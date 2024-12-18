//
//  LoginViewModel.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/18/24.
//


import SwiftUI
import AuthenticationServices
import KeychainSwift

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var showingError = false
    @Published var showingSignUp = false
    @Published var showingForgotPassword = false
    @Published var errorMessage: String?
    @Published var showGoogleSignIn = false

    
    private let authService = AuthenticationService.shared
    private let biometricService = BiometricAuthService.shared
    private let keychain = KeychainSwift()
    
    var biometricType: BiometricAuthService.BiometricType {
        biometricService.biometricType
    }
    
    func login() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showingError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                // Save credentials for biometric login
                saveCredentials()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isLoading = false
        }
    }
    
    func authenticateWithBiometrics() {
        Task {
            do {
                try await biometricService.authenticate()
                // Retrieve saved credentials
                if let savedEmail = keychain.get("userEmail"),
                   let savedPassword = keychain.get("userPassword") {
                    email = savedEmail
                    password = savedPassword
                    await login()
                } else {
                    errorMessage = "No saved credentials found"
                    showingError = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
   
    private func saveCredentials() {
        keychain.set(email, forKey: "userEmail")
        keychain.set(password, forKey: "userPassword")
    }
        
        func signInWithGoogle(presenting: UIViewController) {
            Task {
                do {
                    isLoading = true
                    try await authService.signInWithGoogle(presenting: presenting)
                    isLoading = false
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
                        isLoading = false
                    }
                }
            }
        }
        
        func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
            Task {
                do {
                    isLoading = true
                    switch result {
                    case .success(let authorization):
                        try await authService.handleAppleSignIn(authorization: authorization)
                    case .failure(let error):
                        throw error
                    }
                    isLoading = false
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
