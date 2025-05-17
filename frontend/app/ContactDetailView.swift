import SwiftUI

struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ContactDetailViewModel()
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var animateContent = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Contact Avatar
                        ContactAvatar(name: contact.name, size: 120)
                            .padding(.top, 20)
                            .scaleEffect(animateContent ? 1 : 0.8)
                            .opacity(animateContent ? 1 : 0)
                        
                        // Contact Info
                        VStack(spacing: 20) {
                            InfoCard(title: "Phone",
                                   value: formatPhoneNumber(contact.phone),
                                   icon: "phone.fill")
                                .offset(y: animateContent ? 0 : 50)
                                .opacity(animateContent ? 1 : 0)
                            
                            if !contact.tags.isEmpty {
                                InfoCard(title: "Tags",
                                       value: contact.tags,
                                       icon: "tag.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                            }
                            
                            if let lastInteraction = contact.lastInteraction {
                                InfoCard(title: "Last Interaction",
                                       value: formatDate(lastInteraction),
                                       icon: "clock.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                            }
                            
                            if !contact.birthday.isEmpty {
                                InfoCard(title: "Birthday",
                                       value: formatBirthday(contact.birthday),
                                       icon: "gift.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                            }
                        }
                        .padding(.horizontal)
                        
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
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            ActionButton(title: "Call",
                                      icon: "phone.fill",
                                      color: Color(hex: "4361EE"),
                                      isLoading: viewModel.isCalling) {
                                viewModel.callContact(contact)
                            }
                            
                            ActionButton(title: "Message",
                                      icon: "message.fill",
                                      color: Color(hex: "4CC9F0"),
                                      isLoading: viewModel.isMessaging) {
                                viewModel.messageContact(contact)
                            }
                            
                            ActionButton(title: "Share Contact",
                                      icon: "square.and.arrow.up.fill",
                                      color: Color(hex: "7209B7"),
                                      isLoading: viewModel.isSharing) {
                                showShareSheet = true
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle(contact.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4361EE"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showEditSheet = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(hex: "4361EE"))
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditContactView(contact: contact)
            }
            .alert("Delete Contact", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteContact(contact)
                }
            } message: {
                Text("Are you sure you want to delete this contact? This action cannot be undone.")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [contact.name, contact.phone])
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateContent = true
                }
            }
        }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatBirthday(_ birthday: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: birthday) {
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
        return birthday
    }
}

// MARK: - Supporting Views
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "4361EE"))
                .frame(width: 40, height: 40)
                .background(Color(hex: "4361EE").opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "6C757D"))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "212529"))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

struct EditContactView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var tags: String
    @State private var birthday: Date
    @State private var showDatePicker = false
    @State private var animateFields = false
    
    init(contact: Contact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phone = State(initialValue: contact.phone)
        _tags = State(initialValue: contact.tags)
        _birthday = State(initialValue: Date(timeIntervalSince1970: 0)) // TODO: Parse birthday string
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
                            .padding(.top, 20)
                        
                        // Input Fields
                        VStack(spacing: 16) {
                            CustomTextField(text: $name,
                                         placeholder: "Name",
                                         systemImage: "person.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                            
                            CustomTextField(text: $phone,
                                         placeholder: "Phone Number",
                                         systemImage: "phone.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                                .keyboardType(.phonePad)
                            
                            CustomTextField(text: $tags,
                                         placeholder: "Tags (comma separated)",
                                         systemImage: "tag.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                            
                            // Birthday Picker
                            BirthdayPickerButton(date: birthday, showDatePicker: $showDatePicker)
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                        }
                        .padding(.horizontal)
                        
                        if showDatePicker {
                            DatePicker("Birthday",
                                     selection: $birthday,
                                     displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Save Button
                        SaveButton(title: "Save Changes",
                                 isDisabled: name.isEmpty || phone.isEmpty) {
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
        }
    }
    
    private func saveContact() {
        // TODO: Implement contact update
        dismiss()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ViewModel
class ContactDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCalling = false
    @Published var isMessaging = false
    @Published var isSharing = false
    
    func callContact(_ contact: Contact) {
        isCalling = true
        errorMessage = nil
        
        // TODO: Implement call functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isCalling = false
        }
    }
    
    func messageContact(_ contact: Contact) {
        isMessaging = true
        errorMessage = nil
        
        // TODO: Implement messaging functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isMessaging = false
        }
    }
    
    func deleteContact(_ contact: Contact) {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement delete functionality
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
        }
    }
}

// MARK: - Preview
struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ContactDetailView(contact: Contact(
            id: 1,
            name: "John Doe",
            phone: "1234567890",
            encryptedPhone: "",
            tags: "Work,Friend",
            lastInteraction: Date(),
            birthday: "1990-01-01"
        ))
    }
} 