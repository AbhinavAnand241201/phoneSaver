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
    @State private var isKeyboardVisible = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Contact Avatar
                        ContactAvatar(name: name, size: 100)
                            .padding(.top, isKeyboardVisible ? 10 : 20)
                        
                        // Input Fields
                        VStack(spacing: 16) {
                            CustomTextField(text: $name,
                                         placeholder: "Name",
                                         systemImage: "person.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                                .textContentType(.name)
                            
                            CustomTextField(text: $phone,
                                         placeholder: "Phone Number",
                                         systemImage: "phone.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .onChange(of: phone) { newValue in
                                    phone = formatPhoneNumber(newValue)
                                }
                            
                            CustomTextField(text: $tags,
                                         placeholder: "Tags (comma separated)",
                                         systemImage: "tag.fill")
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                                .textContentType(.none)
                                .autocapitalization(.none)
                            
                            // Birthday Picker
                            BirthdayPickerButton(date: birthday, showDatePicker: $showDatePicker)
                                .offset(y: animateFields ? 0 : 50)
                                .opacity(animateFields ? 1 : 0)
                        }
                        .padding(.horizontal)
                        
                        if showDatePicker {
                            DatePicker("Birthday",
                                     selection: $birthday,
                                     in: ...Date(),
                                     displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(Color(hex: "DC3545"))
                                .font(.system(size: 14, weight: .medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color(hex: "DC3545").opacity(0.1))
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Save Button
                        SaveButton(title: "Save Contact",
                                 isDisabled: !isValidInput || viewModel.isLoading) {
                            saveContact()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
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
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation {
                    isKeyboardVisible = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation {
                    isKeyboardVisible = false
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phone.count >= 10
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        if digits.count <= 3 {
            return digits
        } else if digits.count <= 6 {
            return "\(digits.prefix(3))-\(digits.dropFirst(3))"
        } else {
            return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(3))-\(digits.dropFirst(6))"
        }
    }
    
    private func saveContact() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTags = tags.trimmingCharacters(in: .whitespacesAndNewlines)
        
        viewModel.saveContact(name: trimmedName,
                            phone: trimmedPhone,
                            tags: trimmedTags,
                            birthday: birthday)
    }
}

// MARK: - Supporting Views
struct ContactAvatar: View {
    let name: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "4361EE").opacity(0.1))
                .frame(width: size, height: size)
            
            if name.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Color(hex: "4361EE"))
            } else {
                Text(String(name.prefix(1)))
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(Color(hex: "4361EE"))
            }
        }
    }
}

struct BirthdayPickerButton: View {
    let date: Date
    @Binding var showDatePicker: Bool
    
    var body: some View {
        Button(action: { showDatePicker.toggle() }) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "6C757D"))
                Text(date.formatted(date: .long, time: .omitted))
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
    }
}

struct SaveButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "4361EE"))
                .cornerRadius(12)
                .shadow(color: Color(hex: "4361EE").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

// MARK: - ViewModel
class AddContactViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func saveContact(name: String, phone: String, tags: String, birthday: Date) {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement API call to save contact
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            // Simulate success
        }
    }
}

// MARK: - Preview
struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView()
    }
}
