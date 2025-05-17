import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isKeyboardVisible = false
    @State private var animateFields = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: "4361EE"))
                            .padding(.top, isKeyboardVisible ? 20 : 60)
                            .scaleEffect(animateFields ? 1 : 0.8)
                            .opacity(animateFields ? 1 : 0)
                        
                        // Welcome Text
                        VStack(spacing: 8) {
                            Text("Welcome Back!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "212529"))
                            
                            Text("Sign in to continue")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "6C757D"))
                        }
                        .padding(.bottom, 20)
                        
                        // Input Fields
                        VStack(spacing: 16) {
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
                                        .textContentType(.password)
                                } else {
                                    CustomSecureField(text: $password,
                                                    placeholder: "Password",
                                                    systemImage: "lock.fill")
                                        .textContentType(.password)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color(hex: "6C757D"))
                                }
                            }
                            .offset(y: animateFields ? 0 : 50)
                            .opacity(animateFields ? 1 : 0)
                        }
                        .padding(.horizontal)
                        
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
                        
                        // Login Button
                        Button(action: login) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
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
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(Color(hex: "6C757D"))
                            
                            NavigationLink(destination: SignupView()) {
                                Text("Sign Up")
                                    .foregroundColor(Color(hex: "4361EE"))
                                    .fontWeight(.semibold)
                            }
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
    }
    
    private func login() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        viewModel.login(email: trimmedEmail, password: trimmedPassword)
    }
}

// MARK: - Supporting Views
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(Color(hex: "6C757D"))
                .frame(width: 20)
            
            SecureField(placeholder, text: $text)
                .textContentType(.password)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 