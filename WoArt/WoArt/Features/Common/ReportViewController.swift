import UIKit

enum ReportTarget {
    case post(String)
    case comment(id: String, postID: String)
    case maker(String)
}

private enum ReportReason: CaseIterable {
    case illegal
    case uncomfortable
    case block
    case other

    var title: String {
        switch self {
        case .illegal: return "Illegal content"
        case .uncomfortable: return "Uncomfortable content"
        case .block: return "Block this maker"
        case .other: return "Something else"
        }
    }

    var caption: String {
        switch self {
        case .illegal: return "Something that breaks the law."
        case .uncomfortable: return "Harassment, threats or graphic material."
        case .block: return "Hide all of their work from your view."
        case .other: return "Tell us briefly what happened."
        }
    }
}

final class ReportViewController: BaseViewController {
    private let target: ReportTarget
    private let store = StudioStore.shared
    private let topBar = DetailTopBar()
    private var selectedReason: ReportReason?
    private var reasonRows: [ReportReasonRow] = []
    private let noteView = UITextView()
    private let notePlaceholder = UILabel()
    private let submitButton = PillButton(title: "Submit report", style: .dark, height: 54)

    override var hidesDock: Bool { true }

    init(target: ReportTarget) {
        self.target = target
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackBar(topBar)

        let eyebrow = EyebrowLabel("Community care", color: Palette.terracotta)
        let title = UILabel()
        title.text = "What's wrong?"
        title.font = Typeface.display(35, weight: .bold)
        title.textColor = Palette.ink
        title.numberOfLines = 0

        let intro = UILabel()
        intro.text = "Reports are private. Whatever you report is removed from your view immediately."
        intro.font = Typeface.body(14.5)
        intro.textColor = Palette.inkSoft
        intro.numberOfLines = 0
        intro.setLineHeight(4)

        let optionsStack = UIStackView(axis: .vertical, spacing: 10, views: [])
        for reason in ReportReason.allCases {
            let row = ReportReasonRow(reason: reason)
            row.addTarget(self, action: #selector(reasonTapped(_:)), for: .touchUpInside)
            reasonRows.append(row)
            optionsStack.addArrangedSubview(row)
        }

        let noteCard = CardView(radius: 22)
        noteView.backgroundColor = .clear
        noteView.font = Typeface.body(14.5)
        noteView.textColor = Palette.ink
        noteView.tintColor = Palette.terracotta
        noteView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        noteView.delegate = self

        notePlaceholder.text = "Anything else we should know? (optional)"
        notePlaceholder.font = Typeface.body(14.5)
        notePlaceholder.textColor = Palette.inkFaint.withAlphaComponent(0.8)
        notePlaceholder.numberOfLines = 0

        noteCard.addSubviews(noteView, notePlaceholder)
        NSLayoutConstraint.activate([
            noteView.topAnchor.constraint(equalTo: noteCard.topAnchor, constant: 2),
            noteView.leadingAnchor.constraint(equalTo: noteCard.leadingAnchor, constant: 4),
            noteView.trailingAnchor.constraint(equalTo: noteCard.trailingAnchor, constant: -4),
            noteView.bottomAnchor.constraint(equalTo: noteCard.bottomAnchor, constant: -2),
            noteView.heightAnchor.constraint(equalToConstant: 116),
            notePlaceholder.topAnchor.constraint(equalTo: noteCard.topAnchor, constant: 16),
            notePlaceholder.leadingAnchor.constraint(equalTo: noteCard.leadingAnchor, constant: 17),
            notePlaceholder.trailingAnchor.constraint(equalTo: noteCard.trailingAnchor, constant: -17)
        ])

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        let footer = UILabel()
        footer.text = "You can also remove your own posts and comments at any time."
        footer.font = Typeface.body(11)
        footer.textColor = Palette.inkFaint
        footer.numberOfLines = 0

        let stack = UIStackView(
            axis: .vertical,
            spacing: 16,
            views: [eyebrow, title, intro, optionsStack, noteCard, submitButton, footer]
        )
        stack.setCustomSpacing(7, after: eyebrow)
        stack.setCustomSpacing(12, after: title)
        stack.setCustomSpacing(24, after: intro)
        stack.setCustomSpacing(24, after: optionsStack)
        stack.setCustomSpacing(20, after: noteCard)

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.addSubview(stack)
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 18),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }

    @objc private func reasonTapped(_ sender: ReportReasonRow) {
        Haptics.tap()
        selectedReason = sender.reason
        for row in reasonRows {
            row.setSelected(row === sender)
        }
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        guard let reason = selectedReason else {
            showToast("Choose a reason first.", icon: "exclamationmark")
            return
        }

        ConfirmSheetViewController.present(
            from: self,
            title: "Remove from your view?",
            message: removalMessage(for: reason),
            confirmTitle: "Remove",
            destructive: true
        ) { [weak self] in
            self?.applyReport()
        }
    }

