import UIKit

/// Displays a real image when one is available under the asset/file name.
/// Otherwise it draws a deterministic, wood-toned composition so the layout stays complete.
final class ArtworkView: UIView {
    private let imageView = UIImageView()
    private let artHost = CALayer()
    private var artLayers: [CALayer] = []
    private var lastRenderedSize: CGSize = .zero
    private var signature: String = ""
    private var isAvatar = false
    private var monogram: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.cream
        clipsToBounds = true
        layer.insertSublayer(artHost, at: 0)
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(
        assetName: String,
        fileName: String? = nil,
        remoteURL: String? = nil,
        avatar: Bool = false,
        monogram: String? = nil,
        contentMode: UIView.ContentMode = .scaleAspectFill
    ) {
        let nextSignature = "\(assetName)|\(fileName ?? "")|\(remoteURL ?? "")|\(avatar)|\(monogram ?? "")"
        imageView.contentMode = contentMode
        isAvatar = avatar
        self.monogram = monogram

        let local = MediaLibrary.image(assetName: assetName, fileName: fileName)
        let remoteCached = RemoteImageLoader.shared.cachedImage(for: remoteURL)
        let shown = remoteCached ?? local

        if let shown {
            signature = nextSignature
            imageView.image = shown
            imageView.isHidden = false
            clearArt()
        } else if signature != nextSignature {
            signature = nextSignature
            imageView.image = nil
            imageView.isHidden = true
            lastRenderedSize = .zero
            setNeedsLayout()
        }

        // A server image is authoritative; the bundled art is only a stand-in
        // while it downloads (or if the request fails).
        guard remoteCached == nil, let remoteURL else { return }
        let token = nextSignature
        RemoteImageLoader.shared.load(remoteURL) { [weak self] image in
            guard let self, self.signature == token, let image else { return }
            self.imageView.image = image
            self.imageView.isHidden = false
            self.clearArt()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        artHost.frame = bounds
        guard imageView.isHidden, bounds.width > 1, bounds.height > 1 else { return }
        guard bounds.size != lastRenderedSize else { return }
        lastRenderedSize = bounds.size
        renderGeneratedArt()
    }

    private func clearArt() {
        artLayers.forEach { $0.removeFromSuperlayer() }
        artLayers.removeAll()
    }

    private func renderGeneratedArt() {
        clearArt()
        let size = bounds.size
        var rng = SeededGenerator(seed: signature.stableSeed)
        let palette = ArtPalette.gradients[Int(signature.stableSeed % UInt64(ArtPalette.gradients.count))]

        let gradient = GradientFactory.diagonal(palette, in: bounds)
        artHost.addSublayer(gradient)
        artLayers.append(gradient)

        let glow = CAGradientLayer()
        glow.type = .radial
        glow.frame = CGRect(
            x: CGFloat.random(in: -0.35...0.25, using: &rng) * size.width,
            y: CGFloat.random(in: -0.4...0.05, using: &rng) * size.height,
            width: size.width * 1.3,
            height: size.height * 1.3
        )
        glow.startPoint = CGPoint(x: 0.5, y: 0.5)
        glow.endPoint = CGPoint(x: 1, y: 1)
        glow.colors = [
            UIColor.white.withAlphaComponent(0.34).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        artHost.addSublayer(glow)
        artLayers.append(glow)

        let rings = CAShapeLayer()
        rings.frame = bounds
        let center = CGPoint(
            x: CGFloat.random(in: 0.15...0.9, using: &rng) * size.width,
            y: CGFloat.random(in: 0.1...0.9, using: &rng) * size.height
        )
        let path = UIBezierPath()
        let baseRadius = min(size.width, size.height) * CGFloat.random(in: 0.18...0.3, using: &rng)
        for index in 0..<7 {
            let radius = baseRadius + CGFloat(index) * min(size.width, size.height) * 0.12
            let rect = CGRect(
                x: center.x - radius,
                y: center.y - radius * 0.78,
                width: radius * 2,
                height: radius * 1.56
            )
            path.append(UIBezierPath(ovalIn: rect))
        }
        rings.path = path.cgPath
        rings.fillColor = UIColor.clear.cgColor
        rings.strokeColor = UIColor.white.withAlphaComponent(0.16).cgColor
        rings.lineWidth = max(1, min(size.width, size.height) * 0.006)
        artHost.addSublayer(rings)
        artLayers.append(rings)

        let grain = CAShapeLayer()
        grain.frame = bounds
        let grainPath = UIBezierPath()
        for index in 0..<22 {
            let y = (CGFloat(index) / 22 + CGFloat.random(in: -0.02...0.02, using: &rng)) * size.height
            let bend = CGFloat.random(in: -0.06...0.06, using: &rng) * size.height
            grainPath.move(to: CGPoint(x: -20, y: y))
            grainPath.addCurve(
                to: CGPoint(x: size.width + 20, y: y + bend),
                controlPoint1: CGPoint(x: size.width * 0.3, y: y - bend * 0.6),
                controlPoint2: CGPoint(x: size.width * 0.7, y: y + bend * 0.8)
            )
            grain.lineWidth = CGFloat.random(in: 0.5...1.4, using: &rng)
        }
        grain.path = grainPath.cgPath
        grain.fillColor = UIColor.clear.cgColor
        grain.strokeColor = Palette.ink.withAlphaComponent(0.06).cgColor
        grain.lineWidth = 0.8
        artHost.addSublayer(grain)
        artLayers.append(grain)

        if isAvatar, let initial = monogram?.first {
            let label = CATextLayer()
            label.string = String(initial).uppercased()
            label.font = UIFont.serif(max(14, size.height * 0.4), weight: .bold)
            label.fontSize = max(14, size.height * 0.4)
            label.foregroundColor = UIColor(hex: 0xFFF8ED, alpha: 0.92).cgColor
            label.alignmentMode = .center
            label.frame = CGRect(
                x: 0,
                y: size.height / 2 - size.height * 0.3,
                width: size.width,
                height: size.height * 0.6
            )
            artHost.addSublayer(label)
            artLayers.append(label)
        }

        let vignette = GradientFactory.vertical(
            [UIColor.clear, Palette.walnut.withAlphaComponent(0.16)],
            in: bounds
        )
        vignette.locations = [0.6, 1]
        artHost.addSublayer(vignette)
        artLayers.append(vignette)
    }
}
