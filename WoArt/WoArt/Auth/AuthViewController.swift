import UIKit
import AuthenticationServices

final class AuthViewController: BaseViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    enum Mode {
        case signIn
        case signUp
    }

    var onSuccess: (() -> Void)?
    var initialMode: Mode = .signIn

    private var mode: Mode = .signIn
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let eyebrow = EyebrowLabel("WoArt Atelier", color: Palette.terracotta)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let card = CardView(radius: 30)
    private let nameField = InputFieldView(title: "Maker name", placeholder: "yourname")
    private let passwordField = InputFieldView(title: "Password", placeholder: "At least 6 characters", secure: true)
    private let confirmField = InputFieldView(title: "Confirm password", placeholder: "One more time", secure: true)
    private let errorLabel = UILabel()
    private let primaryButton = PillButton(title: "Sign in", style: .primary, height: 56)
    private let modeButton = UIButton(type: .system)
    private let footer = UITextView()
    private let closeButton = CircleIconButton(symbol: "xmark", diameter: 40, pointSize: 14)
    private var footerBottom: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        mode = initialMode
        buildInterface()
        applyMode(animated: false)
        observeKeyboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if self.nameField.text.isEmpty {
                self.nameField.becomeFirstResponder()
            }
        }
    }

    // MARK: - Interface

    private func buildInterface() {
        let wordmark = WordmarkView(size: 27)
        wordmark.translatesAutoresizingMaskIntoConstraints = false

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        titleLabel.font = Typeface.display(38, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7

        subtitleLabel.font = Typeface.body(15)
        subtitleLabel.textColor = Palette.inkSoft
        subtitleLabel.numberOfLines = 0
        subtitleLabel.setLineHeight(4)

        card.backgroundColor = Palette.card.withAlphaComponent(0.92)

        confirmField.isHidden = true
        let fieldStack = UIStackView(
            axis: .vertical,
            spacing: 22,
            views: [nameField, passwordField, confirmField]
        )
        card.addSubview(fieldStack)
        fieldStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fieldStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            fieldStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            fieldStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            fieldStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])

        errorLabel.font = Typeface.body(12.5, weight: .medium)
        errorLabel.textColor = Palette.terracottaDeep
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        let divider = makeDivider()

        var appleConfig = UIButton.Configuration.filled()
        appleConfig.cornerStyle = .capsule
        appleConfig.baseBackgroundColor = Palette.walnut
        appleConfig.baseForegroundColor = Palette.paper
        appleConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 22)
        var appleContainer = AttributeContainer()
        appleContainer.font = Typeface.chip(16, weight: .bold)
        appleConfig.attributedTitle = AttributedString("Continue with Apple", attributes: appleContainer)
        appleConfig.image = UIImage(
            systemName: "apple.logo",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )
        appleConfig.imagePadding = 9
        let appleButton = UIButton(configuration: appleConfig)
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        appleButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        appleButton.addTarget(self, action: #selector(appleTapped), for: .touchUpInside)

        modeButton.titleLabel?.font = Typeface.chip(14, weight: .semibold)
        modeButton.setTitleColor(Palette.inkSoft, for: .normal)
        modeButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)

        let stack = UIStackView(
            axis: .vertical,
            spacing: 16,
            views: [
                wordmark, eyebrow, titleLabel, subtitleLabel, card,
                errorLabel, primaryButton, divider, appleButton, modeButton
            ]
        )
        stack.setCustomSpacing(20, after: wordmark)
        stack.setCustomSpacing(7, after: eyebrow)
        stack.setCustomSpacing(10, after: titleLabel)
        stack.setCustomSpacing(22, after: subtitleLabel)
        stack.setCustomSpacing(12, after: card)
        stack.setCustomSpacing(18, after: primaryButton)
        stack.setCustomSpacing(18, after: divider)
        stack.setCustomSpacing(20, after: modeButton)
        stack.alignment = .fill

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        configureFooter()
        view.addSubview(footer)
        footer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.gutter),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.gutter + 4),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.gutter - 4),
            scrollView.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -8),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26)
        ])
        footerBottom = footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        footerBottom?.isActive = true

        nameField.textField.textContentType = .username
        passwordField.textField.textContentType = .password
        confirmField.textField.textContentType = .newPassword
    }

    private func makeDivider() -> UIView {
        let container = UIView()
        let left = DividerLine()
        let right = DividerLine()
        let label = UILabel()
        label.text = "or"
        label.font = Typeface.chip(12, weight: .medium)
        label.textColor = Palette.inkFaint
        container.addSubviews(left, right, label)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 20),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            left.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            left.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -12),
            left.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            right.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            right.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            right.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func configureFooter() {
        footer.isEditable = false
        footer.isScrollEnabled = false
        footer.backgroundColor = .clear
        footer.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        footer.linkTextAttributes = [
            .foregroundColor: Palette.terracotta,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        footer.delegate = self

        let text = "By continuing you agree with Terms of Service & Privacy Policy and the EULA."
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 2.5
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: Typeface.body(11, weight: .regular),
                .foregroundColor: Palette.inkFaint,
                .paragraphStyle: paragraph
            ]
        )
        for (phrase, slug) in [
            ("Terms of Service", "terms"),
            ("Privacy Policy", "privacy"),
            ("EULA", "eula")
        ] {
            if let range = text.range(of: phrase) {
                attributed.addAttribute(
                    .link,
                    value: AppLinks.legalURL(for: slug).absoluteString,
                    range: NSRange(range, in: text)
                )
            }
        }
        footer.attributedText = attributed
    }

    // MARK: - Mode

    private func applyMode(animated: Bool) {
        let changes = {
            self.titleLabel.text = self.mode == .signIn ? "Pull up\na stool." : "Join the\nbench."
            self.subtitleLabel.text = self.mode == .signIn
                ? "Good work starts with a seat, a sharp edge and the people around you."
                : "Choose a name, set a password, and keep your pieces and gatherings in one place."
            self.confirmField.isHidden = self.mode == .signIn
            self.primaryButton.setTitle(self.mode == .signIn ? "Sign in" : "Create account", for: .normal)
            self.modeButton.setTitle(
                self.mode == .signIn ? "New here? Create a maker name" : "Already have a name? Sign in",
                for: .normal
            )
            self.errorLabel.isHidden = true
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.transition(with: view, duration: 0.28, options: [.transitionCrossDissolve, .allowAnimatedContent]) {
                changes()
            }
        } else {
            changes()
        }
    }

    @objc private func toggleMode() {
        Haptics.tap()
        mode = mode == .signIn ? .signUp : .signIn
        errorLabel.isHidden = true
        applyMode(animated: true)
    }

    @objc private func closeTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    // MARK: - Actions

    @objc private func primaryTapped() {
        view.endEditing(true)
        errorLabel.isHidden = true

        let name = nameField.text.trimmed
        let password = passwordField.text

        guard !name.isEmpty, !password.isEmpty else {
            showError("A name and a password are both needed.")
            return
        }

        if mode == .signUp {
            guard password == confirmField.text else {
                showError("Those passwords don't match.")
                return
            }
        }

        if mode == .signIn {
            runSignIn(name: name, password: password)
        } else {
            runSignUp(name: name, password: password)
        }
    }

    private func runSignIn(name: String, password: String) {
        primaryButton.isEnabled = false
        Task { @MainActor in
            defer { self.primaryButton.isEnabled = true }
            do {
                try await LoadingVeil.run(message: "Opening the studio…") {
                    _ = try await AuthService.shared.signIn(username: name, password: password)
                }
                StudioStore.shared.refreshAll(force: true)
                self.finishSuccess()
            } catch {
                self.showError(error.localizedDescription)
            }
        }
    }

    private func runSignUp(name: String, password: String) {
        primaryButton.isEnabled = false
        Task { @MainActor in
            defer { self.primaryButton.isEnabled = true }
            do {
                try await LoadingVeil.run(message: "Sweeping the bench…") {
                    _ = try await AuthService.shared.register(username: name, password: password, displayName: nil)
                }
                StudioStore.shared.refreshAll(force: true)
                self.finishSuccess()
            } catch {
                self.showError(error.localizedDescription)
            }
        }
    }

    private func finishSuccess() {
        Haptics.success()
        let action = onSuccess
        dismiss(animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                action?()
            }
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        showToast(message, icon: "exclamationmark")
        Haptics.warn()
    }

    // MARK: - Apple

    @objc private func appleTapped() {
        view.endEditing(true)
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        var name: String?
        if let components = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: components).trimmed
            if !formatted.isEmpty { name = formatted }
        }
        guard
            let tokenData = credential.identityToken,
            let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            showError("Apple didn't return a sign-in token. Please try again.")
            return
        }
        Task { @MainActor in
            do {
                try await LoadingVeil.run(message: "Opening the studio…") {
                    _ = try await AuthService.shared.signInWithApple(
                        identityToken: identityToken,
                        fullName: name
                    )
                }
                StudioStore.shared.refreshAll(force: true)
                self.finishSuccess()
            } catch {
                self.showError(error.localizedDescription)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            return
        }
        showToast("Sign in with Apple isn't available right now.", icon: "exclamationmark")
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        let overlap = max(0, view.bounds.maxY - view.convert(frame, from: nil).minY)
        UIView.animate(withDuration: duration) {
            self.footer.alpha = overlap > 0 ? 0 : 1
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
        }
    }

    @objc private func keyboardWillHide() {
        UIView.animate(withDuration: 0.25) {
            self.footer.alpha = 1
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
}

extension AuthViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard URL.host == "woart.app" else { return true }
        AppLinks.openLegal(URL.pathComponents.last ?? "terms", from: self)
        return false
    }
}
