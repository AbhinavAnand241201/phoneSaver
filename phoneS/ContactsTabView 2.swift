//
//  ContactsTabView 2.swift
//  phoneS
//
//  Created by ABHINAV ANAND  on 11/05/25.
//


import SwiftUI

struct ContactsTabView  : View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            ContactsListView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2")
                }
            
            AddContactView()
                .tabItem {
                    Label("Add Contact", systemImage: "person.badge.plus")
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
