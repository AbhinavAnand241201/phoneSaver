import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var animateBackground = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                             startPoint: animateBackground ? .topLeading : .bottomLeading,
                             endPoint: animateBackground ? .bottomTrailing : .topTrailing)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                            animateBackground.toggle()
                        }
                    }
                
                VStack(spacing: 25) {
                    // Logo and Title
                    VStack(spacing: 10) {
                        Image(systemName: "phone.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .symbolEffect(.bounce, options: .repeating)
                        
                        Text("PhoneSaver")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 50)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        CustomTextField(text: $authViewModel.email,
                                     placeholder: "Email",
                                     systemImage: "envelope.fill")
                        
                        CustomSecureField(text: $authViewModel.password,
                                        placeholder: "Password",
                                        systemImage: "lock.fill")
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Loading Indicator
                    if authViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            withAnimation {
                                authViewModel.signup()
                            }
                        }) {
                            AuthButtonView(title: "Sign Up", color: .blue)
                        }
                        
                        Button(action: {
                            withAnimation {
                                authViewModel.login()
                            }
                        }) {
                            AuthButtonView(title: "Log In", color: .green)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// Custom TextField
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Custom SecureField
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
            SecureField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Custom Button View
struct AuthButtonView: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(15)
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
