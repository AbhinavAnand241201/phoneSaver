import SwiftUI

struct ReminderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let contact: Contact
    @State private var showingAddReminder = false
    @State private var reminderDate = Date()
    @State private var reminderMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Reminders")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingAddReminder = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            if let reminders = contact.reminders, !reminders.isEmpty {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder) {
                        toggleReminder(reminder)
                    }
                }
            } else {
                Text("No reminders set")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            NavigationView {
                Form {
                    DatePicker("Date", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Message", text: $reminderMessage)
                }
                .navigationTitle("New Reminder")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingAddReminder = false
                    },
                    trailing: Button("Add") {
                        addReminder()
                    }
                    .disabled(reminderMessage.isEmpty)
                )
            }
        }
    }
    
    private func addReminder() {
        let reminder = Reminder(
            id: UUID().uuidString,
            date: reminderDate,
            message: reminderMessage,
            isCompleted: false
        )
        
        var updatedReminders = contact.reminders ?? []
        updatedReminders.append(reminder)
        
        // Update contact with new reminder
        authViewModel.updateReminders(for: contact.id, reminders: updatedReminders)
        
        // Schedule local notification
        authViewModel.setReminder(for: contact, date: reminderDate, message: reminderMessage)
        
        showingAddReminder = false
        reminderMessage = ""
    }
    
    private func toggleReminder(_ reminder: Reminder) {
        var updatedReminders = contact.reminders ?? []
        if let index = updatedReminders.firstIndex(where: { $0.id == reminder.id }) {
            updatedReminders[index].isCompleted.toggle()
            authViewModel.updateReminders(for: contact.id, reminders: updatedReminders)
        }
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.message)
                    .font(.body)
                
                Text(reminder.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reminder.isCompleted ? .green : .gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct ReminderView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderView(contact: Contact(
            id: 1,
            name: "John Doe",
            encryptedPhone: "encrypted",
            reminders: [
                Reminder(id: "1", date: Date(), message: "Follow up about project", isCompleted: false),
                Reminder(id: "2", date: Date().addingTimeInterval(86400), message: "Birthday reminder", isCompleted: true)
            ]
        ))
        .environmentObject(AuthViewModel())
        .padding()
    }
} 