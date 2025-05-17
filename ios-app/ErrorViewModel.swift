import Foundation
import SwiftUI

class ErrorViewModel: ObservableObject {
    @Published var error: Error?
    @Published var showError = false
    @Published var errorMessage = ""
    
    func handleError(_ error: Error) {
        self.error = error
        errorMessage = error.localizedDescription
        showError = true
    }
    
    func handleError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func dismissError() {
        showError = false
        error = nil
        errorMessage = ""
    }
}
