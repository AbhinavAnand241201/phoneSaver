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
    private(set) var encryptedPhone: String
    let tags: String
    let lastInteraction: Date?
    let birthday: String
    var contactFrequency: String
    var preferredTime: String?
    var notes: String?
    var reminders: [Reminder]?
    
    // Private computed property for decrypted phone
    private var decryptedPhone: String {
        do {
            return try decryptPhone(encryptedPhone)
        } catch {
            print("Error decrypting phone: \(error)")
            return ""
        }
    }
    
    // Public computed property with validation
    var phone: String {
        let phone = decryptedPhone
        return isValidPhoneNumber(phone) ? phone : "Invalid phone number"
    }
    
    // Coding keys for JSON encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case encryptedPhone
        case tags
        case lastInteraction
        case birthday
        case contactFrequency = "contact_frequency"
        case preferredTime = "preferred_time"
        case notes
        case reminders
    }
    
    // Initialize with encrypted phone
    init(id: Int, name: String, encryptedPhone: String, tags: String, lastInteraction: Date?, birthday: String, contactFrequency: String = "Weekly", preferredTime: String? = nil, notes: String? = nil, reminders: [Reminder]? = nil) {
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
    init(id: Int, name: String, phone: String, tags: String, lastInteraction: Date?, birthday: String) throws {
        guard isValidPhoneNumber(phone) else {
            throw ValidationError.invalidPhoneNumber
        }
        
        guard isValidBirthday(birthday) else {
            throw ValidationError.invalidBirthday
        }
        
        self.id = id
        self.name = name
        self.encryptedPhone = try encryptPhone(phone)
        self.tags = tags
        self.lastInteraction = lastInteraction
        self.birthday = birthday
        self.contactFrequency = "Weekly"
        self.preferredTime = nil
        self.notes = nil
        self.reminders = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        encryptedPhone = try container.decode(String.self, forKey: .encryptedPhone)
        tags = try container.decode(String.self, forKey: .tags)
        
        if let lastInteractionString = try container.decodeIfPresent(String.self, forKey: .lastInteraction) {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: lastInteractionString) {
                lastInteraction = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .lastInteraction,
                                                      in: container,
                                                      debugDescription: "Date string does not match format")
            }
        } else {
            lastInteraction = nil
        }
        
        birthday = try container.decode(String.self, forKey: .birthday)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(encryptedPhone, forKey: .encryptedPhone)
        try container.encode(tags, forKey: .tags)
        
        if let lastInteraction = lastInteraction {
            let formatter = ISO8601DateFormatter()
            let dateString = formatter.string(from: lastInteraction)
            try container.encode(dateString, forKey: .lastInteraction)
        }
        
        try container.encode(birthday, forKey: .birthday)
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
    // Public encryption methods
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
    
    // Public encryption methods with validation
    func encrypt(_ phone: String) throws -> String {
        guard isValidPhoneNumber(phone) else {
            throw ValidationError.invalidPhoneNumber
        }
        return try Contact.encryptPhone(phone)
    }
    
    func decrypt(_ encryptedPhone: String) throws -> String {
        let decrypted = try Contact.decryptPhone(encryptedPhone)
        guard isValidPhoneNumber(decrypted) else {
            throw ValidationError.invalidPhoneNumber
        }
        return decrypted
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

// MARK: - Validation
extension Contact {
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidPhoneNumber(phone) &&
        isValidBirthday(birthday)
    }
    
    static func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: phone)
    }
    
    static func isValidBirthday(_ birthday: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: birthday) != nil
    }
}

// MARK: - Formatting
extension Contact {
    var formattedPhoneNumber: String {
        let digits = phone.filter { $0.isNumber }
        if digits.count <= 3 {
            return digits
        } else if digits.count <= 6 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3))"
        } else {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.dropFirst(6))"
        }
    }
    
    var formattedBirthday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: birthday) {
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
        return birthday
    }
    
    var formattedLastInteraction: String? {
        guard let lastInteraction = lastInteraction else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastInteraction, relativeTo: Date())
    }
    
    var tagArray: [String] {
        tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Encryption
extension Contact {
    func encryptPhone() throws -> String {
        // TODO: Implement proper encryption
        return phone
    }
    
    func decryptPhone() throws -> String {
        // TODO: Implement proper decryption
        return phone
    }
}

// MARK: - Equatable
extension Contact: Equatable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Contact: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}