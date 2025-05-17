import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func backupContacts(_ contacts: [Contact], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let contactsRef = db.collection("users").document(userId).collection("contacts")
        
        // Convert contacts to dictionary format
        let contactsData = contacts.map { contact -> [String: Any] in
            var data: [String: Any] = [
                "id": contact.id,
                "name": contact.name,
                "encrypted_phone": contact.encryptedPhone,
                "tags": contact.tags,
                "contact_frequency": contact.contactFrequency
            ]
            
            if let lastInteraction = contact.lastInteraction {
                data["last_interaction"] = Timestamp(date: lastInteraction)
            }
            
            if let birthday = contact.birthday {
                data["birthday"] = Timestamp(date: birthday)
            }
            
            if let preferredTime = contact.preferredTime {
                data["preferred_time"] = preferredTime
            }
            
            if let notes = contact.notes {
                data["notes"] = notes
            }
            
            if let reminders = contact.reminders {
                data["reminders"] = reminders.map { reminder -> [String: Any] in
                    [
                        "id": reminder.id,
                        "date": Timestamp(date: reminder.date),
                        "message": reminder.message,
                        "is_completed": reminder.isCompleted
                    ]
                }
            }
            
            return data
        }
        
        // Create a batch write
        let batch = db.batch()
        
        // Delete existing contacts
        contactsRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Delete existing documents
            snapshot?.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            
            // Add new contacts
            contactsData.forEach { contactData in
                let docRef = contactsRef.document("\(contactData["id"] as! Int)")
                batch.setData(contactData, forDocument: docRef)
            }
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func restoreContacts(completion: @escaping (Result<[Contact], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("users").document(userId).collection("contacts").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let contacts = documents.compactMap { document -> Contact? in
                let data = document.data()
                
                guard let id = data["id"] as? Int,
                      let name = data["name"] as? String,
                      let encryptedPhone = data["encrypted_phone"] as? String else {
                    return nil
                }
                
                let tags = data["tags"] as? [String] ?? []
                let contactFrequency = data["contact_frequency"] as? String ?? "Weekly"
                
                let lastInteraction = (data["last_interaction"] as? Timestamp)?.dateValue()
                let birthday = (data["birthday"] as? Timestamp)?.dateValue()
                let preferredTime = data["preferred_time"] as? String
                let notes = data["notes"] as? String
                
                let reminders = (data["reminders"] as? [[String: Any]])?.compactMap { reminderData -> Reminder? in
                    guard let id = reminderData["id"] as? String,
                          let date = (reminderData["date"] as? Timestamp)?.dateValue(),
                          let message = reminderData["message"] as? String else {
                        return nil
                    }
                    
                    let isCompleted = reminderData["is_completed"] as? Bool ?? false
                    
                    return Reminder(id: id, date: date, message: message, isCompleted: isCompleted)
                }
                
                return Contact(
                    id: id,
                    name: name,
                    encryptedPhone: encryptedPhone,
                    tags: tags,
                    lastInteraction: lastInteraction,
                    birthday: birthday,
                    contactFrequency: contactFrequency,
                    preferredTime: preferredTime,
                    notes: notes,
                    reminders: reminders
                )
            }
            
            completion(.success(contacts))
        }
    }
} 