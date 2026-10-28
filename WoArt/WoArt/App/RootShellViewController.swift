import UIKit

final class RootShellViewController: UIViewController, DockBarDelegate, UINavigationControllerDelegate {
    private let container = UIView()
    private let dock = DockBar()
    private var navigations: [UINavigationController] = []
    private var currentIndex = -1
    private var dockIsHidden = false

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.paper

        container.frame = view.bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(container)

        let pages: [UIViewController] = [
            WorkshopViewController(),
            HomeViewController(),
            GatheringsViewController(),
            ProfileViewController()
        ]
        navigations = pages.map { page in
            let navigation = UINavigationController(rootViewController: page)
            navigation.isNavigationBarHidden = true
            navigation.delegate = self
            navigation.view.backgroundColor = Palette.paper
            return navigation
        }

        view.addSubview(dock)
        dock.delegate = self
        NSLayoutConstraint.activate([
            dock.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            dock.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            dock.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Metrics.dockBottomGap)
        ])

        // The bench is the heart of the app this phase: it leads the dock.
        showPage(at: 0, animated: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(switchHome),
            name: .showHomeTab,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(requestFailed(_:)),
            name: .studioRequestFailed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionExpired),
            name: .apiSessionExpired,
            object: nil
        )

        StudioStore.shared.start()

    }

    @objc private func requestFailed(_ note: Notification) {
        let message = note.userInfo?["message"] as? String ?? "Something went wrong. Please try again."
        ToastCenter.shared.show(message, icon: "exclamationmark")
    }

    @objc private func sessionExpired() {
        ToastCenter.shared.show("Your session ended. Sign in again to keep sharing.", icon: "person.crop.circle.badge.exclamationmark")
    }

    @objc private func switchHome() {
        selectTab(index: 1)
        navigations[1].popToRootViewController(animated: false)
    }

    // MARK: - Pages

    private func showPage(at index: Int, animated: Bool) {
        guard index >= 0, index < navigations.count, index != currentIndex else { return }
        let incoming = navigations[index]

        if currentIndex >= 0 {
            let outgoing = navigations[currentIndex]
            outgoing.willMove(toParent: nil)
            outgoing.view.removeFromSuperview()
            outgoing.removeFromParent()
        }

        addChild(incoming)
        incoming.view.frame = container.bounds
        incoming.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(incoming.view)
        incoming.didMove(toParent: self)
        container.bringSubviewToFront(incoming.view)

        currentIndex = index
        dock.setActive(index: index)
        updateDockVisibility(animated: animated)

        if animated {
            incoming.view.alpha = 0
            UIView.animate(withDuration: 0.22) {
                incoming.view.alpha = 1
            }
        }
        view.bringSubviewToFront(dock)
    }

    private func updateDockVisibility(animated: Bool) {
        guard currentIndex >= 0 else { return }
        let top = navigations[currentIndex].viewControllers.last
        let shouldHide = (top as? BaseViewController)?.hidesDock ?? false
        setDockHidden(shouldHide, animated: animated)
    }

    private func setDockHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != dockIsHidden else { return }
        dockIsHidden = hidden
        dock.isUserInteractionEnabled = !hidden
        let transform = hidden ? CGAffineTransform(translationX: 0, y: 140) : .identity
        let changes = {
            self.dock.transform = transform
            self.dock.alpha = hidden ? 0 : 1
        }
        if animated {
            UIView.animate(
                withDuration: 0.34,
                delay: 0,
                usingSpringWithDamping: 0.88,
                initialSpringVelocity: 0.2,
                options: [.beginFromCurrentState],
                animations: changes
            )
        } else {
            changes()
        }
    }

    // MARK: - DockBarDelegate

    func dockBar(_ dock: DockBar, didSelectTab index: Int) {
        if index == currentIndex {
            navigations[index].popToRootViewController(animated: true)
            return
        }
        showPage(at: index, animated: true)
    }

    func dockBarDidTapCreate(_ dock: DockBar) {
        presentCreateChooser()
    }

    func selectTab(index: Int) {
        guard index >= 0, index < navigations.count else { return }
        if index == currentIndex {
            navigations[index].popToRootViewController(animated: true)
        } else {
            showPage(at: index, animated: true)
        }
    }

    private func presentCreateChooser() {
        let chooser = CreateChooserViewController()
        chooser.onChoosePost = { [weak self] in
            let compose = ComposePostViewController()
            compose.modalPresentationStyle = .fullScreen
            self?.present(compose, animated: true)
        }
        chooser.onChooseEvent = { [weak self] in
            let compose = ComposeEventViewController()
            compose.modalPresentationStyle = .fullScreen
            self?.present(compose, animated: true)
        }
        chooser.onChooseProject = { [weak self] in
            guard let self else { return }
            self.selectTab(index: 0)
            let workshop = self.navigations[0].viewControllers.first as? WorkshopViewController
            workshop?.presentNewProject()
        }
        chooser.modalPresentationStyle = .pageSheet
        if let sheet = chooser.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 36
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(chooser, animated: true)
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        guard currentIndex >= 0, navigationController === navigations[currentIndex] else { return }
        let shouldHide = (viewController as? BaseViewController)?.hidesDock ?? false
        setDockHidden(shouldHide, animated: animated)
    }
}
