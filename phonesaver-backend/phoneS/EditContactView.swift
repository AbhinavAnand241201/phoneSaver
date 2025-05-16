import SwiftUI

struct EditContactView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var phone: String
    @State private var contactFrequency: String
    @State private var preferredTime: String
    @State private var notes: String
    
    private let frequencyOptions = ["Daily", "Weekly", "Monthly", "Quarterly", "Yearly"]
    private let timeOptions = ["Morning", "Afternoon", "Evening", "Night"]
    
    init(contact: Contact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phone = State(initialValue: contact.phone)
        _contactFrequency = State(initialValue: contact.contactFrequency)
        _preferredTime = State(initialValue: contact.preferredTime ?? "")
        _notes = State(initialValue: contact.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Contact Preferences")) {
                    Picker("Contact Frequency", selection: $contactFrequency) {
                        ForEach(frequencyOptions, id: \.self) { frequency in
                            Text(frequency).tag(frequency)
                        }
                    }
                    
                    Picker("Preferred Time", selection: $preferredTime) {
                        Text("Not specified").tag("")
                        ForEach(timeOptions, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty || phone.isEmpty)
            )
        }
    }
    
    private func saveChanges() {
        // Update contact information
        authViewModel.updateContact(
            id: contact.id,
            name: name,
            phone: phone,
            contactFrequency: contactFrequency,
            preferredTime: preferredTime.isEmpty ? nil : preferredTime,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
}

struct EditContactView_Previews: PreviewProvider {
    static var previews: some View {
        EditContactView(contact: Contact(
            id: 1,
            name: "John Doe",
            encryptedPhone: "encrypted",
            contactFrequency: "Weekly",
            preferredTime: "Evenings",
            notes: "Prefers text messages"
        ))
        .environmentObject(AuthViewModel())
    }
} 