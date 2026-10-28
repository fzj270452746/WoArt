import UIKit

protocol DockBarDelegate: AnyObject {
    func dockBar(_ dock: DockBar, didSelectTab index: Int)
    func dockBarDidTapCreate(_ dock: DockBar)
}

/// Floating walnut dock. Icons only, a raised centre action, and a turned-brass
/// marker for the active room. It replaces the standard tab bar entirely.
final class DockBar: UIView {
    weak var delegate: DockBarDelegate?

    private let tabIcons: [(idle: String, active: String)] = [
        ("hammer", "hammer.fill"),
        ("house", "house.fill"),
        ("calendar", "calendar"),
        ("person", "person.fill")
    ]
    private let slots: [Int: Int] = [0: 0, 1: 1, 3: 2, 4: 3]
    private var tabButtons: [UIButton] = []
    private let createButton = UIButton(type: .custom)
    private var activeIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.walnut
        layer.cornerRadius = 32
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor(hex: 0x1C110A).cgColor
        layer.shadowOpacity = 0.32
        layer.shadowRadius = 26
        layer.shadowOffset = CGSize(width: 0, height: 16)
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true

        buildItems()
        updateSelection(animated: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildItems() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        for position in 0..<5 {
            if position == 2 {
                configureCreateButton()
                stack.addArrangedSubview(createButton)
            } else {
                let index = slots[position] ?? 0
                let button = makeTabButton(index: index)
                tabButtons.append(button)
                stack.addArrangedSubview(button)
            }
        }
    }

    private func makeTabButton(index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 46).isActive = true
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        button.layer.cornerRadius = 23
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return button
    }

    private func configureCreateButton() {
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        createButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        createButton.backgroundColor = Palette.terracotta
        createButton.layer.cornerRadius = 25
        createButton.layer.cornerCurve = .continuous
        createButton.layer.borderWidth = 3
        createButton.layer.borderColor = Palette.walnut.cgColor
        createButton.layer.shadowColor = Palette.terracottaDeep.cgColor
        createButton.layer.shadowOpacity = 0.45
        createButton.layer.shadowRadius = 14
        createButton.layer.shadowOffset = CGSize(width: 0, height: 7)
        createButton.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)
        createButton.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        createButton.transform = CGAffineTransform(translationX: 0, y: -7)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTouchDown), for: .touchDown)
        createButton.addTarget(self, action: #selector(createTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }

    // MARK: - State

    func setActive(index: Int) {
        guard index != activeIndex else { return }
        activeIndex = index
        updateSelection(animated: true)
    }

    private func updateSelection(animated: Bool) {
        let apply = {
            for button in self.tabButtons {
                let icon = self.tabIcons[button.tag]
                let isActive = button.tag == self.activeIndex
                let symbol = isActive ? icon.active : icon.idle
                let config = UIImage.SymbolConfiguration(pointSize: 19, weight: isActive ? .semibold : .regular)
                button.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
                button.tintColor = isActive ? Palette.brassLight : Palette.paper.withAlphaComponent(0.5)
                button.backgroundColor = isActive ? UIColor.white.withAlphaComponent(0.07) : .clear
            }
        }
        if animated {
            UIView.animate(withDuration: 0.24, delay: 0, options: [.beginFromCurrentState]) { apply() }
        } else {
            apply()
        }
    }

    // MARK: - Actions

    @objc private func tabTapped(_ sender: UIButton) {
        Haptics.tap()
        delegate?.dockBar(self, didSelectTab: sender.tag)
    }

    @objc private func createTapped() {
        Haptics.tap()
        delegate?.dockBarDidTapCreate(self)
    }

    @objc private func createTouchDown() {
        UIView.animate(withDuration: 0.12) {
            self.createButton.transform = CGAffineTransform(translationX: 0, y: -4).scaledBy(x: 0.94, y: 0.94)
        }
    }

    @objc private func createTouchUp() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.4) {
            self.createButton.transform = CGAffineTransform(translationX: 0, y: -7)
        }
    }
}
