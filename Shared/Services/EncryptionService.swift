import Foundation
import CryptoKit

class EncryptionService {
    static let shared = EncryptionService()
    
    private let keychain = KeychainService.shared
    private let keychainKey = "backup_encryption_key"
    
    private var encryptionKey: SymmetricKey? {
        get {
            if let keyData = keychain.getData(for: keychainKey) {
                return SymmetricKey(data: keyData)
            }
            return generateAndStoreNewKey()
        }
    }
    
    private init() {}
    
    func encrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.noKeyAvailable
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.noKeyAvailable
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func generateAndStoreNewKey() -> SymmetricKey? {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        do {
            try keychain.save(keyData, for: keychainKey)
            return key
        } catch {
            print("Failed to store encryption key: \(error)")
            return nil
        }
    }
    
    enum EncryptionError: Error {
        case noKeyAvailable
    }
} 