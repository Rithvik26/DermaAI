import Foundation
import FirebaseAuth
import CryptoKit
import Security
import FirebaseFirestore

class EncryptionService {
    static let shared = EncryptionService()
    private var key: SymmetricKey
    private let keychainKey = "encryption_key"
    
    private init() {
        // Initialize with a new key
        self.key = SymmetricKey(size: .bits256)
        if let existingKey = Self.loadKeyFromKeychain() {
            print("🔐 Using existing encryption key from keychain")
            self.key = existingKey
        } else {
            print("🔑 Creating and storing new encryption key")
            Self.saveKeyToKeychain(self.key)
        }
    }
    
    func reEncryptData() async {
        print("🔄 Starting re-encryption process")
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user for re-encryption")
            return
        }
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("patients")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            print("📄 Found \(snapshot.documents.count) documents to re-encrypt")
            
            for document in snapshot.documents {
                var data = document.data()
                let patientId = document.documentID
                print("🔄 Re-encrypting patient: \(patientId)")
                
                // Re-encrypt diagnosis notes
                if let diagnosisNotes = data["diagnosisNotes"] as? String {
                    // First try to decrypt with current key
                    let plaintext = try decrypt(diagnosisNotes)
                    // Re-encrypt with current key
                    data["diagnosisNotes"] = try encrypt(plaintext)
                }
                
                // Re-encrypt medications
                if var medications = data["medications"] as? [[String: Any]] {
                    for i in 0..<medications.count {
                        if let dosage = medications[i]["dosage"] as? String {
                            let plaintext = try decrypt(dosage)
                            medications[i]["dosage"] = try encrypt(plaintext)
                        }
                    }
                    data["medications"] = medications
                }
                
                try await document.reference.setData(data, merge: true)
                print("✅ Successfully re-encrypted patient: \(patientId)")
            }
            
            print("✅ Re-encryption completed")
        } catch {
            print("❌ Re-encryption failed: \(error.localizedDescription)")
        }
    }
    
    func encrypt(_ string: String) throws -> String {
        guard !string.isEmpty else { return string }
        
        // Check if string is already encrypted
        if isBase64Encoded(string) {
            print("🔒 String appears to be already encrypted, skipping encryption")
            return string
        }
        
        do {
            print("🔒 Encrypting string of length: \(string.count)")
            let data = string.data(using: .utf8)!
            let nonce = try AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            let encrypted = combined.base64EncodedString()
            print("✅ Encryption successful")
            return encrypted
        } catch {
            print("⚠️ Encryption error: \(error)")
            return string
        }
    }
    
    func decrypt(_ encrypted: String) throws -> String {
        guard !encrypted.isEmpty else { return encrypted }
        
        // Check if string is actually encrypted
        if !isBase64Encoded(encrypted) {
            print("🔓 String is not encrypted, returning as is")
            return encrypted
        }
        
        do {
            print("🔓 Decrypting string of length: \(encrypted.count)")
            let data = Data(base64Encoded: encrypted)!
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw EncryptionError.decryptionFailed
            }
            print("✅ Decryption successful")
            return decryptedString
        } catch {
            print("⚠️ Decryption failed: \(error)")
            // If decryption fails, assume the string is not encrypted
            return encrypted
        }
    }
    
    private func isBase64Encoded(_ string: String) -> Bool {
        if let data = Data(base64Encoded: string) {
            return data.count > 0
        }
        return false
    }
    
    private static func loadKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "encryption_key",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }
        return nil
    }
    
    private static func saveKeyToKeychain(_ key: SymmetricKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "encryption_key",
            kSecValueData as String: key.withUnsafeBytes { Data($0) }
        ]
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "encryption_key"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Save new key
        let status = SecItemAdd(query as CFDictionary, nil)
        print("🔑 Key save status: \(status)")
    }
    
    enum EncryptionError: Error {
        case encryptionFailed
        case decryptionFailed
        case invalidData
    }
}
