import UIKit

final class HomeMastheadCell: UICollectionViewCell {
    static let reuseID = "HomeMasthead"

    var onOpenProfile: (() -> Void)?

    private let avatar = ArtworkView()
    private let dateLabel = EyebrowLabel("Today", color: Palette.inkFaint)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statLabel = EyebrowLabel("", color: Palette.inkSoft, size: 9)
    private let eventsTitle = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        let wordmark = WordmarkView(size: 28)

        avatar.layer.cornerRadius = 19
        avatar.layer.borderWidth = 1.5
        avatar.layer.borderColor = Palette.card.cgColor
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 38).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 38).isActive = true
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))

        let topRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [wordmark])
        topRow.addArrangedSubview(UIView())
        topRow.addArrangedSubview(avatar)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEEE · MMM d"
        dateLabel.attributedText = NSAttributedString(
            string: dateFormatter.string(from: Date()).uppercased(),
            attributes: [
                .font: Typeface.eyebrow(10),
                .kern: 2,
                .foregroundColor: Palette.terracotta
            ]
        )

        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82
        titleLabel.text = "The bench is warm today."
        titleLabel.font = Typeface.display(30, weight: .bold)
        titleLabel.textColor = Palette.ink

        subtitleLabel.text = "Gatherings, field notes and quiet work from the atelier."
        subtitleLabel.font = Typeface.body(13)
        subtitleLabel.textColor = Palette.inkSoft
        subtitleLabel.numberOfLines = 0

        let rule = UIView()
        rule.backgroundColor = Palette.brass.withAlphaComponent(0.55)
        rule.translatesAutoresizingMaskIntoConstraints = false
        rule.widthAnchor.constraint(equalToConstant: 26).isActive = true
        rule.heightAnchor.constraint(equalToConstant: 2).isActive = true

        let statRow = UIStackView(axis: .horizontal, spacing: 10, alignment: .center, views: [rule, statLabel])

        let gatherEyebrow = EyebrowLabel("Gather", color: Palette.terracotta)
        eventsTitle.text = "Upcoming at the bench"
        eventsTitle.font = Typeface.display(20, weight: .bold)
        eventsTitle.textColor = Palette.ink
        eventsTitle.numberOfLines = 0

        let gatherStack = UIStackView(axis: .vertical, spacing: 4, views: [gatherEyebrow, eventsTitle])

        let stack = UIStackView(
            axis: .vertical,
            spacing: 11,
            views: [topRow, dateLabel, titleLabel, subtitleLabel, statRow, gatherStack]
        )
        stack.setCustomSpacing(16, after: topRow)
        stack.setCustomSpacing(7, after: dateLabel)
        stack.setCustomSpacing(9, after: titleLabel)
        stack.setCustomSpacing(14, after: subtitleLabel)
        stack.setCustomSpacing(18, after: statRow)

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    func update(store: StudioStore) {
        let maker = store.currentMaker
        let signedIn = AuthService.shared.isSignedIn
        avatar.configure(
            assetName: signedIn ? maker.avatarAsset : "avatar_guest",
            fileName: signedIn ? maker.avatarFile : nil,
            remoteURL: signedIn ? maker.avatarRemoteURL : nil,
            avatar: true,
            monogram: signedIn ? maker.name : nil
        )
        statLabel.attributedText = NSAttributedString(
            string: "\(store.upcomingEvents.count) GATHERINGS  ·  \(store.feed.count) PIECES  ·  \(store.state.makers.count) MAKERS",
            attributes: [
                .font: Typeface.eyebrow(9),
                .kern: 1.3,
                .foregroundColor: Palette.inkSoft
            ]
        )
    }

    @objc private func profileTapped() { onOpenProfile?() }
}

final class HomeFeedHeaderView: UICollectionReusableView {
    static let reuseID = "HomeFeedHeader"

    private let countLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let eyebrow = EyebrowLabel("The bench", color: Palette.terracotta)
        let title = UILabel()
        title.text = "Fresh from the workshop"
        title.font = Typeface.display(22, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        countLabel.font = Typeface.chip(11, weight: .medium)
        countLabel.textColor = Palette.inkFaint

        let titleRow = UIStackView(axis: .horizontal, spacing: 12, alignment: .bottom, views: [title])
        titleRow.addArrangedSubview(UIView())
        titleRow.addArrangedSubview(countLabel)

        let stack = UIStackView(axis: .vertical, spacing: 5, views: [eyebrow, titleRow])
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.gutter),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.gutter),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(count: Int) {
        countLabel.text = "\(count) pieces"
    }
}

final class FeedEmptyCell: UICollectionViewCell {
    static let reuseID = "FeedEmptyCell"

    private let stateView = EmptyStateView(
        title: "The bench is quiet",
        message: "Be the first to share a piece. A photo, a film, or a few lines from the workshop."
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(stateView)
        stateView.translatesAutoresizingMaskIntoConstraints = false
        stateView.pinEdges(to: contentView)
        NSLayoutConstraint.activate([
            stateView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
