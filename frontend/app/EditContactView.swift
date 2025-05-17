import SwiftUI

struct EditContactView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditContactViewModel()
    @State private var name: String
    @State private var phone: String
    @State private var tags: String
    @State private var birthday: Date
    @State private var showDatePicker = false
    @State private var animateFields = false
    @State private var isKeyboardVisible = false
    
    private let frequencyOptions = ["Daily", "Weekly", "Monthly", "Quarterly", "Yearly"]
    private let timeOptions = ["Morning", "Afternoon", "Evening", "Night"]
    
    init(contact: Contact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phone = State(initialValue: contact.phone)
        _tags = State(initialValue: contact.tags)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: contact.birthday) ?? Date()
        _birthday = State(initialValue: date)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Contact Avatar
                        ContactAvatar(name: name, size: 100)
                            .padding(.top, isKeyboardVisible ? 10 : 20)
                        
                        // Input Fields
                        VStack(spacing: 16) {
                            CustomTextField(text: $name,
                                         placeholder: "Name",
                                         systemImage: "person.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                                .textContentType(.name)
                            
                            CustomTextField(text: $phone,
                                         placeholder: "Phone Number",
                                         systemImage: "phone.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .onChange(of: phone) { newValue in
                                    phone = formatPhoneNumber(newValue)
                                }
                            
                            CustomTextField(text: $tags,
                                         placeholder: "Tags (comma separated)",
                                         systemImage: "tag.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                                .textContentType(.none)
                                .autocapitalization(.none)
                            
                            // Birthday Picker
                            BirthdayPickerButton(date: birthday, showDatePicker: $showDatePicker)
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                        }
                        .padding(.horizontal)
                        
                        if showDatePicker {
                            DatePicker("Birthday",
                                     selection: $birthday,
                                     in: ...Date(),
                                     displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(Color(hex: "DC3545"))
                                .font(.system(size: 14, weight: .medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color(hex: "DC3545").opacity(0.1))
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Save Button
                        SaveButton(title: "Save Changes",
                                 isDisabled: !isValidInput || viewModel.isLoading) {
                            saveContact()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4361EE"))
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateFields = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation {
                    isKeyboardVisible = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation {
                    isKeyboardVisible = false
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phone.count >= 10
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        if digits.count <= 3 {
            return digits
        } else if digits.count <= 6 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3))"
        } else {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.dropFirst(6))"
        }
    }
    
    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTags = tags.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthdayString = formatter.string(from: birthday)
        
        viewModel.updateContact(contact,
                              name: trimmedName,
                              phone: trimmedPhone,
                              tags: trimmedTags,
                              birthday: birthdayString)
    }
}

// MARK: - ViewModel
class EditContactViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func updateContact(_ contact: Contact, name: String, phone: String, tags: String, birthday: String) {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement API call to update contact
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            // Simulate success
        }
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