import UIKit

final class InputFieldView: UIView, UITextFieldDelegate {
    let textField = UITextField()
    private let titleLabel = UILabel()
    private let line = UIView()
    private let revealButton = UIButton(type: .system)

    var onChange: ((String) -> Void)?

    var text: String {
        textField.text ?? ""
    }

    init(title: String, placeholder: String, secure: Bool = false, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)

        titleLabel.text = title.uppercased()
        titleLabel.font = Typeface.eyebrow(10)
        titleLabel.textColor = Palette.inkFaint

        textField.font = Typeface.body(16, weight: .medium)
        textField.textColor = Palette.ink
        textField.tintColor = Palette.terracotta
        textField.keyboardType = keyboard
        textField.isSecureTextEntry = secure
        textField.autocapitalizationType = keyboard == .emailAddress ? .none : .words
        textField.autocorrectionType = .no
        textField.delegate = self
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: Typeface.body(16, weight: .regular),
                .foregroundColor: Palette.inkFaint.withAlphaComponent(0.75)
            ]
        )
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)

        line.backgroundColor = Palette.ink.withAlphaComponent(0.14)
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1.2).isActive = true

        addSubview(titleLabel)
        addSubview(textField)
        addSubview(line)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 9),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 30),

            line.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        if secure {
            revealButton.setImage(
                UIImage(systemName: "eye", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)),
                for: .normal
            )
            revealButton.tintColor = Palette.inkFaint
            revealButton.addTarget(self, action: #selector(toggleReveal), for: .touchUpInside)
            addSubview(revealButton)
            revealButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                revealButton.trailingAnchor.constraint(equalTo: trailingAnchor),
                revealButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
                revealButton.widthAnchor.constraint(equalToConstant: 36),
                revealButton.heightAnchor.constraint(equalToConstant: 36),
                textField.trailingAnchor.constraint(equalTo: revealButton.leadingAnchor, constant: -6)
            ])
        } else {
            textField.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setTitle(_ text: String) {
        titleLabel.text = text.uppercased()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    override var isFirstResponder: Bool {
        textField.isFirstResponder
    }

    @objc private func editingChanged() {
        onChange?(text)
    }

    @objc private func toggleReveal() {
        textField.isSecureTextEntry.toggle()
        let symbol = textField.isSecureTextEntry ? "eye" : "eye.slash"
        revealButton.setImage(
            UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)),
            for: .normal
        )
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.line.backgroundColor = Palette.terracotta
            self.titleLabel.textColor = Palette.terracotta
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.line.backgroundColor = Palette.ink.withAlphaComponent(0.14)
            self.titleLabel.textColor = Palette.inkFaint
        }
    }
}
