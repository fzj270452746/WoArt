import UIKit

/// Single, reusable text notification used across the app.
final class ToastCenter {
    static let shared = ToastCenter()

    private var queue: [(message: String, icon: String)] = []
    private var activeToast: UIView?
    private var isPresenting = false

    private init() {}

    func show(_ message: String, icon: String = "checkmark") {
        queue.append((message, icon))
        presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard !isPresenting, !queue.isEmpty, let host = hostView() else { return }
        isPresenting = true
        let item = queue.removeFirst()

        let container = UIView()
        container.backgroundColor = Palette.walnut
        container.layer.cornerRadius = 24
        container.layer.cornerCurve = .continuous
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.22
        container.layer.shadowRadius = 20
        container.layer.shadowOffset = CGSize(width: 0, height: 10)
        container.alpha = 0
        container.transform = CGAffineTransform(translationX: 0, y: -16)

        let iconView = UIImageView()
        iconView.image = UIImage(
            systemName: item.icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        )
        iconView.tintColor = Palette.brassLight
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = item.message
        label.font = Typeface.chip(13.5, weight: .semibold)
        label.textColor = Palette.paper
        label.numberOfLines = 0

        let stack = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [iconView, label])
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        host.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        let top = container.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor, constant: 10)
        NSLayoutConstraint.activate([
            top,
            container.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -24),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: 360)
        ])

        activeToast = container
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.5
        ) {
            container.alpha = 1
            container.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self, weak container] in
            guard let self, let container else { return }
            UIView.animate(withDuration: 0.3, animations: {
                container.alpha = 0
                container.transform = CGAffineTransform(translationX: 0, y: -10)
            }, completion: { _ in
                container.removeFromSuperview()
                if self.activeToast === container {
                    self.activeToast = nil
                }
                self.isPresenting = false
                self.presentNextIfNeeded()
            })
        }
    }

    private func hostView() -> UIView? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) ?? scenes.first?.windows.first
        guard var controller = window?.rootViewController else { return nil }
        while let presented = controller.presentedViewController, !presented.isBeingDismissed {
            controller = presented
        }
        return controller.view
    }
}
