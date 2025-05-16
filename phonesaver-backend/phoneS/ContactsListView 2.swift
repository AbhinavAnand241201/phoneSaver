//
//  ContactsListView 2.swift
//  phoneS
//
//  Created by ABHINAV ANAND  on 11/05/25.
//


import SwiftUI

struct ContactsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var contacts: [Contact] = []
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText) ||
            contact.phone.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .transition(.scale.combined(with: .opacity))
                    } else if let errorMessage = authViewModel.errorMessage {
                        ErrorView(message: errorMessage)
                    } else if filteredContacts.isEmpty {
                        EmptyStateView()
                    } else {
                        List {
                            ForEach(filteredContacts) { contact in
                                ContactRow(contact: contact)
                                    .listRowBackground(Color(.systemBackground))
                                    .listRowSeparator(.hidden)
                                    .padding(.vertical, 4)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .refreshable {
                            await refreshContacts()
                        }
                    }
                }
            }
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshContacts()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .symbolEffect(.bounce, options: .repeating)
                    }
                }
            }
        }
        .onAppear {
            loadContacts()
        }
    }
    
    private func loadContacts() {
        authViewModel.fetchContacts { fetchedContacts in
            withAnimation {
                self.contacts = fetchedContacts
            }
        }
    }
    
    private func refreshContacts() async {
        isRefreshing = true
        authViewModel.fetchContacts { fetchedContacts in
            withAnimation {
                self.contacts = fetchedContacts
                self.isRefreshing = false
            }
        }
    }
}

// Search Bar View
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search contacts...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

// Contact Row View
struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(contact.name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.phone)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                // Call action
                if let url = URL(string: "tel://\(contact.phone)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Image(systemName: "phone.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Contacts Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add some contacts to get started")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// Error View
struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct ContactsListView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsListView()
            .environmentObject(AuthViewModel())
    }
}
