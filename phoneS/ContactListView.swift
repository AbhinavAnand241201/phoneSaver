import SwiftUI

struct ContactListView: View {
    @StateObject private var viewModel = ContactListViewModel()
    @State private var searchText = ""
    @State private var showAddContact = false
    @State private var selectedContact: Contact?
    @State private var animateList = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: "6C757D"))
                        TextField("Search contacts", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Contact List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredContacts) { contact in
                                ContactRow(contact: contact)
                                    .offset(y: animateList ? 0 : 50)
                                    .opacity(animateList ? 1 : 0)
                                    .onTapGesture {
                                        selectedContact = contact
                                    }
                            }
                        }
                        .padding()
                    }
                }
                
                // Add Contact Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddContact = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "4361EE"))
                                .clipShape(Circle())
                                .shadow(color: Color(hex: "4361EE").opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddContact) {
                AddContactView()
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateList = true
                }
            }
        }
    }
    
    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return viewModel.contacts
        }
        return viewModel.contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Contact Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "4361EE").opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(String(contact.name.prefix(1)))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "4361EE"))
            }
            
            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "212529"))
                
                if let lastInteraction = contact.lastInteraction {
                    Text("Last interaction: \(lastInteraction.formatted(.relative))")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "6C757D"))
                }
            }
            
            Spacer()
            
            // Tags
            if !contact.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(contact.tags.components(separatedBy: ","), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "4361EE"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "4361EE").opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(width: 120)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
}

struct ContactListViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    
    init() {
        // TODO: Fetch contacts from backend
        // For now, using sample data
        contacts = [
            Contact(id: 1, name: "John Doe", phone: "1234567890", encryptedPhone: "", tags: "Work,Friend", lastInteraction: Date(), birthday: "1990-01-01"),
            Contact(id: 2, name: "Jane Smith", phone: "0987654321", encryptedPhone: "", tags: "Family", lastInteraction: Date().addingTimeInterval(-86400), birthday: "1992-05-15")
        ]
    }
}

struct Contact: Identifiable {
    let id: Int
    let name: String
    let phone: String
    let encryptedPhone: String
    let tags: String
    let lastInteraction: Date?
    let birthday: String
}

struct ContactListView_Previews: PreviewProvider {
    static var previews: some View {
        ContactListView()
    }
} 