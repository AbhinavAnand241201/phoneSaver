//
//  Contact.swift
//  phoneS
//
//  Created by ABHINAV ANAND  on 11/05/25.
//


import Foundation
import CryptoKit

struct Contact: Identifiable, Codable {
    let id: Int
    let name: String
    private let encryptedPhone: String
    var tags: [String]
    var lastInteraction: Date?
    var birthday: Date?
    var contactFrequency: String
    var preferredTime: String?
    var notes: String?
    var reminders: [Reminder]?
    
    // Computed property to decrypt phone number
    var phone: String {
        do {
            return try decryptPhone(encryptedPhone)
        } catch {
            print("Error decrypting phone: \(error)")
            return "Error: Could not decrypt phone number"
        }
    }
    
    // Coding keys for JSON encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case encryptedPhone = "encrypted_phone"
        case tags
        case lastInteraction = "last_interaction"
        case birthday
        case contactFrequency = "contact_frequency"
        case preferredTime = "preferred_time"
        case notes
        case reminders
    }
    
    // Initialize with encrypted phone
    init(id: Int, name: String, encryptedPhone: String, tags: [String] = [], lastInteraction: Date? = nil, birthday: Date? = nil, contactFrequency: String = "Weekly", preferredTime: String? = nil, notes: String? = nil, reminders: [Reminder]? = nil) {
        self.id = id
        self.name = name
        self.encryptedPhone = encryptedPhone
        self.tags = tags
        self.lastInteraction = lastInteraction
        self.birthday = birthday
        self.contactFrequency = contactFrequency
        self.preferredTime = preferredTime
        self.notes = notes
        self.reminders = reminders
    }
    
    // Initialize with plain phone (will be encrypted)
    init(id: Int, name: String, phone: String, tags: [String] = [], lastInteraction: Date? = nil, birthday: Date? = nil, contactFrequency: String = "Weekly", preferredTime: String? = nil, notes: String? = nil, reminders: [Reminder]? = nil) throws {
        self.id = id
        self.name = name
        self.encryptedPhone = try encryptPhone(phone)
        self.tags = tags
        self.lastInteraction = lastInteraction
        self.birthday = birthday
        self.contactFrequency = contactFrequency
        self.preferredTime = preferredTime
        self.notes = notes
        self.reminders = reminders
    }
}

// MARK: - Reminder Model
struct Reminder: Codable, Identifiable {
    let id: String
    let date: Date
    let message: String
    var isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case message
        case isCompleted = "is_completed"
    }
}

// MARK: - Encryption/Decryption
extension Contact {
    static func encryptPhone(_ phone: String) throws -> String {
        guard let key = KeychainManager.shared.getEncryptionKey() else {
            throw EncryptionError.keyNotFound
        }
        
        guard let phoneData = phone.data(using: .utf8) else {
            throw EncryptionError.encodingFailed
        }
        
        let sealedBox = try AES.GCM.seal(phoneData, using: key)
        return sealedBox.combined?.base64EncodedString() ?? ""
    }
    
    static func decryptPhone(_ encryptedPhone: String) throws -> String {
        guard let key = KeychainManager.shared.getEncryptionKey() else {
            throw EncryptionError.keyNotFound
        }
        
        guard let data = Data(base64Encoded: encryptedPhone),
              let sealedBox = try? AES.GCM.SealedBox(combined: data) else {
            throw EncryptionError.decryptionFailed
        }
        
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decodingFailed
        }
        
        return decryptedString
    }
}

// MARK: - Encryption Errors
enum EncryptionError: Error {
    case keyNotFound
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed
}

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    private let keychain = KeychainWrapper.standard
    private let encryptionKeyKey = "encryptionKey"
    
    private init() {}
    
    func getEncryptionKey() -> SymmetricKey? {
        if let keyData = keychain.data(forKey: encryptionKeyKey) {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new key if none exists
        let key = SymmetricKey(size: .bits256)
        keychain.set(key.withUnsafeBytes { Data($0) }, forKey: encryptionKeyKey)
        return key
    }
}