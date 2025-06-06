import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var animateBackground = false
    @State private var showLogo = false
    @State private var showFields = false
    @State private var showButtons = false
    @State private var isKeyboardVisible = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                LinearGradient(gradient: Gradient(colors: [
                    Color(hex: "F8F9FA"),
                    Color(hex: "E9ECEF")
                ]), startPoint: animateBackground ? .topLeading : .bottomLeading,
                   endPoint: animateBackground ? .bottomTrailing : .topTrailing)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
                            animateBackground.toggle()
                        }
                    }
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and Title
                        VStack(spacing: 15) {
                            Image(systemName: "phone.circle.fill")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .foregroundColor(Color(hex: "4361EE"))
                                .opacity(showLogo ? 1 : 0)
                                .scaleEffect(showLogo ? 1 : 0.8)
                            
                            Text("PhoneSaver")
                                .font(.system(size: 36, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "212529"))
                                .opacity(showLogo ? 1 : 0)
                        }
                        .padding(.top, isKeyboardVisible ? 20 : 60)
                        
                        // Input Fields
                        VStack(spacing: 16) {
                            CustomTextField(text: $authViewModel.email,
                                         placeholder: "Email",
                                         systemImage: "envelope.fill",
                                         keyboardType: .emailAddress)
                                .offset(y: showFields ? 0 : 50)
                                .opacity(showFields ? 1 : 0)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                            
                            CustomSecureField(text: $authViewModel.password,
                                            placeholder: "Password",
                                            systemImage: "lock.fill")
                                .offset(y: showFields ? 0 : 50)
                                .opacity(showFields ? 1 : 0)
                                .textContentType(isSignUp ? .newPassword : .password)
                        }
                        .padding(.horizontal)
                        
                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(Color(hex: "DC3545"))
                                .font(.system(size: 14, weight: .medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color(hex: "DC3545").opacity(0.1))
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Loading Indicator
                        if authViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color(hex: "4361EE"))
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                if validateInput() {
                                    authViewModel.signup()
                                }
                            }) {
                                AuthButtonView(title: "Sign Up", color: Color(hex: "4361EE"))
                            }
                            .offset(y: showButtons ? 0 : 50)
                            .opacity(showButtons ? 1 : 0)
                            
                            Button(action: {
                                if validateInput() {
                                    authViewModel.login()
                                }
                            }) {
                                AuthButtonView(title: "Log In", color: Color(hex: "4CC9F0"))
                            }
                            .offset(y: showButtons ? 0 : 50)
                            .opacity(showButtons ? 1 : 0)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    showLogo = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    showFields = true
                }
                withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                    showButtons = true
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
    
    private func validateInput() -> Bool {
        // Email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: authViewModel.email) else {
            authViewModel.errorMessage = "Please enter a valid email address"
            return false
        }
        
        // Password validation
        guard authViewModel.password.count >= 8 else {
            authViewModel.errorMessage = "Password must be at least 8 characters long"
            return false
        }
        
        // Password strength validation
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$&*])(?=.*[a-z]).{8,}$"
        let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
        if isSignUp && !passwordPredicate.evaluate(with: authViewModel.password) {
            authViewModel.errorMessage = "Password must contain at least one uppercase letter, one number, and one special character"
            return false
        }
        
        return true
    }
}

// MARK: - Supporting Views
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(Color(hex: "6C757D"))
                .font(.system(size: 16, weight: .medium))
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F8F9FA"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "DEE2E6"), lineWidth: 1)
        )
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(Color(hex: "6C757D"))
                .font(.system(size: 16, weight: .medium))
            SecureField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F8F9FA"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "DEE2E6"), lineWidth: 1)
        )
    }
}

struct AuthButtonView: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
