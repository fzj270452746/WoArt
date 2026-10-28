import UIKit

final class ActionSheetViewController: UIViewController {
    struct Option {
        let title: String
        let symbol: String
        let destructive: Bool
        let handler: () -> Void
    }

    private let sheetTitle: String
    private let options: [Option]
    private let dimView = UIView()
    private let sheet = UIView()

    static func present(
        from presenter: UIViewController,
        title: String,
        options: [Option]
    ) {
        let controller = ActionSheetViewController(title: title, options: options)
        controller.modalPresentationStyle = .overFullScreen
        presenter.present(controller, animated: false)
    }

    private init(title: String, options: [Option]) {
        sheetTitle = title
        self.options = options
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
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancel)))

        sheet.backgroundColor = Palette.card
        sheet.layer.cornerRadius = 34
        sheet.layer.cornerCurve = .continuous
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false

        let grabber = UIView()
        grabber.backgroundColor = Palette.ink.withAlphaComponent(0.16)
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false
        grabber.widthAnchor.constraint(equalToConstant: 40).isActive = true
        grabber.heightAnchor.constraint(equalToConstant: 5).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = sheetTitle
        titleLabel.font = Typeface.display(23, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        let stack = UIStackView(axis: .vertical, spacing: 0, views: [])
        for option in options {
            let row = UIButton(type: .custom)
            row.contentHorizontalAlignment = .fill
            row.addAction(UIAction { [weak self] _ in
                Haptics.tap()
                self?.dismissSheet(then: option.handler)
            }, for: .touchUpInside)

            let icon = UIImageView(
                image: UIImage(
                    systemName: option.symbol,
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                )
            )
            icon.tintColor = option.destructive ? Palette.terracotta : Palette.inkSoft

            let label = UILabel()
            label.text = option.title
            label.font = Typeface.chip(15.5, weight: .semibold)
            label.textColor = option.destructive ? Palette.terracottaDeep : Palette.ink

            row.addSubviews(icon, label)
            icon.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: 54),
                icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 4),
                icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 24),
                label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
                label.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -4),
                label.centerYAnchor.constraint(equalTo: row.centerYAnchor)
            ])
            stack.addArrangedSubview(row)
        }

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(Palette.inkSoft, for: .normal)
        cancelButton.titleLabel?.font = Typeface.chip(14.5, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.heightAnchor.constraint(equalToConstant: 46).isActive = true

        sheet.addSubviews(grabber, titleLabel, stack, cancelButton)
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),

            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 34),
            titleLabel.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 26),
            titleLabel.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -26),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -22),

            cancelButton.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 6),
            cancelButton.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 26),
            cancelButton.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -26),
            cancelButton.bottomAnchor.constraint(equalTo: sheet.safeAreaLayoutGuide.bottomAnchor, constant: -6)
        ])

        sheet.transform = CGAffineTransform(translationX: 0, y: 360)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3) { self.dimView.alpha = 1 }
        UIView.animate(
            withDuration: 0.46,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.2
        ) {
            self.sheet.transform = .identity
        }
    }

    @objc private func cancel() {
        dismissSheet(then: nil)
    }

    private func dismissSheet(then action: (() -> Void)?) {
        UIView.animate(withDuration: 0.25, animations: {
            self.dimView.alpha = 0
            self.sheet.transform = CGAffineTransform(translationX: 0, y: 360)
        }, completion: { _ in
            self.dismiss(animated: false) {
                action?()
            }
        })
    }
}
