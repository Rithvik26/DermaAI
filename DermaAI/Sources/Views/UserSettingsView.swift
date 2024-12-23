//
//  UserSettingsView.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/19/24.
//


import SwiftUI
import FirebaseAuth

struct UserSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthenticationService.shared
    @State private var displayName = ""
    @State private var email = ""
    @State private var isEditingProfile = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var userInitial: String {
        String(displayName.prefix(1).uppercased())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    // Profile Image/Initial
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(userInitial)
                                    .foregroundColor(.white)
                                    .font(.title2.bold())
                            )
                        
                        VStack(alignment: .leading) {
                            Text(displayName)
                                .font(.headline)
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Account")) {
                    Button("Edit Profile") {
                        isEditingProfile = true
                    }
                    
                    Button("Sign Out", role: .destructive) {
                        Task {
                            do {
                                try authService.signOut()
                                dismiss()
                            } catch {
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                        }
                    }
                }
                
                Section(header: Text("App Information")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(displayName: $displayName)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if let user = Auth.auth().currentUser {
                    displayName = user.displayName ?? "User"
                    email = user.email ?? ""
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .iPadAdaptive()
    }
        
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var displayName: String
    @State private var newDisplayName: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Display Name", text: $newDisplayName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateProfile()
                    }
                    .disabled(newDisplayName.isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            newDisplayName = displayName
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func updateProfile() {
        isLoading = true
        
        Task {
            do {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = newDisplayName
                try await changeRequest?.commitChanges()
                
                await MainActor.run {
                    displayName = newDisplayName
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
}