    private func removalMessage(for reason: ReportReason) -> String {
        if reason == .block {
            return "Their pieces and comments will be removed from your view. This cannot be undone."
        }
        switch target {
        case .post:
            return "This post and its comments will be removed from your view. This cannot be undone."
        case .comment:
            return "This comment will be removed from your view. This cannot be undone."
        case .maker:
            return "Their pieces and comments will be removed from your view. This cannot be undone."
        }
    }

    private func applyReport() {
        guard let selectedReason else { return }
        let reason: String
        switch selectedReason {
        case .illegal: reason = "illegal"
        case .uncomfortable: reason = "offensive"
        case .block, .other: reason = "other"
        }
        let details = noteView.text.trimmed
        let blocking = selectedReason == .block
        let effectiveTarget = blocking ? makerTargetForBlocking() : target
        let store = self.store

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await LoadingVeil.run(message: "Sending the report…", minimum: 0.6) {
                    try await store.report(target: effectiveTarget, reason: reason, details: details)
                }
                self.showToast(blocking ? "Maker removed from your view" : "Removed from your view", icon: "checkmark")
                if blocking {
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    switch self.target {
                    case .post, .maker:
                        self.navigationController?.popToRootViewController(animated: true)
                    case .comment:
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                Haptics.warn()
                self.showToast(error.localizedDescription, icon: "exclamationmark")
            }
        }
    }

    /// "Block this maker" on a post or comment blocks the author rather than
    /// hiding a single piece of content.
    private func makerTargetForBlocking() -> ReportTarget {
        switch target {
        case .post(let postID):
            if let author = store.post(id: postID)?.authorID,
               author != StudioNamespace.currentUserID {
                return .maker(author)
            }
            return target
        case .comment(let commentID, _):
            if let author = store.comment(id: commentID)?.authorID,
               author != StudioNamespace.currentUserID {
                return .maker(author)
            }
            return target
        case .maker:
            return target
        }
    }
}

extension ReportViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        notePlaceholder.isHidden = !textView.text.isEmpty
    }
}

private final class ReportReasonRow: UIControl {
    let reason: ReportReason
    private let radio = UIView()
    private let radioDot = UIView()

    init(reason: ReportReason) {
        self.reason = reason
        super.init(frame: .zero)
        backgroundColor = Palette.card
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.ink.withAlphaComponent(0.07).cgColor

        radio.layer.cornerRadius = 10
        radio.layer.borderWidth = 1.5
        radio.layer.borderColor = Palette.inkFaint.cgColor
        radio.translatesAutoresizingMaskIntoConstraints = false
        radio.widthAnchor.constraint(equalToConstant: 20).isActive = true
        radio.heightAnchor.constraint(equalToConstant: 20).isActive = true

        radioDot.backgroundColor = Palette.terracotta
        radioDot.layer.cornerRadius = 5
        radioDot.alpha = 0
        radioDot.translatesAutoresizingMaskIntoConstraints = false
        radio.addSubview(radioDot)
        NSLayoutConstraint.activate([
            radioDot.centerXAnchor.constraint(equalTo: radio.centerXAnchor),
            radioDot.centerYAnchor.constraint(equalTo: radio.centerYAnchor),
            radioDot.widthAnchor.constraint(equalToConstant: 10),
            radioDot.heightAnchor.constraint(equalToConstant: 10)
        ])

        let titleLabel = UILabel()
        titleLabel.text = reason.title
        titleLabel.font = Typeface.chip(15, weight: .semibold)
        titleLabel.textColor = Palette.ink

        let captionLabel = UILabel()
        captionLabel.text = reason.caption
        captionLabel.font = Typeface.body(12)
        captionLabel.textColor = Palette.inkSoft
        captionLabel.numberOfLines = 0

        let textStack = UIStackView(axis: .vertical, spacing: 3, views: [titleLabel, captionLabel])
        textStack.isUserInteractionEnabled = false
        radio.isUserInteractionEnabled = false

        addSubviews(radio, textStack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
            radio.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            radio.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: radio.trailingAnchor, constant: 13),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setSelected(_ selected: Bool) {
        UIView.animate(withDuration: 0.18) {
            self.layer.borderColor = (selected ? Palette.terracotta : Palette.ink.withAlphaComponent(0.07)).cgColor
            self.backgroundColor = selected ? Palette.terracotta.withAlphaComponent(0.06) : Palette.card
            self.radio.layer.borderColor = (selected ? Palette.terracotta : Palette.inkFaint).cgColor
            self.radioDot.alpha = selected ? 1 : 0
        }
    }
}
