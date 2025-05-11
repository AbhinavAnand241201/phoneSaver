import SwiftUI

struct ContactsTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContactsListView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
                .tag(0)
            
            UpcomingView()
                .tabItem {
                    Label("Upcoming", systemImage: "calendar")
                }
                .tag(1)
            
            InsightsTabView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

struct UpcomingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var upcomingReminders: [(Contact, Reminder)] {
        authViewModel.contacts.flatMap { contact in
            (contact.reminders ?? []).map { reminder in
                (contact, reminder)
            }
        }
        .filter { !$0.1.isCompleted }
        .sorted { $0.1.date < $1.1.date }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(upcomingReminders, id: \.1.id) { contact, reminder in
                    NavigationLink(destination: ContactDetailView(contact: contact)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(reminder.message)
                                .font(.headline)
                            
                            HStack {
                                Text(contact.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(reminder.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Upcoming")
        }
    }
}

struct InsightsTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Contact Statistics")) {
                    StatRow(title: "Total Contacts", value: "\(authViewModel.contacts.count)")
                    StatRow(title: "Most Used Tag", value: mostUsedTag)
                    StatRow(title: "Average Contact Frequency", value: averageContactFrequency)
                }
                
                Section(header: Text("Recent Activity")) {
                    ForEach(recentActivity, id: \.contact.id) { activity in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(activity.contact.name)
                                    .font(.headline)
                                Text(activity.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(activity.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }
    
    private var mostUsedTag: String {
        let tagCounts = authViewModel.contacts.flatMap { $0.tags }
            .reduce(into: [:]) { counts, tag in
                counts[tag, default: 0] += 1
            }
        return tagCounts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    private var averageContactFrequency: String {
        let frequencies = authViewModel.contacts.map { $0.contactFrequency }
        let frequencyCounts = frequencies.reduce(into: [:]) { counts, frequency in
            counts[frequency, default: 0] += 1
        }
        return frequencyCounts.max(by: { $0.value < $1.value })?.key ?? "Weekly"
    }
    
    private var recentActivity: [(contact: Contact, date: Date, description: String)] {
        authViewModel.contacts.compactMap { contact in
            guard let lastInteraction = contact.lastInteraction else { return nil }
            return (contact, lastInteraction, "Last contact")
        }
        .sorted { $0.date > $1.date }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingBackupAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    Button("Log Out") {
                        authViewModel.logout()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Data Management")) {
                    Button("Backup Contacts") {
                        showingBackupAlert = true
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Backup Contacts", isPresented: $showingBackupAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Backup") {
                    authViewModel.backupContacts()
                }
            } message: {
                Text("This will create a backup of all your contacts.")
            }
        }
    }
}

struct ContactsTabView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsTabView()
            .environmentObject(AuthViewModel())
    }
} 