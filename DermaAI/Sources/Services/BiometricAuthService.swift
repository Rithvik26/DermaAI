//
//  BiometricAuthService.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/18/24.
//


import LocalAuthentication

class BiometricAuthService {
    static let shared = BiometricAuthService()
    
    enum BiometricType {
        case none
        case faceID
        case touchID
        
        var description: String {
            switch self {
            case .none: return "none"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            }
        }
        
        var iconName: String {
            switch self {
            case .none: return ""
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            }
        }
    }
    
    private init() {}
    
    var biometricType: BiometricType {
        let authContext = LAContext()
        var error: NSError?
        
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch authContext.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    func authenticate() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error ?? NSError(domain: "BiometricAuthService", code: -1)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "Log in to your account") { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}