import SwiftUI

struct ContactsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var selectedFilter: ContactFilter = .all
    @State private var showingAddContact = false
    
    enum ContactFilter {
        case all, favorites, recent, tagged(String)
        
        var title: String {
            switch self {
            case .all: return "All Contacts"
            case .favorites: return "Favorites"
            case .recent: return "Recent"
            case .tagged(let tag): return "Tag: \(tag)"
            }
        }
    }
    
    var filteredContacts: [Contact] {
        let searchFiltered = searchText.isEmpty ? authViewModel.contacts : authViewModel.contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText) ||
            contact.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch selectedFilter {
        case .all:
            return searchFiltered
        case .favorites:
            return searchFiltered.filter { $0.tags.contains("Favorite") }
        case .recent:
            return searchFiltered.sorted { ($0.lastInteraction ?? .distantPast) > ($1.lastInteraction ?? .distantPast) }
        case .tagged(let tag):
            return searchFiltered.filter { $0.tags.contains(tag) }
        }
    }
    
    var availableTags: [String] {
        Array(Set(authViewModel.contacts.flatMap { $0.tags })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: selectedFilter == .all) {
                            selectedFilter = .all
                        }
                        
                        FilterChip(title: "Favorites", isSelected: selectedFilter == .favorites) {
                            selectedFilter = .favorites
                        }
                        
                        FilterChip(title: "Recent", isSelected: selectedFilter == .recent) {
                            selectedFilter = .recent
                        }
                        
                        ForEach(availableTags, id: \.self) { tag in
                            FilterChip(title: tag, isSelected: selectedFilter == .tagged(tag)) {
                                selectedFilter = .tagged(tag)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    ForEach(filteredContacts) { contact in
                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                            ContactRow(contact: contact)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle(selectedFilter.title)
            .navigationBarItems(trailing: Button(action: {
                showingAddContact = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
            }
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                
                if !contact.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(contact.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            if let lastInteraction = contact.lastInteraction {
                Text(lastInteraction.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct ContactsListView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsListView()
            .environmentObject(AuthViewModel())
    }
} 