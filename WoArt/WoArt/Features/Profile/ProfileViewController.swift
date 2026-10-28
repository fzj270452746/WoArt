import UIKit

final class ProfileViewController: BaseViewController {
    private let store = StudioStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
        render()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(render),
            name: .studioDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(render),
            name: .authDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
        store.refreshAll()
    }

    private func build() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Metrics.contentBottomInset, right: 0)
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.spacing = 16
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 6),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Metrics.gutter),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Metrics.gutter),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Metrics.gutter * 2)
        ])
    }

    @objc private func render() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let wordmark = WordmarkView(size: 28)
        let topRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [wordmark])
        topRow.addArrangedSubview(UIView())
        topRow.addArrangedSubview(TagChip(text: AuthService.shared.isSignedIn ? "maker" : "guest", index: 3))
        contentStack.addArrangedSubview(topRow)
        contentStack.setCustomSpacing(24, after: topRow)

        if AuthService.shared.isSignedIn {
            buildSignedIn()
        } else {
            buildSignedOut()
        }
    }

    // MARK: - Signed in

    private func buildSignedIn() {
        let profile = store.currentProfile
        let myPosts = store.posts(by: StudioNamespace.currentUserID)
        let myEvents = store.events(hostedBy: StudioNamespace.currentUserID)
        let following = store.followingMakers
        let likes = store.likedPosts

        let eyebrow = EyebrowLabel("Your bench", color: Palette.terracotta)
        let name = UILabel()
        name.text = profile.displayName
        name.font = Typeface.display(30, weight: .bold)
        name.textColor = Palette.ink
        name.numberOfLines = 0

        let handle = UILabel()
        handle.text = "@\(profile.handle)"
        handle.font = Typeface.chip(12, weight: .medium)
        handle.textColor = Palette.inkFaint

        let meta = UILabel()
        meta.text = [profile.craft, profile.location].filter { !$0.isEmpty }.joined(separator: "  ·  ")
        meta.font = Typeface.body(11.5, weight: .medium)
        meta.textColor = Palette.inkSoft
        meta.numberOfLines = 1

        let bio = UILabel()
        bio.text = profile.bio
        bio.font = Typeface.body(13)
        bio.textColor = Palette.inkSoft
        bio.numberOfLines = 0
        bio.setLineHeight(4)
        bio.isHidden = profile.bio.isEmpty

        let identityStack = UIStackView(axis: .vertical, spacing: 4, views: [name, handle, meta, bio])
        identityStack.setCustomSpacing(2, after: name)
        identityStack.setCustomSpacing(10, after: meta)

        let avatar = ArtworkView()
        avatar.layer.cornerRadius = 37
        avatar.layer.borderWidth = 2
        avatar.layer.borderColor = Palette.card.cgColor
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editProfile)))
        avatar.configure(
            assetName: profile.avatarAsset,
            fileName: profile.avatarFile,
            remoteURL: profile.avatarRemoteURL,
            avatar: true,
            monogram: profile.displayName
        )
        avatar.widthAnchor.constraint(equalToConstant: 74).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 74).isActive = true

        let edit = CircleIconButton(symbol: "pencil", diameter: 38, background: Palette.cream, pointSize: 14)
        edit.addTarget(self, action: #selector(editProfile), for: .touchUpInside)

        let headerCard = CardView(radius: 28)
        let headerRow = UIStackView(axis: .horizontal, spacing: 14, alignment: .center, views: [avatar, identityStack, edit])
        headerCard.addSubview(headerRow)
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRow.pinEdges(to: headerCard, insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))

        let headerStack = UIStackView(axis: .vertical, spacing: 8, views: [eyebrow, headerCard])
        contentStack.addArrangedSubview(headerStack)
        contentStack.setCustomSpacing(18, after: headerStack)

        let stats = CardView(radius: 24)
        let statsRow = UIStackView(axis: .horizontal, alignment: .center, distribution: .fillEqually)
        statsRow.addArrangedSubview(StatColumnView(value: "\(following.count)", label: "Following"))
        statsRow.addArrangedSubview(
            StatColumnView(value: "\(store.currentMaker.followers)", label: "Followers")
        )
        statsRow.addArrangedSubview(StatColumnView(value: "\(myEvents.count)", label: "Hosted"))
        statsRow.addArrangedSubview(StatColumnView(value: "\(myPosts.count)", label: "Pieces"))
        stats.addSubview(statsRow)
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        statsRow.pinEdges(to: stats, insets: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8))
        contentStack.addArrangedSubview(stats)
        contentStack.setCustomSpacing(22, after: stats)

        let studioEyebrow = EyebrowLabel("Your studio", color: Palette.terracotta)
        contentStack.addArrangedSubview(studioEyebrow)

        let menuCard = CardView(radius: 26)
        let menuStack = UIStackView(axis: .vertical, spacing: 0)
        let rows: [(String, String, String, () -> Void)] = [
            ("square.stack", "My pieces", "\(myPosts.count)", { [weak self] in self?.open(MyWorksViewController()) }),
            ("heart", "Liked pieces", "\(likes.count)", { [weak self] in self?.open(MyLikesViewController()) }),
            ("person.2", "Following", "\(following.count)", { [weak self] in self?.open(MyFollowingViewController()) }),
            ("calendar", "Hosted gatherings", "\(myEvents.count)", { [weak self] in self?.open(MyEventsViewController()) }),
            ("info.circle", "About WoArt", "", { [weak self] in self?.open(AboutViewController()) })
        ]
        for (index, row) in rows.enumerated() {
            if index > 0 {
                menuStack.addArrangedSubview(DividerLine())
            }
            menuStack.addArrangedSubview(
                ProfileMenuRow(
                    symbol: row.0,
                    title: row.1,
                    detail: row.2.isEmpty ? nil : row.2,
                    tint: index == 1 ? Palette.terracotta : Palette.inkSoft,
                    action: row.3
                )
            )
        }
        menuCard.addSubview(menuStack)
        menuStack.translatesAutoresizingMaskIntoConstraints = false
        menuStack.pinEdges(to: menuCard, insets: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        contentStack.addArrangedSubview(menuCard)
        contentStack.setCustomSpacing(28, after: menuCard)

        let signOut = UIButton(type: .system)
        signOut.setTitle("Sign out", for: .normal)
        signOut.setTitleColor(Palette.inkSoft, for: .normal)
        signOut.titleLabel?.font = Typeface.chip(14, weight: .semibold)
        signOut.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        signOut.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let delete = UIButton(type: .system)
        delete.setTitle("Delete account", for: .normal)
        delete.setTitleColor(Palette.terracottaDeep, for: .normal)
        delete.titleLabel?.font = Typeface.chip(13, weight: .medium)
        delete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        delete.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let accountStack = UIStackView(axis: .vertical, spacing: 2, alignment: .center, views: [signOut, delete])
        contentStack.addArrangedSubview(accountStack)

        let version = UILabel()
        version.text = "WoArt · v1.0"
        version.font = Typeface.eyebrow(8)
        version.textColor = Palette.inkFaint.withAlphaComponent(0.7)
        version.textAlignment = .center
        contentStack.addArrangedSubview(version)
        contentStack.setCustomSpacing(6, after: accountStack)
    }

    // MARK: - Signed out

    private func buildSignedOut() {
        let eyebrow = EyebrowLabel("Your bench", color: Palette.terracotta)
        let title = UILabel()
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 34
        paragraph.maximumLineHeight = 34
        title.attributedText = NSAttributedString(
            string: "Keep your\nwork together.",
            attributes: [
                .font: Typeface.display(34, weight: .bold),
                .foregroundColor: Palette.ink,
                .paragraphStyle: paragraph
            ]
        )
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = "Pieces, gatherings and field notes in one quiet place."
        subtitle.font = Typeface.body(13)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0
        subtitle.setLineHeight(4)

        let rings = RingMotifView()

        let card = CardView(radius: 28)
        let cardTitle = UILabel()
        cardTitle.text = "Sign in or make a name"
        cardTitle.font = Typeface.display(22, weight: .bold)
        cardTitle.textColor = Palette.ink
        cardTitle.numberOfLines = 0

        let cardText = UILabel()
        cardText.text = "Your Bench stays on this device. Shared pieces, gatherings and comments live with the WoArt community; the tools are always open, with or without an account."
        cardText.font = Typeface.body(12.5)
        cardText.textColor = Palette.inkSoft
        cardText.numberOfLines = 0
        cardText.setLineHeight(3)

        let signIn = PillButton(title: "Sign in", style: .primary, height: 48)
        signIn.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        let create = PillButton(title: "Create an account", style: .outline, height: 46)
        create.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        let benefits = UIStackView(axis: .vertical, spacing: 8, views: [
            benefit("square.stack", "Keep your pieces and their notes"),
            benefit("calendar", "Manage the gatherings you host"),
            benefit("person.2", "Follow the makers you admire")
        ])

        let stack = UIStackView(
            axis: .vertical,
            spacing: 14,
            views: [cardTitle, cardText, signIn, create, benefits]
        )
        stack.setCustomSpacing(10, after: cardTitle)
        stack.setCustomSpacing(20, after: cardText)
        stack.setCustomSpacing(18, after: create)
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: card, insets: UIEdgeInsets(top: 22, left: 20, bottom: 22, right: 20))

        let footer = UILabel()
        footer.text = "The five workshop tools never require an account."
        footer.font = Typeface.body(11, weight: .medium)
        footer.textColor = Palette.inkFaint
        footer.textAlignment = .center
        footer.numberOfLines = 0

        contentStack.addArrangedSubview(eyebrow)
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(subtitle)
        contentStack.addArrangedSubview(rings)
        contentStack.addArrangedSubview(card)
        contentStack.addArrangedSubview(footer)
        contentStack.setCustomSpacing(8, after: eyebrow)
        contentStack.setCustomSpacing(12, after: title)
        contentStack.setCustomSpacing(18, after: subtitle)
        contentStack.setCustomSpacing(0, after: rings)
        contentStack.setCustomSpacing(22, after: card)
    }

    private func benefit(_ symbol: String, _ text: String) -> UIView {
        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            )
        )
        icon.tintColor = Palette.brass
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let label = UILabel()
        label.text = text
        label.font = Typeface.body(11.5, weight: .medium)
        label.textColor = Palette.inkSoft

        return UIStackView(axis: .horizontal, spacing: 10, alignment: .center, views: [icon, label])
    }

    // MARK: - Actions

    private func open(_ controller: UIViewController) {
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func editProfile() {
        Haptics.tap()
        open(EditProfileViewController())
    }

    @objc private func signInTapped() {
        AuthGate.requireLogin(from: self)
    }

    @objc private func createTapped() {
        let auth = AuthViewController()
        auth.initialMode = .signUp
        auth.modalPresentationStyle = .fullScreen
        present(auth, animated: true)
    }

    @objc private func signOutTapped() {
        ConfirmSheetViewController.present(
            from: self,
            title: "Sign out of WoArt?",
            message: "Your pieces stay in the community. You can sign back in whenever you like.",
            confirmTitle: "Sign out"
        ) { [weak self] in
            guard let self else { return }
            LoadingVeil.show(message: "Closing the studio…") {
                AuthService.shared.signOut()
                self.render()
            }
        }
    }

    @objc private func deleteTapped() {
        ConfirmSheetViewController.present(
            from: self,
            title: "Delete this account?",
            message: "Your profile, pieces, comments, likes and reservations will be removed from WoArt. This cannot be undone.",
            confirmTitle: "Delete account",
            destructive: true
        ) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                do {
                    try await LoadingVeil.run(message: "Clearing the bench…") {
                        try await StudioStore.shared.deleteAccount()
                    }
                    self.render()
                    self.showToast("Account deleted", icon: "trash")
                } catch {
                    Haptics.warn()
                    self.showToast(error.localizedDescription, icon: "exclamationmark")
                }
            }
        }
    }
}

private final class RingMotifView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 96).isActive = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for index in 0..<7 {
            let radius = 14 + CGFloat(index) * 11
            context.setStrokeColor(
                (index % 2 == 0 ? Palette.terracotta : Palette.ink)
                    .withAlphaComponent(0.06 + CGFloat(index) * 0.012)
                    .cgColor
            )
            context.setLineWidth(index == 0 ? 2 : 1)
            context.strokeEllipse(
                in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius * 0.66,
                    width: radius * 2,
                    height: radius * 1.32
                )
            )
        }
        context.setFillColor(Palette.brass.withAlphaComponent(0.85).cgColor)
        context.fillEllipse(in: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
    }
}
