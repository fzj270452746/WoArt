import UIKit

enum Palette {
    static let ink = UIColor(hex: 0x241C16)
    static let inkSoft = UIColor(hex: 0x6F5E50)
    static let inkFaint = UIColor(hex: 0x9C8A79)
    static let paper = UIColor(hex: 0xFBF5EA)
    static let paperDeep = UIColor(hex: 0xF4E8D7)
    static let card = UIColor(hex: 0xFFFCF6)
    static let cream = UIColor(hex: 0xF2E3CF)
    static let terracotta = UIColor(hex: 0xC55638)
    static let terracottaDeep = UIColor(hex: 0xA8442B)
    static let clay = UIColor(hex: 0xDF8A63)
    static let brass = UIColor(hex: 0xC2963F)
    static let brassLight = UIColor(hex: 0xE8C884)
    static let moss = UIColor(hex: 0x5E7355)
    static let teal = UIColor(hex: 0x2F5C58)
    static let blush = UIColor(hex: 0xF7DDCC)
    static let sand = UIColor(hex: 0xEAD4B4)
    static let walnut = UIColor(hex: 0x34261D)
    static let hairline = UIColor(hex: 0x241C16, alpha: 0.09)
    static let scrim = UIColor(hex: 0x1B120C, alpha: 0.45)

    static let tagPalettes: [(UIColor, UIColor)] = [
        (UIColor(hex: 0xEDE1CB), UIColor(hex: 0x5D4A34)),
        (UIColor(hex: 0xE7DDE8), UIColor(hex: 0x5A4560)),
        (UIColor(hex: 0xDDE6DC), UIColor(hex: 0x42573F)),
        (UIColor(hex: 0xF1DACF), UIColor(hex: 0x8A4A34)),
        (UIColor(hex: 0xDCE4E6), UIColor(hex: 0x375558))
    ]
}

enum Typeface {
    static func display(_ size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        .serif(size, weight: weight)
    }

    static func body(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        .label(size, weight: weight)
    }

    static func chip(_ size: CGFloat = 13, weight: UIFont.Weight = .semibold) -> UIFont {
        .rounded(size, weight: weight)
    }

    static func eyebrow(_ size: CGFloat = 11) -> UIFont {
        .monospacedSystemFont(ofSize: size, weight: .semibold)
    }
}

enum ArtPalette {
    static let gradients: [[UIColor]] = [
        [UIColor(hex: 0xE9D3B4), UIColor(hex: 0xB97B4E), UIColor(hex: 0x6D432A)],
        [UIColor(hex: 0xF3E2CB), UIColor(hex: 0xD9A06E), UIColor(hex: 0x9A5A36)],
        [UIColor(hex: 0xD8DFD1), UIColor(hex: 0x8FA083), UIColor(hex: 0x4D5D45)],
        [UIColor(hex: 0xEAD5C6), UIColor(hex: 0xC97F5C), UIColor(hex: 0x7C4230)],
        [UIColor(hex: 0xE5D9C5), UIColor(hex: 0xA9906A), UIColor(hex: 0x5B4A34)],
        [UIColor(hex: 0xF0DCC2), UIColor(hex: 0xC98F52), UIColor(hex: 0x7A5730)]
    ]
}

enum GradientFactory {
    static func vertical(_ colors: [UIColor], in frame: CGRect) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.frame = frame
        layer.colors = colors.map(\.cgColor)
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }

    static func diagonal(_ colors: [UIColor], in frame: CGRect) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.frame = frame
        layer.colors = colors.map(\.cgColor)
        layer.startPoint = CGPoint(x: 0.05, y: 0)
        layer.endPoint = CGPoint(x: 0.95, y: 1)
        return layer
    }
}
