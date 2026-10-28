import UIKit

/// Layered paper, clay glow and wood-ring drawing used behind every screen.
final class StudioBackdropView: UIView {
    private let baseLayer = CAGradientLayer()
    private let warmGlow = CAGradientLayer()
    private let coolGlow = CAGradientLayer()
    private let ringsLayer = CAShapeLayer()
    private let lowerRingsLayer = CAShapeLayer()
    private let grainLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = Palette.paper

        baseLayer.startPoint = CGPoint(x: 0.05, y: 0)
        baseLayer.endPoint = CGPoint(x: 0.95, y: 1)
        baseLayer.colors = [
            UIColor(hex: 0xFDF9F1).cgColor,
            UIColor(hex: 0xFAEFE2).cgColor,
            UIColor(hex: 0xF5E0CE).cgColor
        ]
        layer.addSublayer(baseLayer)

        warmGlow.type = .radial
        warmGlow.startPoint = CGPoint(x: 0.5, y: 0.5)
        warmGlow.endPoint = CGPoint(x: 1.05, y: 1.05)
        warmGlow.colors = [
            UIColor(hex: 0xF3BE9E, alpha: 0.62).cgColor,
            UIColor(hex: 0xF3BE9E, alpha: 0).cgColor
        ]
        layer.addSublayer(warmGlow)

        coolGlow.type = .radial
        coolGlow.startPoint = CGPoint(x: 0.5, y: 0.5)
        coolGlow.endPoint = CGPoint(x: 1.0, y: 1.0)
        coolGlow.colors = [
            UIColor(hex: 0xD9D6B8, alpha: 0.5).cgColor,
            UIColor(hex: 0xD9D6B8, alpha: 0).cgColor
        ]
        layer.addSublayer(coolGlow)

        ringsLayer.fillColor = UIColor.clear.cgColor
        ringsLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        ringsLayer.lineWidth = 1.1
        layer.addSublayer(ringsLayer)

        lowerRingsLayer.fillColor = UIColor.clear.cgColor
        lowerRingsLayer.strokeColor = Palette.ink.withAlphaComponent(0.05).cgColor
        lowerRingsLayer.lineWidth = 1
        layer.addSublayer(lowerRingsLayer)

        grainLayer.fillColor = UIColor.clear.cgColor
        grainLayer.strokeColor = Palette.ink.withAlphaComponent(0.026).cgColor
        grainLayer.lineWidth = 0.8
        layer.addSublayer(grainLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }

        baseLayer.frame = bounds
        warmGlow.frame = CGRect(
            x: bounds.width * 0.42,
            y: -bounds.height * 0.16,
            width: bounds.width * 1.0,
            height: bounds.height * 0.72
        )
        coolGlow.frame = CGRect(
            x: -bounds.width * 0.5,
            y: bounds.height * 0.46,
            width: bounds.width * 1.1,
            height: bounds.height * 0.65
        )

        ringsLayer.frame = bounds
        ringsLayer.path = ringPath(
            center: CGPoint(x: bounds.width * 0.94, y: bounds.height * 0.12),
            radii: stride(from: 46.0, through: 286.0, by: 30.0).map { $0 },
            squash: 0.86
        ).cgPath

        lowerRingsLayer.frame = bounds
        lowerRingsLayer.path = ringPath(
            center: CGPoint(x: -bounds.width * 0.06, y: bounds.height * 0.84),
            radii: stride(from: 60.0, through: 330.0, by: 36.0).map { $0 },
            squash: 1.0
        ).cgPath

        grainLayer.frame = bounds
        grainLayer.path = grainPath().cgPath
    }

    private func ringPath(center: CGPoint, radii: [CGFloat], squash: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        for radius in radii {
            let rect = CGRect(
                x: center.x - radius,
                y: center.y - radius * squash,
                width: radius * 2,
                height: radius * 2 * squash
            )
            path.append(UIBezierPath(ovalIn: rect))
        }
        return path
    }

    private func grainPath() -> UIBezierPath {
        let path = UIBezierPath()
        var seed: UInt64 = 0x5EED_A11E
        for index in 0..<34 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let y = CGFloat(seed >> 33 % 1000) / 1000 * bounds.height
            let lift = CGFloat(index % 5) * 2.4
            path.move(to: CGPoint(x: -30, y: y))
            path.addCurve(
                to: CGPoint(x: bounds.width + 30, y: y + lift),
                controlPoint1: CGPoint(x: bounds.width * 0.32, y: y - 16 - lift),
                controlPoint2: CGPoint(x: bounds.width * 0.68, y: y + 20 + lift)
            )
        }
        return path
    }
}

/// A thin decorative ring used in the wordmark and empty states.
final class RingGlyphView: UIView {
    private let shape = CAShapeLayer()
    var color: UIColor = Palette.ink {
        didSet { shape.strokeColor = color.cgColor }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = color.cgColor
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        shape.frame = bounds
        let lineWidth = max(1.4, bounds.width * 0.1)
        shape.lineWidth = lineWidth
        let inset = lineWidth / 2 + 0.5
        let rect = bounds.insetBy(dx: inset + 1, dy: inset + 1)
        let path = UIBezierPath()
        path.append(UIBezierPath(ovalIn: rect))
        let inner = rect.insetBy(dx: rect.width * 0.24, dy: rect.height * 0.24)
        path.append(UIBezierPath(ovalIn: inner))
        shape.path = path.cgPath
        shape.transform = CATransform3DMakeRotation(.pi / 9, 0, 0, 1)
    }
}
