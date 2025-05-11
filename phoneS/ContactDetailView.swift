import SwiftUI

struct ContactDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let contact: Contact
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCallSheet = false
    @State private var showingMessageSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Contact Header
                VStack(spacing: 10) {
                    Text(contact.name)
                        .font(.title)
                        .bold()
                    
                    Text(contact.phone)
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Action Buttons
                HStack(spacing: 20) {
                    ActionButton(title: "Call", icon: "phone.fill") {
                        showingCallSheet = true
                    }
                    
                    ActionButton(title: "Message", icon: "message.fill") {
                        showingMessageSheet = true
                    }
                    
                    ActionButton(title: "Edit", icon: "pencil") {
                        showingEditSheet = true
                    }
                }
                .padding()
                
                // Tags Section
                TagView(contact: contact)
                    .padding(.horizontal)
                
                // Insights Section
                InsightsView(contact: contact)
                    .padding(.horizontal)
                
                // Reminders Section
                ReminderView(contact: contact)
                    .padding(.horizontal)
                
                // Delete Button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Text("Delete Contact")
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            EditContactView(contact: contact)
        }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement delete functionality
            }
        } message: {
            Text("Are you sure you want to delete this contact? This action cannot be undone.")
        }
        .sheet(isPresented: $showingCallSheet) {
            CallSheet(contact: contact)
        }
        .sheet(isPresented: $showingMessageSheet) {
            MessageSheet(contact: contact)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct CallSheet: View {
    let contact: Contact
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Calling \(contact.name)...")
                    .font(.title2)
                
                Text(contact.phone)
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Button("End Call") {
                    dismiss()
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Call")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct MessageSheet: View {
    let contact: Contact
    @State private var messageText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $messageText)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                Button("Send Message") {
                    // TODO: Implement message sending
                    dismiss()
                }
                .disabled(messageText.isEmpty)
                .padding()
            }
            .navigationTitle("New Message")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactDetailView(contact: Contact(
                id: 1,
                name: "John Doe",
                encryptedPhone: "encrypted",
                tags: ["Work", "Friend"],
                lastInteraction: Date(),
                contactFrequency: "Weekly",
                preferredTime: "Evenings",
                notes: "Prefers text messages"
            ))
            .environmentObject(AuthViewModel())
        }
    }
} 