import SwiftUI

struct ContactListView: View {
    @StateObject private var viewModel = ContactListViewModel()
    @State private var searchText = ""
    @State private var showAddContact = false
    @State private var selectedContact: Contact?
    @State private var animateList = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Content
                    if viewModel.isLoading && viewModel.contacts.isEmpty {
                        LoadingView()
                    } else if let error = viewModel.error {
                        ErrorView(error: error, retryAction: viewModel.fetchContacts)
                    } else if filteredContacts.isEmpty {
                        EmptyStateView(searchText: searchText)
                    } else {
                        // Contact List
                        ScrollView {
                            RefreshableScrollView(isRefreshing: $isRefreshing) {
                                viewModel.fetchContacts()
                            }
                            
                            LazyVStack(spacing: 12) {
                                ForEach(filteredContacts) { contact in
                                    ContactRow(contact: contact)
                                        .offset(y: animateList ? 0 : 50)
                                        .opacity(animateList ? 1 : 0)
                                        .onTapGesture {
                                            selectedContact = contact
                                        }
                                }
                                
                                if viewModel.hasMoreContacts {
                                    ProgressView()
                                        .padding()
                                        .onAppear {
                                            viewModel.loadMoreContacts()
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                // Add Contact Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddContactButton(action: { showAddContact = true })
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
                viewModel.fetchContacts()
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

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "6C757D"))
            TextField("Search contacts", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct ContactRow: View {
    let contact: Contact
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Contact Avatar
            ContactAvatar(name: contact.name)
            
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
                TagsView(tags: contact.tags)
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

struct ContactAvatar: View {
    let name: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "4361EE").opacity(0.1))
                .frame(width: 50, height: 50)
            
            Text(String(name.prefix(1)))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "4361EE"))
        }
    }
}

struct TagsView: View {
    let tags: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags.components(separatedBy: ","), id: \.self) { tag in
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

struct AddContactButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color(hex: "4361EE"))
                .clipShape(Circle())
                .shadow(color: Color(hex: "4361EE").opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading contacts...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "6C757D"))
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "DC3545"))
            
            Text(error.localizedDescription)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "6C757D"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Text("Retry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "4361EE"))
                    .cornerRadius(8)
            }
        }
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "person.crop.circle.badge.plus" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "6C757D"))
            
            Text(searchText.isEmpty ? "No contacts yet" : "No matching contacts")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "212529"))
            
            if searchText.isEmpty {
                Text("Add your first contact by tapping the + button")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "6C757D"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

struct RefreshableScrollView<Content: View>: View {
    @Binding var isRefreshing: Bool
    let action: () -> Void
    let content: Content
    
    init(isRefreshing: Binding<Bool>,
         action: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self._isRefreshing = isRefreshing
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView(action: action, isRefreshing: $isRefreshing)
                        .offset(y: -50)
                    
                    VStack {
                        content
                    }
                    .offset(y: isRefreshing ? 50 : 0)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

struct MovingView: View {
    let action: () -> Void
    @Binding var isRefreshing: Bool
    
    var body: some View {
        HStack {
            if isRefreshing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .frame(height: 50)
    }
}

// MARK: - ViewModel
class ContactListViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMoreContacts = false
    
    private var currentPage = 1
    private let pageSize = 20
    
    func fetchContacts() {
        isLoading = true
        error = nil
        
        // TODO: Implement API call to fetch contacts
        // For now, using sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.contacts = [
                Contact(id: 1, name: "John Doe", phone: "1234567890", encryptedPhone: "", tags: "Work,Friend", lastInteraction: Date(), birthday: "1990-01-01"),
                Contact(id: 2, name: "Jane Smith", phone: "0987654321", encryptedPhone: "", tags: "Family", lastInteraction: Date().addingTimeInterval(-86400), birthday: "1992-05-15")
            ]
            self.isLoading = false
            self.hasMoreContacts = false
        }
    }
    
    func loadMoreContacts() {
        guard !isLoading else { return }
        
        currentPage += 1
        // TODO: Implement pagination
    }
}

// MARK: - Model
struct Contact: Identifiable {
    let id: Int
    let name: String
    let phone: String
    let encryptedPhone: String
    let tags: String
    let lastInteraction: Date?
    let birthday: String
}

// MARK: - Preview
struct ContactListView_Previews: PreviewProvider {
    static var previews: some View {
        ContactListView()
    }
} 