import SwiftUI

struct AddContactView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var phone = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var birthday: Date?
    @State private var contactFrequency = "Weekly"
    @State private var preferredTime = ""
    @State private var notes = ""
    
    private let frequencyOptions = ["Daily", "Weekly", "Monthly", "Quarterly", "Yearly"]
    private let timeOptions = ["Morning", "Afternoon", "Evening", "Night"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Tags")) {
                    HStack {
                        TextField("New tag", text: $newTag)
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    TagChip(tag: tag) {
                                        removeTag(tag)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Birthday")) {
                    DatePicker("Birthday", selection: Binding(
                        get: { birthday ?? Date() },
                        set: { birthday = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
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
            .navigationTitle("Add Contact")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveContact()
                }
                .disabled(name.isEmpty || phone.isEmpty)
            )
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveContact() {
        authViewModel.addContact(
            name: name,
            phone: phone,
            tags: tags,
            birthday: birthday,
            contactFrequency: contactFrequency,
            preferredTime: preferredTime.isEmpty ? nil : preferredTime,
            notes: notes.isEmpty ? nil : notes
        )
        dismiss()
    }
}

struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView()
            .environmentObject(AuthViewModel())
    }
}
