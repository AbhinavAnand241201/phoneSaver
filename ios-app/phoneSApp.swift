import SwiftUI
import Firebase

@main
struct phoneSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    setupAppearance()
                }
        }
    }
    
    private func setupAppearance() {
        // Navigation Bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "F8F9FA"))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "212529"))]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color(hex: "212529"))]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Tab Bar
        UITabBar.appearance().backgroundColor = UIColor(Color(hex: "F8F9FA"))
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color(hex: "6C757D"))
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        do {
            try FirebaseApp.configure()
        } catch {
            print("Firebase configuration failed: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    func application(_ application: UIApplication,
                    configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

// MARK: - Scene Delegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView())
        window.makeKeyAndVisible()
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var contacts: [Contact] = []
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let keychainWrapper = KeychainWrapper()
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.user = user
            }
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func hideError() {
        errorMessage = nil
        showError = false
    }
    
    func loadContacts() {
        isLoading = true
        
        db.collection("contacts").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.contacts = []
                    return
                }
                
                self?.contacts = documents.compactMap { document in
                    try? document.data(as: Contact.self)
                }
            }
        }
    }
    
    func saveContact(_ contact: Contact) {
        isLoading = true
        
        do {
            let contactRef = db.collection("contacts").document(contact.id)
            try contactRef.setData(from: contact)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadContacts()
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.showError(error.localizedDescription)
            }
        }
    }
    
    func deleteContact(_ contact: Contact) {
        isLoading = true
        
        db.collection("contacts").document(contact.id).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.showError(error.localizedDescription)
                    return
                }
                
                self?.loadContacts()
            }
        }
    }
}




