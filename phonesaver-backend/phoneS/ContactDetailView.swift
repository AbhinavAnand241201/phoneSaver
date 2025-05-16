import SwiftUI

struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var animateContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Contact Avatar
                        ZStack {
                            Circle()
                                .fill(Color(hex: "4361EE").opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Text(String(contact.name.prefix(1)))
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(Color(hex: "4361EE"))
                        }
                        .padding(.top, 20)
                        .scaleEffect(animateContent ? 1 : 0.8)
                        .opacity(animateContent ? 1 : 0)
                        
                        // Contact Info
                        VStack(spacing: 20) {
                            InfoCard(title: "Phone", value: contact.phone, icon: "phone.fill")
                                .offset(y: animateContent ? 0 : 50)
                                .opacity(animateContent ? 1 : 0)
                            
                            if !contact.tags.isEmpty {
                                InfoCard(title: "Tags", value: contact.tags, icon: "tag.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                            }
                            
                            if let lastInteraction = contact.lastInteraction {
                                InfoCard(title: "Last Interaction",
                                       value: lastInteraction.formatted(.relative),
                                       icon: "clock.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                            }
                            
                            if !contact.birthday.isEmpty {
                                InfoCard(title: "Birthday",
                                       value: contact.birthday,
                                       icon: "gift.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            ActionButton(title: "Call",
                                      icon: "phone.fill",
                                      color: Color(hex: "4361EE")) {
                                // TODO: Implement call action
                            }
                            
                            ActionButton(title: "Message",
                                      icon: "message.fill",
                                      color: Color(hex: "4CC9F0")) {
                                // TODO: Implement message action
                            }
                            
                            ActionButton(title: "Share Contact",
                                      icon: "square.and.arrow.up.fill",
                                      color: Color(hex: "7209B7")) {
                                // TODO: Implement share action
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
                    // TODO: Implement delete action
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this contact? This action cannot be undone.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateContent = true
                }
            }
        }
    }
}

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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
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
                        ZStack {
                            Circle()
                                .fill(Color(hex: "4361EE").opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            if name.isEmpty {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: "4361EE"))
                            } else {
                                Text(String(name.prefix(1)))
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(Color(hex: "4361EE"))
                            }
                        }
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
                            Button(action: { showDatePicker.toggle() }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Color(hex: "6C757D"))
                                    Text(birthday.formatted(date: .long, time: .omitted))
                                        .foregroundColor(Color(hex: "212529"))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "DEE2E6"), lineWidth: 1)
                                )
                            }
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
                        Button(action: saveContact) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "4361EE"))
                                .cornerRadius(12)
                                .shadow(color: Color(hex: "4361EE").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .disabled(name.isEmpty || phone.isEmpty)
                        .opacity(name.isEmpty || phone.isEmpty ? 0.6 : 1)
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