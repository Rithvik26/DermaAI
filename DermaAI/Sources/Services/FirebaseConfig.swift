//
//  FirebaseConfig.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/18/24.
//

import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseAnalytics

class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {
        // Only configure once
        guard FirebaseApp.app() == nil else { return }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign In
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
}
