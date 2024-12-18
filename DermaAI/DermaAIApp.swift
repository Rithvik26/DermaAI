//
//  DermaAIApp.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/14/24.
//
import SwiftUI
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
@main
struct DermaAIApp: App {
    @StateObject private var patientViewModel = PatientViewModel()
    @StateObject private var authManager = AuthenticationService.shared
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign In
        if let clientID = FirebaseApp.app()?.options.clientID {
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
        }
        
        // Trigger re-encryption when user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                await EncryptionService.shared.reEncryptData()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.currentUser != nil {
                ContentView(viewModel: patientViewModel)
                    .task {
                        // Re-encrypt data when user logs in
                        await EncryptionService.shared.reEncryptData()
                    }
            } else {
                LoginView()
                    .environmentObject(patientViewModel)
            }
        }
    }
}
