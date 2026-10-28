import UIKit

final class EventCardCell: UICollectionViewCell {
    static let reuseID = "EventCardCell"

    var onOpen: (() -> Void)?

    private let poster = ArtworkView()
    private let shade = UIView()
    private let dateBadge = UIView()
    private let monthLabel = UILabel()
    private let dayLabel = UILabel()
    private let seatPill = MediaOverlayPill()
    private let hostLabel = EyebrowLabel("Host", color: Palette.brassLight, size: 9)
    private let titleLabel = UILabel()
    private let locationLabel = UILabel()
    private let arrowCircle = UIView()
    private var event: StudioEvent?

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        contentView.backgroundColor = .clear
        poster.layer.cornerRadius = 24
        poster.layer.cornerCurve = .continuous
        poster.clipsToBounds = true
        contentView.addSubview(poster)
        poster.translatesAutoresizingMaskIntoConstraints = false
        poster.pinEdges(to: contentView)

        poster.layer.borderWidth = 1
        poster.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor

        shade.backgroundColor = .clear
        shade.isUserInteractionEnabled = false
        poster.addSubviews(shade)
        shade.pinEdges(to: poster)
        let gradient = GradientView(
            colors: [UIColor.clear, Palette.walnut.withAlphaComponent(0.9)],
            locations: [0.32, 1]
        )
        shade.addSubview(gradient)
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.pinEdges(to: shade)

        dateBadge.backgroundColor = UIColor(hex: 0xFFF9EE, alpha: 0.95)
        dateBadge.layer.cornerRadius = 26
        dateBadge.layer.cornerCurve = .continuous
        poster.addSubview(dateBadge)
        dateBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateBadge.leadingAnchor.constraint(equalTo: poster.leadingAnchor, constant: 10),
            dateBadge.topAnchor.constraint(equalTo: poster.topAnchor, constant: 10),
            dateBadge.widthAnchor.constraint(equalToConstant: 40),
            dateBadge.heightAnchor.constraint(equalToConstant: 40)
        ])

        monthLabel.font = Typeface.eyebrow(7)
        monthLabel.textColor = Palette.terracotta
        monthLabel.textAlignment = .center
        dayLabel.font = Typeface.display(16, weight: .bold)
        dayLabel.textColor = Palette.ink
        dayLabel.textAlignment = .center

        let dateStack = UIStackView(axis: .vertical, spacing: -2, alignment: .center, views: [monthLabel, dayLabel])
        dateBadge.addSubview(dateStack)
        dateStack.pinEdges(to: dateBadge, insets: UIEdgeInsets(top: 6, left: 2, bottom: 4, right: 2))

        poster.addSubview(seatPill)
        seatPill.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            seatPill.trailingAnchor.constraint(equalTo: poster.trailingAnchor, constant: -10),
            seatPill.topAnchor.constraint(equalTo: poster.topAnchor, constant: 10)
        ])

        hostLabel.numberOfLines = 1
        titleLabel.font = Typeface.display(18, weight: .bold)
        titleLabel.textColor = Palette.paper
        titleLabel.numberOfLines = 2

        let pin = UIImageView(
            image: UIImage(
                systemName: "mappin.and.ellipse",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
            )
        )
        pin.tintColor = Palette.paper.withAlphaComponent(0.64)
        locationLabel.font = Typeface.body(11.5, weight: .medium)
        locationLabel.textColor = Palette.paper.withAlphaComponent(0.68)
        locationLabel.numberOfLines = 1
        let locationRow = UIStackView(axis: .horizontal, spacing: 4, alignment: .center, views: [pin, locationLabel])

        let textStack = UIStackView(
            axis: .vertical,
            spacing: 4,
            views: [hostLabel, titleLabel, locationRow]
        )
        textStack.setCustomSpacing(3, after: hostLabel)
        textStack.setCustomSpacing(6, after: titleLabel)

        arrowCircle.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        arrowCircle.layer.cornerRadius = 14
        arrowCircle.layer.borderWidth = 1
        arrowCircle.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        let arrow = UIImageView(
            image: UIImage(
                systemName: "arrow.up.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
            )
        )
        arrow.tintColor = Palette.paper
        arrowCircle.addSubview(arrow)
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.centerXAnchor.constraint(equalTo: arrowCircle.centerXAnchor).isActive = true
        arrow.centerYAnchor.constraint(equalTo: arrowCircle.centerYAnchor).isActive = true
        arrowCircle.translatesAutoresizingMaskIntoConstraints = false
        arrowCircle.widthAnchor.constraint(equalToConstant: 28).isActive = true
        arrowCircle.heightAnchor.constraint(equalToConstant: 28).isActive = true

        poster.addSubviews(textStack, arrowCircle)
        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: poster.leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: arrowCircle.leadingAnchor, constant: -6),
            textStack.bottomAnchor.constraint(equalTo: poster.bottomAnchor, constant: -12),
            arrowCircle.trailingAnchor.constraint(equalTo: poster.trailingAnchor, constant: -10),
            arrowCircle.bottomAnchor.constraint(equalTo: poster.bottomAnchor, constant: -12)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    func configure(event: StudioEvent, host: Maker?, seatsLeft: Int) {
        self.event = event
        poster.configure(assetName: event.posterAsset, fileName: event.posterFile, remoteURL: event.posterRemoteURL)
        monthLabel.text = event.date.monthAbbreviation
        dayLabel.text = event.date.dayNumber
        hostLabel.text = host?.name ?? "WoArt"
        titleLabel.text = event.title
        locationLabel.text = event.location
        seatPill.text = seatsLeft == 0 ? "FULL" : "\(seatsLeft) SEATS"
    }

    @objc private func tapped() {
        guard event != nil else { return }
        Haptics.tap()
        UIView.animate(withDuration: 0.14, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.contentView.transform = .identity
            }
            self.onOpen?()
        }
    }
}
