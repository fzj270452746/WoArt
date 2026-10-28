import UIKit

final class ConfirmSheetViewController: UIViewController {
    private let dimView = UIView()
    private let sheet = UIView()
    private let grabber = UIView()
    private let titleText: String
    private let messageText: String
    private let confirmTitle: String
    private let isDestructive: Bool
    private let onConfirm: () -> Void

    static func present(
        from presenter: UIViewController,
        title: String,
        message: String,
        confirmTitle: String,
        destructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) {
        let controller = ConfirmSheetViewController(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            destructive: destructive,
            onConfirm: onConfirm
        )
        controller.modalPresentationStyle = .overFullScreen
        presenter.present(controller, animated: false)
    }

    private init(
        title: String,
        message: String,
        confirmTitle: String,
        destructive: Bool,
        onConfirm: @escaping () -> Void
    ) {
        titleText = title
        messageText = message
        self.confirmTitle = confirmTitle
        isDestructive = destructive
        self.onConfirm = onConfirm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dimView.backgroundColor = Palette.scrim
        dimView.alpha = 0
        view.addSubview(dimView)
        dimView.pinEdges(to: view)
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))

        sheet.backgroundColor = Palette.card
        sheet.layer.cornerRadius = 34
        sheet.layer.cornerCurve = .continuous
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false

        let close = CircleIconButton(symbol: "xmark", diameter: 34, background: Palette.cream, pointSize: 12)
        close.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = Typeface.display(26, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.text = messageText
        messageLabel.font = Typeface.body(14.5)
        messageLabel.textColor = Palette.inkSoft
        messageLabel.numberOfLines = 0
        messageLabel.setLineHeight(5)

        let confirm = PillButton(
            title: confirmTitle,
            style: isDestructive ? .primary : .dark,
            height: 54
        )
        confirm.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let cancel = UIButton(type: .system)
        cancel.setTitle("Keep it as it is", for: .normal)
        cancel.setTitleColor(Palette.inkSoft, for: .normal)
        cancel.titleLabel?.font = Typeface.chip(14, weight: .semibold)
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        grabber.backgroundColor = Palette.ink.withAlphaComponent(0.16)
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(axis: .vertical, spacing: 16, views: [titleLabel, messageLabel, confirm, cancel])
        stack.setCustomSpacing(10, after: titleLabel)
        stack.setCustomSpacing(22, after: messageLabel)

        sheet.addSubviews(grabber, close, stack)
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 40),
            grabber.heightAnchor.constraint(equalToConstant: 5),

            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            close.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 26),
            close.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -22),

            stack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 62),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -26),
            stack.bottomAnchor.constraint(equalTo: sheet.safeAreaLayoutGuide.bottomAnchor, constant: -14)
        ])

        sheet.transform = CGAffineTransform(translationX: 0, y: 420)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3) {
            self.dimView.alpha = 1
        }
        UIView.animate(
            withDuration: 0.48,
            delay: 0,
            usingSpringWithDamping: 0.84,
            initialSpringVelocity: 0.2
        ) {
            self.sheet.transform = .identity
        }
    }

    @objc private func cancelTapped() {
        Haptics.tap()
        dismissSheet(completion: nil)
    }

    @objc private func confirmTapped() {
        Haptics.success()
        dismissSheet(completion: onConfirm)
    }

    private func dismissSheet(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.26, animations: {
            self.dimView.alpha = 0
            self.sheet.transform = CGAffineTransform(translationX: 0, y: 420)
        }, completion: { _ in
            self.dismiss(animated: false) {
                completion?()
            }
        })
    }
}

extension UILabel {
    func setLineHeight(_ spacing: CGFloat) {
        guard let text else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = spacing
        attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font as Any,
                .foregroundColor: textColor as Any,
                .paragraphStyle: paragraph
            ]
        )
    }
}
