import UIKit

class ComposeBaseViewController: BaseViewController {
    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    private let publishBar = UIView()
    private let publishButton: PillButton
    private var publishBottom: NSLayoutConstraint!
    private let pageTitle: String
    private let pageEyebrow: String
    private let pageSubtitle: String

    init(eyebrow: String, title: String, subtitle: String, publishTitle: String) {
        pageEyebrow = eyebrow
        pageTitle = title
        pageSubtitle = subtitle
        publishButton = PillButton(title: publishTitle, style: .primary, height: 54)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildScaffold()
        buildFields()
        observeKeyboard()
    }

    func buildFields() {}
    func publishTapped() {}

    // MARK: - Scaffold

    private func buildScaffold() {
        let close = CircleIconButton(symbol: "xmark", diameter: 40, pointSize: 14)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let eula = UIButton(type: .system)
        let eulaText = NSAttributedString(
            string: "EULA",
            attributes: [
                .font: Typeface.chip(12, weight: .bold),
                .foregroundColor: Palette.terracotta,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .kern: 0.6
            ]
        )
        eula.setAttributedTitle(eulaText, for: .normal)
        eula.backgroundColor = Palette.terracotta.withAlphaComponent(0.08)
        eula.layer.cornerRadius = 15
        eula.translatesAutoresizingMaskIntoConstraints = false
        eula.heightAnchor.constraint(equalToConstant: 30).isActive = true
        eula.widthAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        eula.addTarget(self, action: #selector(eulaTapped), for: .touchUpInside)

        let topRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [close])
        topRow.addArrangedSubview(UIView())
        topRow.addArrangedSubview(eula)

        let eyebrow = EyebrowLabel(pageEyebrow, color: Palette.terracotta)
        let title = UILabel()
        title.text = pageTitle
        title.font = Typeface.display(35, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = pageSubtitle
        subtitle.font = Typeface.body(13.5)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0
        subtitle.setLineHeight(4)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.addArrangedSubview(topRow)
        contentStack.addArrangedSubview(eyebrow)
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(subtitle)
        contentStack.setCustomSpacing(22, after: topRow)
        contentStack.setCustomSpacing(8, after: eyebrow)
        contentStack.setCustomSpacing(10, after: title)
        contentStack.setCustomSpacing(24, after: subtitle)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 136, right: 0)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        publishBar.backgroundColor = Palette.paper
        view.addSubview(publishBar)
        publishBar.translatesAutoresizingMaskIntoConstraints = false

        let topLine = DividerLine()
        publishBar.addSubview(topLine)
        topLine.translatesAutoresizingMaskIntoConstraints = false

        publishButton.addTarget(self, action: #selector(publishPressed), for: .touchUpInside)
        publishBar.addSubview(publishButton)
        publishButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            publishBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            publishBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topLine.topAnchor.constraint(equalTo: publishBar.topAnchor),
            topLine.leadingAnchor.constraint(equalTo: publishBar.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: publishBar.trailingAnchor),
            publishBar.heightAnchor.constraint(equalToConstant: 104),
            publishButton.topAnchor.constraint(equalTo: publishBar.topAnchor, constant: 14),
            publishButton.leadingAnchor.constraint(equalTo: publishBar.leadingAnchor, constant: 24),
            publishButton.trailingAnchor.constraint(equalTo: publishBar.trailingAnchor, constant: -24),
            publishButton.bottomAnchor.constraint(equalTo: publishBar.bottomAnchor, constant: -36)
        ])
        publishBottom = publishBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        publishBottom.isActive = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fieldBeganEditing(_:)),
            name: UITextField.textDidBeginEditingNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fieldBeganEditing(_:)),
            name: UITextView.textDidBeginEditingNotification,
            object: nil
        )
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    @objc private func eulaTapped() {
        AppLinks.openLegal("eula", from: self)
    }

    @objc private func publishPressed() {
        view.endEditing(true)
        publishTapped()
    }

    func finishAndClose(message: String) {
        Haptics.success()
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .showHomeTab, object: nil)
            ToastCenter.shared.show(message, icon: "checkmark")
        }
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        _ = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification)
        }
        _ = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleKeyboardHidden()
        }
    }

    private func handleKeyboard(_ notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        UIView.animate(withDuration: duration) {
            self.publishBottom.constant = -overlap
            self.scrollView.contentInset.bottom = 136 + overlap
            self.view.layoutIfNeeded()
        }
    }

    private func handleKeyboardHidden() {
        UIView.animate(withDuration: 0.25) {
            self.publishBottom.constant = 0
            self.scrollView.contentInset.bottom = 136
            self.view.layoutIfNeeded()
        }
    }

    @objc private func fieldBeganEditing(_ note: Notification) {
        guard let field = note.object as? UIView, field.isDescendant(of: view) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { [weak self, weak field] in
            guard let self, let field else { return }
            let rect = field.convert(field.bounds, to: self.scrollView).insetBy(dx: 0, dy: -60)
            self.scrollView.scrollRectToVisible(rect, animated: true)
        }
    }
}

final class DashedCardView: UIView {
    private let border = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.cream.withAlphaComponent(0.45)
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        border.fillColor = UIColor.clear.cgColor
        border.strokeColor = Palette.ink.withAlphaComponent(0.18).cgColor
        border.lineWidth = 1.3
        border.lineDashPattern = [6, 5]
        layer.addSublayer(border)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.frame = bounds
        border.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 24).cgPath
    }
}
