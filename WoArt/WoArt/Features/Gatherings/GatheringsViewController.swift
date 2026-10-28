import UIKit

final class GatheringsViewController: BaseViewController {
    private let store = StudioStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let listStack = UIStackView()
    private let countLabel = UILabel()

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
        store.refreshAll()
    }

    // MARK: - Layout

    private func build() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Metrics.contentBottomInset, right: 0)
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let wordmark = WordmarkView(size: 28)
        let topRow = UIStackView(axis: .horizontal, spacing: 8, alignment: .center, views: [wordmark])
        topRow.addArrangedSubview(UIView())
        topRow.addArrangedSubview(TagChip(text: "gatherings", index: 2))

        let eyebrow = EyebrowLabel("The calendar", color: Palette.terracotta)
        let title = UILabel()
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 34
        paragraph.maximumLineHeight = 34
        title.attributedText = NSAttributedString(
            string: "Meet at\nthe bench.",
            attributes: [
                .font: Typeface.display(34, weight: .bold),
                .foregroundColor: Palette.ink,
                .paragraphStyle: paragraph
            ]
        )
        title.numberOfLines = 0

        let subtitle = UILabel()
        subtitle.text = "Small rooms, real tools, and makers who will show you the cut."
        subtitle.font = Typeface.body(13)
        subtitle.textColor = Palette.inkSoft
        subtitle.numberOfLines = 0
        subtitle.setLineHeight(3)

        countLabel.font = Typeface.chip(11, weight: .medium)
        countLabel.textColor = Palette.inkFaint

        let listTitle = UILabel()
        listTitle.text = "Coming up"
        listTitle.font = Typeface.display(21, weight: .bold)
        listTitle.textColor = Palette.ink

        let titleRow = UIStackView(axis: .horizontal, spacing: 10, alignment: .bottom, views: [listTitle])
        titleRow.addArrangedSubview(UIView())
        titleRow.addArrangedSubview(countLabel)

        listStack.axis = .vertical
        listStack.spacing = 10

        let hostHint = UILabel()
        hostHint.text = "Use the centre button to open your own room."
        hostHint.font = Typeface.body(11.5, weight: .medium)
        hostHint.textColor = Palette.inkFaint
        hostHint.numberOfLines = 0
        hostHint.textAlignment = .center

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.addArrangedSubview(topRow)
        contentStack.addArrangedSubview(eyebrow)
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(subtitle)
        contentStack.addArrangedSubview(titleRow)
        contentStack.addArrangedSubview(listStack)
        contentStack.addArrangedSubview(hostHint)
        contentStack.setCustomSpacing(18, after: topRow)
        contentStack.setCustomSpacing(7, after: eyebrow)
        contentStack.setCustomSpacing(8, after: title)
        contentStack.setCustomSpacing(18, after: subtitle)
        contentStack.setCustomSpacing(8, after: titleRow)
        contentStack.setCustomSpacing(20, after: listStack)

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

    // MARK: - Data

    @objc private func render() {
        listStack.arrangedSubviews.forEach {
            listStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let events = store.upcomingEvents
        countLabel.text = "\(events.count) \(events.count == 1 ? "gathering" : "gatherings")"

        if events.isEmpty {
            let empty = EmptyStateView(
                title: "No rooms open",
                message: "Open the first gathering and invite a few makers to the bench."
            )
            empty.heightAnchor.constraint(equalToConstant: 260).isActive = true
            listStack.addArrangedSubview(empty)
            return
        }

        for event in events {
            let row = GatheringRow(event: event, host: store.maker(id: event.hostID), seatsLeft: store.seatsLeft(for: event))
            row.onOpen = { [weak self] in
                let detail = EventDetailViewController(eventID: event.id)
                self?.navigationController?.pushViewController(detail, animated: true)
            }
            listStack.addArrangedSubview(row)
        }
    }
}

private final class GatheringRow: UIControl {
    var onOpen: (() -> Void)?

    private let card = CardView(radius: 22)
    private let poster = ArtworkView()
    private let dateLabel = EyebrowLabel("", color: Palette.terracotta, size: 8.5)
    private let titleLabel = UILabel()
    private let hostLabel = UILabel()
    private let chevron = UIImageView()

    init(event: StudioEvent, host: Maker?, seatsLeft: Int) {
        super.init(frame: .zero)

        card.isUserInteractionEnabled = false
        addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.pinEdges(to: self)

        poster.layer.cornerRadius = 16
        poster.layer.cornerCurve = .continuous
        poster.clipsToBounds = true
        poster.configure(assetName: event.posterAsset, fileName: event.posterFile, remoteURL: event.posterRemoteURL)
        poster.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(poster)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE · MMM d · h:mm a"
        dateLabel.attributedText = NSAttributedString(
            string: formatter.string(from: event.date).uppercased(),
            attributes: [
                .font: Typeface.eyebrow(8.5),
                .kern: 1.2,
                .foregroundColor: Palette.terracotta
            ]
        )

        titleLabel.text = event.title
        titleLabel.font = Typeface.display(18.5, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        let hostName = host?.name ?? "WoArt"
        let seatText = seatsLeft == 0 ? "Full" : "\(seatsLeft) seats left"
        hostLabel.text = "\(hostName)  ·  \(seatText)  ·  \(event.location)"
        hostLabel.font = Typeface.body(10.5, weight: .medium)
        hostLabel.textColor = Palette.inkFaint
        hostLabel.numberOfLines = 1
        hostLabel.lineBreakMode = .byTruncatingTail

        let textStack = UIStackView(axis: .vertical, spacing: 4, views: [dateLabel, titleLabel, hostLabel])
        textStack.setCustomSpacing(3, after: dateLabel)
        textStack.setCustomSpacing(3, after: titleLabel)
        textStack.isUserInteractionEnabled = false

        chevron.image = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        )
        chevron.tintColor = Palette.inkFaint
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 12).isActive = true

        card.addSubviews(textStack, chevron)
        NSLayoutConstraint.activate([
            poster.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            poster.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            poster.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            poster.widthAnchor.constraint(equalToConstant: 92),
            poster.heightAnchor.constraint(equalToConstant: 80),

            textStack.leadingAnchor.constraint(equalTo: poster.trailingAnchor, constant: 12),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -10),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(released), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        Haptics.tap()
        onOpen?()
    }

    @objc private func pressed() {
        UIView.animate(withDuration: 0.12) {
            self.card.transform = CGAffineTransform(scaleX: 0.985, y: 0.985)
        }
    }

    @objc private func released() {
        UIView.animate(withDuration: 0.2) {
            self.card.transform = .identity
        }
    }
}
