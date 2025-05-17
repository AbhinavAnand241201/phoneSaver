import Foundation
import UserNotifications
import FirebaseFirestore
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var token: String?
    @Published var isLoading: Bool = false
    @Published var contacts: [Contact] = []
    @Published var user: User?
    @Published var errorViewModel = ErrorViewModel()
    
    private let db = Firestore.firestore()
    private let keychain = KeychainWrapper.standard
    private let sessionTimeout: TimeInterval = 24 * 60 * 60 // 24 hours
    
    enum AuthError: LocalizedError {
        case invalidCredentials
        case networkError
        case serverError
        case unauthorized
        case invalidResponse
        case notAuthenticated
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password"
            case .networkError:
                return "Network connection error"
            case .serverError:
                return "Server error occurred"
            case .unauthorized:
                return "Unauthorized access"
            case .invalidResponse:
                return "Invalid server response"
            case .notAuthenticated:
                return "Not authenticated"
            }
        }
    }
    
    init() {
        checkSession()
    }
    
    // MARK: - Session Management
    private func checkSession() {
        guard let token = keychain.string(forKey: "authToken"),
              let tokenData = keychain.data(forKey: "tokenData") else {
            isAuthenticated = false
            return
        }
        
        do {
            let tokenInfo = try JSONDecoder().decode(TokenInfo.self, from: tokenData)
            if Date().timeIntervalSince(tokenInfo.createdAt) > sessionTimeout {
                logout()
                return
            }
            
            isAuthenticated = true
            fetchUserProfile()
        } catch {
            logout()
        }
    }
    
    private func saveSession(token: String, tokenInfo: TokenInfo) {
        keychain.set(token, forKey: "authToken")
        if let tokenData = try? JSONEncoder().encode(tokenInfo) {
            keychain.set(tokenData, forKey: "tokenData")
        }
    }
    
    // MARK: - Authentication Methods
    func signup() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        guard !email.isEmpty, !password.isEmpty else {
            DispatchQueue.main.async {
                self.errorViewModel.handleError(AuthError.invalidCredentials)
                self.isLoading = false
            }
            return
        }
        
        let url = URL(string: "http://localhost:8080/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorViewModel.handleError(AuthError.networkError)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorViewModel.handleError(AuthError.invalidResponse)
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let token = json["token"] as? String {
                        self.saveSession(token: token)
                        self.isAuthenticated = true
                        self.email = ""
                        self.password = ""
                    } else {
                        self.errorViewModel.handleError(AuthError.invalidResponse)
                    }
                case 400:
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorViewModel.handleError(AuthError.invalidCredentials)
                    }
                default:
                    self.errorViewModel.handleError(AuthError.serverError)
                }
            }
        }.resume()
    }
    
    func login() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        let url = URL(string: "http://localhost:8080/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let token = json["token"] as? String {
                        self.token = token
                        self.isAuthenticated = true
                        self.errorMessage = nil
                        self.email = ""
                        self.password = ""
                        self.fetchContacts { _ in }
                    } else {
                        self.errorMessage = "Invalid response format"
                    }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorMessage = "Login failed: \(errorMessage)"
                    } else {
                        self.errorMessage = "Login failed: Server error"
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Contact Management
    func addContact(name: String, phone: String, tags: [String] = [], birthday: Date? = nil, contactFrequency: String = "Weekly", preferredTime: String? = nil, notes: String? = nil) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        do {
            let encryptedPhone = try Contact.encryptPhone(phone)
        
        let url = URL(string: "http://localhost:8080/contacts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
            let body: [String: Any] = [
                "name": name,
                "encrypted_phone": encryptedPhone,
                "tags": tags,
                "birthday": birthday?.timeIntervalSince1970,
                "contact_frequency": contactFrequency,
                "preferred_time": preferredTime as Any,
                "notes": notes as Any
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to add contact: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.errorMessage = "Invalid server response"
                        return
                    }
                    
                    if httpResponse.statusCode == 200 {
                        self.fetchContacts { _ in }
                    } else {
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let errorMessage = json["error"] as? String {
                            self.errorMessage = "Failed to add contact: \(errorMessage)"
                        } else {
                            self.errorMessage = "Failed to add contact: Server error"
                        }
                    }
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encrypt phone number: \(error.localizedDescription)"
            }
        }
    }
    
    func updateTags(for contactId: Int, tags: [String]) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        let url = URL(string: "http://localhost:8080/contacts/\(contactId)/tags")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["tags": tags]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to update tags: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.fetchContacts { _ in }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorMessage = "Failed to update tags: \(errorMessage)"
                    } else {
                        self.errorMessage = "Failed to update tags: Server error"
                    }
                }
            }
        }.resume()
    }
    
    func updateLastInteraction(for contactId: Int) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        let url = URL(string: "http://localhost:8080/contacts/\(contactId)/last-interaction")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["timestamp": Date().timeIntervalSince1970]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to update last interaction: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.fetchContacts { _ in }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorMessage = "Failed to update last interaction: \(errorMessage)"
                    } else {
                        self.errorMessage = "Failed to update last interaction: Server error"
                    }
                }
            }
        }.resume()
    }
    
    func setReminder(for contact: Contact, date: Date, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Follow-up with \(contact.name)"
        content.body = message
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: "contact-\(contact.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func backupContacts() {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        // First, backup to Firebase
        FirebaseService.shared.backupContacts(contacts) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Then, notify the backend about the backup
                    let url = URL(string: "http://localhost:8080/backup")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                        guard let self = self else { return }
                        
                        DispatchQueue.main.async {
                            if let error = error {
                                self.errorMessage = "Failed to backup contacts: \(error.localizedDescription)"
                                return
                            }
                            
                            guard let httpResponse = response as? HTTPURLResponse else {
                                self.errorMessage = "Invalid server response"
                                return
                            }
                            
                            if httpResponse.statusCode == 200 {
                                self.errorMessage = "Contacts backed up successfully"
                            } else {
                                if let data = data,
                                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                                   let errorMessage = json["error"] as? String {
                                    self.errorMessage = "Failed to backup contacts: \(errorMessage)"
                                } else {
                                    self.errorMessage = "Failed to backup contacts: Server error"
                                }
                            }
                        }
                    }.resume()
                    
                case .failure(let error):
                    self.errorMessage = "Failed to backup contacts to Firebase: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func restoreContacts() {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        FirebaseService.shared.restoreContacts { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let restoredContacts):
                    // Update local contacts
                    self.contacts = restoredContacts
                    self.errorMessage = "Contacts restored successfully"
                    
                case .failure(let error):
                    self.errorMessage = "Failed to restore contacts: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchContacts(completion: @escaping ([Contact]) -> Void) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            completion([])
            return
        }
        
        let url = URL(string: "http://localhost:8080/contacts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            var contacts: [Contact] = []
            
            defer {
                DispatchQueue.main.async {
                    self.contacts = contacts
                    completion(contacts)
                }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch contacts: \(error.localizedDescription)"
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid server response"
                }
                return
            }
            
            if httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    self.logout()
                    self.errorMessage = "Session expired. Please log in again."
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorMessage = "Failed to fetch contacts: \(errorMessage)"
                    } else {
                        self.errorMessage = "Failed to fetch contacts: Server error"
                    }
                }
                return
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                contacts = json.compactMap { dict in
                    guard let id = dict["id"] as? Int,
                          let name = dict["name"] as? String,
                          let encryptedPhone = dict["encrypted_phone"] as? String else {
                        return nil
                    }
                    
                    let tags = dict["tags"] as? [String] ?? []
                    let lastInteraction = (dict["last_interaction"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
                    let birthday = (dict["birthday"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
                    
                    return Contact(id: id,
                                 name: name,
                                 encryptedPhone: encryptedPhone,
                                 tags: tags,
                                 lastInteraction: lastInteraction,
                                 birthday: birthday)
                }
            }
        }.resume()
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.token = nil
            self.isAuthenticated = false
            self.errorMessage = nil
            self.contacts = []
        }
    }
    
    func updateReminders(for contactId: Int, reminders: [Reminder]) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        let url = URL(string: "http://localhost:8080/contacts/\(contactId)/reminders")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let remindersData = try encoder.encode(reminders)
            request.httpBody = remindersData
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to update reminders: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.errorMessage = "Invalid server response"
                        return
                    }
                    
                    if httpResponse.statusCode == 200 {
                        self.fetchContacts { _ in }
                    } else {
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let errorMessage = json["error"] as? String {
                            self.errorMessage = "Failed to update reminders: \(errorMessage)"
                        } else {
                            self.errorMessage = "Failed to update reminders: Server error"
                        }
                    }
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encode reminders: \(error.localizedDescription)"
            }
        }
    }
    
    func updateContactFrequency(for contactId: Int, frequency: String) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        let url = URL(string: "http://localhost:8080/contacts/\(contactId)/frequency")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["frequency": frequency]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to update contact frequency: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.fetchContacts { _ in }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorMessage = "Failed to update contact frequency: \(errorMessage)"
                    } else {
                        self.errorMessage = "Failed to update contact frequency: Server error"
                    }
                }
            }
        }.resume()
    }
    
    func updatePreferredTime(for contactId: Int, preferredTime: String) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        let url = URL(string: "http://localhost:8080/contacts/\(contactId)/preferred-time")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["preferred_time": preferredTime]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to update preferred time: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.fetchContacts { _ in }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorMessage = "Failed to update preferred time: \(errorMessage)"
                    } else {
                        self.errorMessage = "Failed to update preferred time: Server error"
                    }
                }
            }
        }.resume()
    }
    
    func updateNotes(for contactId: Int, notes: String) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        let url = URL(string: "http://localhost:8080/contacts/\(contactId)/notes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["notes": notes]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to update notes: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.fetchContacts { _ in }
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        self.errorMessage = "Failed to update notes: \(errorMessage)"
                    } else {
                        self.errorMessage = "Failed to update notes: Server error"
                    }
                }
            }
        }.resume()
    }
    
    func updateContact(id: Int, name: String, phone: String, contactFrequency: String, preferredTime: String?, notes: String?) {
        guard let token = token else {
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
            }
            return
        }
        
        do {
            let encryptedPhone = try Contact.encryptPhone(phone)
            
            let url = URL(string: "http://localhost:8080/contacts/\(id)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "name": name,
                "encrypted_phone": encryptedPhone,
                "contact_frequency": contactFrequency,
                "preferred_time": preferredTime as Any,
                "notes": notes as Any
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Failed to update contact: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.errorMessage = "Invalid server response"
                        return
                    }
                    
                    if httpResponse.statusCode == 200 {
                        self.fetchContacts { _ in }
                    } else {
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let errorMessage = json["error"] as? String {
                            self.errorMessage = "Failed to update contact: \(errorMessage)"
                        } else {
                            self.errorMessage = "Failed to update contact: Server error"
                        }
                    }
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to encrypt phone number: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - User Profile
    func fetchUserProfile() {
        guard isAuthenticated else { return }
        
        // TODO: Implement API call to fetch user profile
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Simulate successful profile fetch
            self.user = User(id: 1, name: "John Doe", email: "john@example.com")
        }
    }
    
    func updateProfile(name: String, email: String) {
        guard isAuthenticated else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Validate input
        guard !name.isEmpty, !email.isEmpty else {
            errorMessage = "Please fill in all fields"
            isLoading = false
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        // TODO: Implement API call to update profile
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Simulate successful profile update
            self.user = User(id: self.user?.id ?? 1, name: name, email: email)
            self.isLoading = false
        }
    }
    
    // MARK: - Validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
}

// MARK: - Models
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

struct TokenInfo: Codable {
    let token: String
    let createdAt: Date
}
