import UIKit

/// WOART wordmark: a serif "W", a turned-wood ring standing in for the "O", and "ART".
final class WordmarkView: UIView {
    private let leftLabel = UILabel()
    private let ring = RingGlyphView()
    private let rightLabel = UILabel()

    init(size: CGFloat = 26, color: UIColor = Palette.ink) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        leftLabel.attributedText = attributed("W", size: size, kern: 1.5)
        rightLabel.attributedText = attributed("ART", size: size, kern: 1.8)
        leftLabel.textColor = color
        rightLabel.textColor = color
        ring.color = color

        let stack = UIStackView(
            axis: .horizontal,
            spacing: size * 0.08,
            alignment: .center,
            views: [leftLabel, ring, rightLabel]
        )
        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftLabel.setContentHuggingPriority(.required, for: .horizontal)
        rightLabel.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            ring.widthAnchor.constraint(equalToConstant: size * 0.66),
            ring.heightAnchor.constraint(equalTo: ring.widthAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func attributed(_ text: String, size: CGFloat, kern: CGFloat) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.serif(size, weight: .heavy),
                .kern: kern
            ]
        )
    }
}
