import UIKit

final class EventDetailViewController: BaseViewController {
    private let eventID: String
    private let store = StudioStore.shared
    private let scrollView = UIScrollView()
    private let topBar = DetailTopBar()
    private let poster = ArtworkView()
    private let titleLabel = UILabel()
    private let eyebrow = EyebrowLabel("")
    private let hostRow = UIControl()
    private let hostAvatar = ArtworkView()
    private let hostName = UILabel()
    private let hostCraft = UILabel()
    private let detailsLabel = UILabel()
    private let infoStack = UIStackView()
    private let tagRow = UIStackView()
    private let seatsLabel = UILabel()
    private let actionButton = PillButton(title: "Reserve a seat", style: .primary, height: 54)
    private let bottomBar = UIView()
    private let dateBadge = UIView()
    private let monthLabel = UILabel()
    private let dayLabel = UILabel()
    private var isHostEvent = false

    override var hidesDock: Bool { true }

    init(eventID: String) {
        self.eventID = eventID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
        if store.event(id: eventID) != nil {
            render()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .studioDidChange,
            object: nil
        )

        Task { @MainActor in
            do {
                try await store.loadEvent(id: eventID)
                if store.event(id: eventID) != nil {
                    render()
                } else {
                    navigationController?.popViewController(animated: true)
                }
            } catch {
                if store.event(id: eventID) == nil {
                    showToast(error.localizedDescription, icon: "exclamationmark")
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func build() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 160, right: 0)
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        poster.layer.cornerRadius = 32
        poster.layer.cornerCurve = .continuous
        poster.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        poster.clipsToBounds = true
        scrollView.addSubview(poster)
        poster.translatesAutoresizingMaskIntoConstraints = false

        let topShade = UIView()
        topShade.isUserInteractionEnabled = false
        let topGradient = GradientView(
            colors: [Palette.paper.withAlphaComponent(0.7), UIColor.clear]
        )
        topShade.addSubview(topGradient)
        topGradient.translatesAutoresizingMaskIntoConstraints = false
        topGradient.pinEdges(to: topShade)
        poster.addSubview(topShade)
        topShade.pinEdges(to: poster)

        dateBadge.backgroundColor = UIColor(hex: 0xFFF9EE, alpha: 0.96)
        dateBadge.layer.cornerRadius = 30
        dateBadge.layer.cornerCurve = .continuous
        dateBadge.layer.shadowColor = UIColor.black.cgColor
        dateBadge.layer.shadowOpacity = 0.14
        dateBadge.layer.shadowRadius = 16
        dateBadge.layer.shadowOffset = CGSize(width: 0, height: 6)
        poster.addSubview(dateBadge)
        dateBadge.translatesAutoresizingMaskIntoConstraints = false

        monthLabel.font = Typeface.eyebrow(9)
        monthLabel.textColor = Palette.terracotta
        monthLabel.textAlignment = .center
        dayLabel.font = Typeface.display(26, weight: .bold)
        dayLabel.textColor = Palette.ink
        dayLabel.textAlignment = .center
        let dateStack = UIStackView(axis: .vertical, spacing: -2, alignment: .center, views: [monthLabel, dayLabel])
        dateBadge.addSubview(dateStack)
        dateStack.pinEdges(to: dateBadge, insets: UIEdgeInsets(top: 8, left: 2, bottom: 6, right: 2))

        NSLayoutConstraint.activate([
            poster.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            poster.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            poster.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            poster.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            poster.heightAnchor.constraint(equalToConstant: 290),

            dateBadge.leadingAnchor.constraint(equalTo: poster.leadingAnchor, constant: 20),
            dateBadge.bottomAnchor.constraint(equalTo: poster.bottomAnchor, constant: -48),
            dateBadge.widthAnchor.constraint(equalToConstant: 54),
            dateBadge.heightAnchor.constraint(equalToConstant: 54)
        ])

        let sheet = UIView()
        sheet.backgroundColor = Palette.card
        sheet.layer.cornerRadius = 32
        sheet.layer.cornerCurve = .continuous
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.applySoftShadow(opacity: 0.08, radius: 20, y: -4)
        scrollView.addSubview(sheet)
        sheet.translatesAutoresizingMaskIntoConstraints = false

        eyebrow.textColor = Palette.terracotta
        titleLabel.font = Typeface.display(29, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0

        hostAvatar.layer.cornerRadius = 22
        hostAvatar.clipsToBounds = true
        hostAvatar.isUserInteractionEnabled = false
        hostAvatar.translatesAutoresizingMaskIntoConstraints = false
        hostAvatar.widthAnchor.constraint(equalToConstant: 44).isActive = true
        hostAvatar.heightAnchor.constraint(equalToConstant: 44).isActive = true

        hostName.font = Typeface.chip(14.5, weight: .bold)
        hostName.textColor = Palette.ink
        hostCraft.font = Typeface.body(11.5)
        hostCraft.textColor = Palette.inkFaint
        let hostText = UIStackView(axis: .vertical, spacing: 2, views: [hostName, hostCraft])
        hostText.isUserInteractionEnabled = false

        let chevron = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
            )
        )
        chevron.tintColor = Palette.inkFaint
        chevron.isUserInteractionEnabled = false

        hostRow.addSubviews(hostAvatar, hostText, chevron)
        NSLayoutConstraint.activate([
            hostAvatar.leadingAnchor.constraint(equalTo: hostRow.leadingAnchor),
            hostAvatar.centerYAnchor.constraint(equalTo: hostRow.centerYAnchor),
            hostText.leadingAnchor.constraint(equalTo: hostAvatar.trailingAnchor, constant: 12),
            hostText.topAnchor.constraint(equalTo: hostRow.topAnchor),
            hostText.bottomAnchor.constraint(equalTo: hostRow.bottomAnchor),
            chevron.trailingAnchor.constraint(equalTo: hostRow.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: hostRow.centerYAnchor)
        ])
        hostRow.addTarget(self, action: #selector(hostTapped), for: .touchUpInside)

        let hairline = DividerLine()

        detailsLabel.font = Typeface.body(15)
        detailsLabel.textColor = Palette.inkSoft
        detailsLabel.numberOfLines = 0
        detailsLabel.setLineHeight(6)

        infoStack.axis = .vertical
        infoStack.spacing = 14

        tagRow.axis = .horizontal
        tagRow.spacing = 7

        let bottomSpacer = UIView()
        bottomSpacer.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        bottomSpacer.setContentCompressionResistancePriority(UILayoutPriority(1), for: .vertical)

        let stack = UIStackView(
            axis: .vertical,
            spacing: 18,
            views: [eyebrow, titleLabel, hostRow, hairline, detailsLabel, infoStack, tagRow, bottomSpacer]
        )
        stack.setCustomSpacing(7, after: eyebrow)
        stack.setCustomSpacing(14, after: titleLabel)
        stack.setCustomSpacing(22, after: hostRow)
        stack.setCustomSpacing(22, after: hairline)
        sheet.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sheet.topAnchor.constraint(equalTo: poster.bottomAnchor, constant: -26),
            sheet.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            sheet.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            sheet.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            sheet.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.66),

            stack.topAnchor.constraint(equalTo: sheet.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: sheet.bottomAnchor, constant: -26)
        ])

