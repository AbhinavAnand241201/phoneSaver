import SwiftUI

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddContactViewModel()
    @State private var name = ""
    @State private var phone = ""
    @State private var tags = ""
    @State private var birthday = Date()
    @State private var showDatePicker = false
    @State private var animateFields = false
    
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
                            Text("Save Contact")
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
            .navigationTitle("Add Contact")
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
        // TODO: Implement contact saving
        dismiss()
    }
}

class AddContactViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func saveContact(name: String, phone: String, tags: String, birthday: Date) {
        // TODO: Implement API call to save contact
    }
}

struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView()
    }
}
