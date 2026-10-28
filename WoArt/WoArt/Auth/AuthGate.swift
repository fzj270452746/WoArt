import UIKit

enum AuthGate {
    /// Returns true when the person is signed in. Otherwise presents the auth screen
    /// and runs `action` after a successful sign in.
    @discardableResult
    static func requireLogin(from controller: UIViewController, then action: (() -> Void)? = nil) -> Bool {
        if AuthService.shared.isSignedIn {
            StudioStore.shared.ensureCurrentProfile()
            return true
        }
        let auth = AuthViewController()
        auth.onSuccess = action
        auth.modalPresentationStyle = .fullScreen
        auth.modalTransitionStyle = .coverVertical
        controller.present(auth, animated: true)
        return false
    }
}