        bottomBar.backgroundColor = Palette.paper.withAlphaComponent(0.97)
        bottomBar.layer.shadowColor = UIColor(hex: 0x3A2114).cgColor
        bottomBar.layer.shadowOpacity = 0.1
        bottomBar.layer.shadowRadius = 20
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -6)
        view.addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        seatsLabel.font = Typeface.chip(11.5, weight: .medium)
        seatsLabel.textColor = Palette.inkSoft
        seatsLabel.textAlignment = .center

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        bottomBar.addSubviews(seatsLabel, actionButton)
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -88),

            seatsLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            seatsLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 24),
            seatsLabel.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -24),

            actionButton.topAnchor.constraint(equalTo: seatsLabel.bottomAnchor, constant: 7),
            actionButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -24)
        ])

        topBar.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        view.addSubview(topBar)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])
    }

    private func render() {
        guard let event = store.event(id: eventID) else {
            navigationController?.popViewController(animated: true)
            return
        }
        let host = store.maker(id: event.hostID)
        isHostEvent = event.hostID == StudioNamespace.currentUserID

        poster.configure(assetName: event.posterAsset, fileName: event.posterFile, remoteURL: event.posterRemoteURL)
        monthLabel.text = event.date.monthAbbreviation
        dayLabel.text = event.date.dayNumber

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d · h:mm a"
        eyebrow.attributedText = NSAttributedString(
            string: formatter.string(from: event.date).uppercased(),
            attributes: [
                .font: Typeface.eyebrow(10),
                .kern: 1.6,
                .foregroundColor: Palette.terracotta
            ]
        )
        titleLabel.text = event.title
        hostName.text = isHostEvent ? "Hosted by you" : (host?.name ?? "WoArt")
        hostCraft.text = isHostEvent ? "Your gathering" : (host?.craft ?? "")
        if let host {
            hostAvatar.configure(
                assetName: host.avatarAsset,
                fileName: host.avatarFile,
                remoteURL: host.avatarRemoteURL,
                avatar: true,
                monogram: host.name
            )
        }
        hostRow.isHidden = isHostEvent
        detailsLabel.text = event.details

        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        infoStack.addArrangedSubview(
            infoRow(symbol: "calendar", title: "When", value: formatter.string(from: event.date))
        )
        infoStack.addArrangedSubview(
            infoRow(symbol: "mappin.and.ellipse", title: "Where", value: event.location)
        )
        infoStack.addArrangedSubview(
            infoRow(
                symbol: "person.2",
                title: "Place",
                value: "\(event.capacity) makers · \(store.reservedCount(for: event)) places taken"
            )
        )

        tagRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, tag) in event.tags.enumerated() {
            tagRow.addArrangedSubview(TagChip(text: tag, index: index))
        }
        tagRow.addArrangedSubview(UIView())
        tagRow.isHidden = event.tags.isEmpty

        seatsLabel.text = "\(store.reservedCount(for: event)) of \(event.capacity) places taken"
        actionButton.isHidden = false
        seatsLabel.isHidden = isHostEvent

        if isHostEvent {
            actionButton.setTitle("Delete gathering", for: .normal)
        } else if store.isReserved(event.id) {
            actionButton.setTitle("You're on the list", for: .normal)
        } else if store.seatsLeft(for: event) == 0 {
            actionButton.setTitle("Gathering is full", for: .normal)
        } else {
            actionButton.setTitle("Reserve a seat", for: .normal)
        }
    }

    private func infoRow(symbol: String, title: String, value: String) -> UIView {
        let circle = UIView()
        circle.backgroundColor = Palette.cream
        circle.layer.cornerRadius = 17
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 34).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let icon = UIImageView(
            image: UIImage(
                systemName: symbol,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            )
        )
        icon.tintColor = Palette.inkSoft
        circle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor).isActive = true
        icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title.uppercased()
        titleLabel.font = Typeface.eyebrow(8.5)
        titleLabel.textColor = Palette.inkFaint

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = Typeface.body(13.5, weight: .medium)
        valueLabel.textColor = Palette.ink
        valueLabel.numberOfLines = 0

        let textStack = UIStackView(axis: .vertical, spacing: 2, views: [titleLabel, valueLabel])
        let row = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, views: [circle, textStack])
        return row
    }

    @objc private func dataChanged() {
        guard store.event(id: eventID) != nil else {
            navigationController?.popViewController(animated: true)
            return
        }
        render()
    }

    @objc private func hostTapped() {
        guard let event = store.event(id: eventID) else { return }
        let profile = MakerProfileViewController(makerID: event.hostID)
        navigationController?.pushViewController(profile, animated: true)
    }

    @objc private func actionTapped() {
        guard let event = store.event(id: eventID) else { return }
        if isHostEvent {
            ConfirmSheetViewController.present(
                from: self,
                title: "Delete this gathering?",
                message: "This removes the gathering and any places already reserved. This cannot be undone.",
                confirmTitle: "Delete gathering",
                destructive: true
            ) { [weak self] in
                self?.store.deleteEvent(id: self?.eventID ?? "")
                self?.navigationController?.popViewController(animated: true)
                self?.showToast("Gathering removed", icon: "trash")
            }
            return
        }

        if store.isReserved(event.id) {
            ConfirmSheetViewController.present(
                from: self,
                title: "Give up your place?",
                message: "Your seat will be released for another maker.",
                confirmTitle: "Cancel reservation",
                destructive: true
            ) { [weak self] in
                self?.store.cancelReservation(eventID: self?.eventID ?? "")
                self?.render()
                self?.showToast("Reservation cancelled", icon: "arrow.uturn.left")
            }
            return
        }

        guard store.seatsLeft(for: event) > 0 else {
            showToast("This gathering is full.", icon: "exclamationmark")
            return
        }

        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.reserve()
        }) else { return }
        reserve()
    }

    private func reserve() {
        store.reserve(eventID: eventID)
        Haptics.success()
        render()
        showToast("Seat reserved. See you at the bench.", icon: "checkmark")
    }
}
