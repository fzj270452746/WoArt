import UIKit

/// Shimmering ring animation shown while an account action completes.
final class LoadingVeil: UIView {
    private let card = UIView()
    private let messageLabel = UILabel()
    private let ringContainer = UIView()
    private var ringLayers: [CAShapeLayer] = []
    private var isFinishing = false

    static func show(
        message: String = "Working the grain…",
        duration: TimeInterval? = nil,
        completion: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            guard let veil = present(message: message) else {
                completion?()
                return
            }
            let span = duration ?? Double.random(in: 1.1...1.35)
            DispatchQueue.main.asyncAfter(deadline: .now() + span) {
                veil.finish(completion: completion)
            }
        }
    }

    /// Keeps the veil up until the async work finishes (with a short minimum
    /// so fast requests still read as an intentional action).
    @MainActor
    static func run(
        message: String,
        minimum: TimeInterval = 0.8,
        operation: @escaping () async throws -> Void
    ) async throws {
        guard let veil = present(message: message) else {
            try await operation()
            return
        }
        let started = Date()
        do {
            try await operation()
            let remaining = max(0, minimum - Date().timeIntervalSince(started))
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            await veil.finishAsync()
        } catch {
            await veil.finishAsync()
            throw error
        }
    }

    private static func present(message: String) -> LoadingVeil? {
        guard let host = hostView() else { return nil }
        let veil = LoadingVeil(message: message)
        veil.frame = host.bounds
        veil.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(veil)
        veil.appear()
        return veil
    }

    private func finishAsync() async {
        await withCheckedContinuation { continuation in
            finish {
                continuation.resume()
            }
        }
    }

    private init(message: String) {
        super.init(frame: .zero)
        backgroundColor = Palette.walnut.withAlphaComponent(0.22)
        isUserInteractionEnabled = true

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)
        blur.pinEdges(to: self)

        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 30
        card.layer.cornerCurve = .continuous
        card.layer.shadowColor = UIColor(hex: 0x3A2114).cgColor
        card.layer.shadowOpacity = 0.2
        card.layer.shadowRadius = 30
        card.layer.shadowOffset = CGSize(width: 0, height: 16)
        addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.text = message
        messageLabel.font = Typeface.chip(14, weight: .semibold)
        messageLabel.textColor = Palette.inkSoft
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        card.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(ringContainer)
        ringContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            card.widthAnchor.constraint(equalToConstant: 208),

            ringContainer.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            ringContainer.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            ringContainer.widthAnchor.constraint(equalToConstant: 96),
            ringContainer.heightAnchor.constraint(equalToConstant: 96),

            messageLabel.topAnchor.constraint(equalTo: ringContainer.bottomAnchor, constant: 18),
            messageLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -26)
        ])

    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        card.layoutIfNeeded()
        if ringLayers.isEmpty {
            buildRings(in: ringContainer.bounds)
        }
    }

    private func buildRings(in bounds: CGRect) {
        guard !bounds.isEmpty else { return }
        let colors = [Palette.terracotta, Palette.brass, Palette.moss]
        let fractions: [CGFloat] = [0.96, 0.7, 0.44]

        for index in 0..<3 {
            let radius = bounds.width / 2 * fractions[index] - 4
            let ring = CAShapeLayer()
            ring.frame = bounds
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: -0.4 * .pi,
                endAngle: 1.15 * .pi,
                clockwise: true
            )
            ring.path = path.cgPath
            ring.fillColor = UIColor.clear.cgColor
            ring.strokeColor = colors[index].cgColor
            ring.lineWidth = index == 0 ? 5 : 3
            ring.lineCap = .round
            ringContainer.layer.addSublayer(ring)
            ringLayers.append(ring)

            ring.position = CGPoint(x: bounds.midX, y: bounds.midY)
            let spin = CABasicAnimation(keyPath: "transform.rotation.z")
            spin.fromValue = 0
            spin.toValue = (index % 2 == 0 ? 1 : -1) * 2 * Double.pi
            spin.duration = 1.6 + Double(index) * 0.45
            spin.repeatCount = .infinity
            spin.timingFunction = CAMediaTimingFunction(name: .linear)
            ring.add(spin, forKey: "spin")
        }
    }

    private func appear() {
        alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2) {
            self.alpha = 1
            self.card.transform = .identity
        }
    }

    private func finish(completion: (() -> Void)?) {
        guard !isFinishing else { return }
        isFinishing = true
        Haptics.success()
        UIView.animate(withDuration: 0.26, animations: {
            self.alpha = 0
            self.card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    private static func hostView() -> UIView? {
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
