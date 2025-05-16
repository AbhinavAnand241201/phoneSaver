import SwiftUI

struct SignupView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isKeyboardVisible = false
    @State private var animateFields = false
    
    // Error handling
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color(hex: "F8F9FA")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "4361EE"))
                        .padding(.top, isKeyboardVisible ? 20 : 60)
                        .scaleEffect(animateFields ? 1 : 0.8)
                        .opacity(animateFields ? 1 : 0)
                    
                    // Welcome Text
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "212529"))
                        
                        Text("Sign up to get started")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "6C757D"))
                    }
                    .padding(.bottom, 20)
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        CustomTextField(text: $name,
                                     placeholder: "Full Name",
                                     systemImage: "person.fill")
                            .offset(y: animateFields ? 0 : 50)
                            .opacity(animateFields ? 1 : 0)
                            .textContentType(.name)
                        
                        CustomTextField(text: $email,
                                     placeholder: "Email",
                                     systemImage: "envelope.fill")
                            .offset(y: animateFields ? 0 : 50)
                            .opacity(animateFields ? 1 : 0)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        // Password Field
                        HStack {
                            if showPassword {
                                CustomTextField(text: $password,
                                             placeholder: "Password",
                                             systemImage: "lock.fill")
                                    .textContentType(.newPassword)
                            } else {
                                CustomSecureField(text: $password,
                                                placeholder: "Password",
                                                systemImage: "lock.fill")
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color(hex: "6C757D"))
                            }
                        }
                        .offset(y: animateFields ? 0 : 50)
                        .opacity(animateFields ? 1 : 0)
                        
                        // Confirm Password Field
                        HStack {
                            if showConfirmPassword {
                                CustomTextField(text: $confirmPassword,
                                             placeholder: "Confirm Password",
                                             systemImage: "lock.fill")
                                    .textContentType(.newPassword)
                            } else {
                                CustomSecureField(text: $confirmPassword,
                                                placeholder: "Confirm Password",
                                                systemImage: "lock.fill")
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color(hex: "6C757D"))
                            }
                        }
                        .offset(y: animateFields ? 0 : 50)
                        .opacity(animateFields ? 1 : 0)
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if viewModel.errorViewModel.showError {
                        VStack(spacing: 8) {
                            Text(viewModel.errorViewModel.errorMessage)
                                .foregroundColor(Color(hex: "DC3545"))
                                .font(.system(size: 14, weight: .medium))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                viewModel.errorViewModel.dismissError()
                            }) {
                                Text("Dismiss")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "4361EE"))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(hex: "F8D7DA"))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                    
                    // Sign Up Button
                    Button(action: signup) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "4361EE"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)
                    
                    // Login Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(Color(hex: "6C757D"))
                        
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(Color(hex: "4361EE"))
                        .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
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
    
    private func signup() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty,
              !trimmedEmail.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty,
              password == confirmPassword else {
            viewModel.errorViewModel.handleError("Please fill in all fields and ensure passwords match")
            return
        }
        
        viewModel.email = trimmedEmail
        viewModel.password = password
        viewModel.signup()
        
        if viewModel.isAuthenticated {
            dismiss()
        }
    }
}

// MARK: - Preview
struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}