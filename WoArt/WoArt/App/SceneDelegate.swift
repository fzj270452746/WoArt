import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .light
        window.backgroundColor = Palette.paper
        window.tintColor = Palette.terracotta
        window.rootViewController = RootShellViewController()
        window.makeKeyAndVisible()
        self.window = window

        let navigationBar = UINavigationBar.appearance()
        navigationBar.isHidden = true
    }
}
