import SwiftUI
import GoogleSignInSwift
import UIKit

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    private var rootViewController: UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return scene.windows.first?.rootViewController
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.4, green: 0.8, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Logo and Title
                    VStack(spacing: 15) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        Text("DermaAI")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 50)
                    
                    // Social Sign In Buttons
                    VStack(spacing: 12) {
                        // Official Google Sign In Button
                        GoogleSignInButton(scheme: colorScheme == .dark ? .dark : .light, style: .wide, state: viewModel.isLoading ? .disabled : .normal) {
                            if let viewController = rootViewController {
                                Task {
                                    await viewModel.signInWithGoogle(presenting: viewController)
                                }
                            }
                        }
                        .frame(height: 50) // Increased from 44 to 50 to match your other buttons
                        
                        // Separator
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.white.opacity(0.3))
                            Text("or")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.footnote)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(.vertical)
                    }
                    .padding(.horizontal, 30)
                    
                    // Email Login Form
                    VStack(spacing: 20) {
                        CustomTextField(
                            text: $viewModel.email,
                            placeholder: "Email",
                            systemImage: "envelope"
                        )
                        
                        CustomTextField(
                            text: $viewModel.password,
                            placeholder: "Password",
                            systemImage: "lock",
                            isSecure: true
                        )
                        
                        // Forgot Password Button
                        Button("Forgot Password?") {
                            viewModel.showingForgotPassword = true
                        }
                        .font(.footnote)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        // Login Button
                        Button(action: { viewModel.login() }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else {
                                Text("Log In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .disabled(viewModel.isLoading)
                        
                        // Biometric Login
                        if viewModel.biometricType != .none {
                            Button(action: { viewModel.authenticateWithBiometrics() }) {
                                HStack {
                                    Image(systemName: viewModel.biometricType.iconName)
                                    Text("Sign in with \(viewModel.biometricType.description)")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Sign Up Section
                    VStack(spacing: 10) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Create Account") {
                            viewModel.showingSignUp = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                }
                .padding(.vertical, 30)
            }
        }
        .sheet(isPresented: $viewModel.showingSignUp) {
            SignUpView(viewModel: SignUpViewModel())
        }
        .sheet(isPresented: $viewModel.showingForgotPassword) {
            ForgotPasswordView(viewModel: ForgotPasswordViewModel())
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .disabled(viewModel.isLoading)
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(.emailAddress)
                    .keyboardType(placeholder.lowercased().contains("email") ? .emailAddress : .default)
            }
        }
        .autocapitalization(.none)
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .foregroundColor(.white)
    }
}

#Preview {
    LoginView()
}
