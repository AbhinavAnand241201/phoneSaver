import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var name = ""
    @State private var email = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isEditing = false
    @State private var isKeyboardVisible = false
    @State private var animateContent = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F8F9FA")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image
                        VStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 8)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(Color(hex: "4361EE"))
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 8)
                            }
                            
                            Button(action: { showImagePicker = true }) {
                                Text("Change Photo")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "4361EE"))
                            }
                            .padding(.top, 8)
                        }
                        .padding(.top, 20)
                        .scaleEffect(animateContent ? 1 : 0.8)
                        .opacity(animateContent ? 1 : 0)
                        
                        // Profile Info
                        VStack(spacing: 16) {
                            if isEditing {
                                CustomTextField(text: $name,
                                             placeholder: "Full Name",
                                             systemImage: "person.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                                    .textContentType(.name)
                                
                                CustomTextField(text: $email,
                                             placeholder: "Email",
                                             systemImage: "envelope.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            } else {
                                InfoCard(title: "Name",
                                       value: viewModel.user?.name ?? "",
                                       icon: "person.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                                
                                InfoCard(title: "Email",
                                       value: viewModel.user?.email ?? "",
                                       icon: "envelope.fill")
                                    .offset(y: animateContent ? 0 : 50)
                                    .opacity(animateContent ? 1 : 0)
                            }
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
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if isEditing {
                                Button(action: saveProfile) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Save Changes")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "4361EE"))
                                .cornerRadius(12)
                                .disabled(viewModel.isLoading)
                                
                                Button(action: { isEditing = false }) {
                                    Text("Cancel")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "6C757D"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "6C757D"), lineWidth: 1)
                                )
                            } else {
                                Button(action: { isEditing = true }) {
                                    Text("Edit Profile")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "4361EE"))
                                .cornerRadius(12)
                                
                                Button(action: { showLogoutAlert = true }) {
                                    Text("Logout")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "DC3545"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "DC3545"), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    viewModel.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateContent = true
                }
                if let user = viewModel.user {
                    name = user.name
                    email = user.email
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
    
    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        viewModel.updateProfile(name: trimmedName, email: trimmedEmail)
        isEditing = false
    }
}

// MARK: - Supporting Views
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 