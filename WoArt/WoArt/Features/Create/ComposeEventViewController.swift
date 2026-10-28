import UIKit
import PhotosUI

final class ComposeEventViewController: ComposeBaseViewController, PHPickerViewControllerDelegate {
    private let store = StudioStore.shared
    private let coverBox = UIView()
    private let coverPlaceholder = DashedCardView()
    private let coverPreview = ArtworkView()
    private let coverBadge = UIView()
    private let removeCover = UIButton(type: .custom)
    private let titleField = InputFieldView(title: "Gathering name", placeholder: "Hand-cut dovetails")
    private let summaryField = InputFieldView(title: "One line", placeholder: "One drawer, one saw, one quiet afternoon")
    private let detailsCard = CardView(radius: 24)
    private let detailsView = UITextView()
    private let detailsPlaceholder = UILabel()
    private let locationField = InputFieldView(title: "Where", placeholder: "The Bench Room · Copenhagen")
    private let datePicker = UIDatePicker()
    private let capacityLabel = UILabel()
    private let capacityStepper = UIStepper()
    private var coverFileName: String?
    private var isProcessingCover = false

    init() {
        super.init(
            eyebrow: "New gathering",
            title: "Open the\nbench.",
            subtitle: "Invite makers into a room, a workshop or an afternoon outside.",
            publishTitle: "Host this gathering"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildFields() {
        buildCover()
        contentStack.addArrangedSubview(coverBox)

        let titleCard = CardView(radius: 24)
        titleCard.addSubview(titleField)
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.pinEdges(to: titleCard, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        contentStack.addArrangedSubview(titleCard)

        let summaryCard = CardView(radius: 24)
        summaryCard.addSubview(summaryField)
        summaryField.translatesAutoresizingMaskIntoConstraints = false
        summaryField.pinEdges(to: summaryCard, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        contentStack.addArrangedSubview(summaryCard)

        detailsView.backgroundColor = .clear
        detailsView.font = Typeface.body(14.5)
        detailsView.textColor = Palette.ink
        detailsView.tintColor = Palette.terracotta
        detailsView.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        detailsView.delegate = self
        detailsPlaceholder.text = "What will happen, what to bring, and how the day will run."
        detailsPlaceholder.font = Typeface.body(14.5)
        detailsPlaceholder.textColor = Palette.inkFaint.withAlphaComponent(0.85)
        detailsPlaceholder.numberOfLines = 0
        detailsCard.addSubviews(detailsView, detailsPlaceholder)
        NSLayoutConstraint.activate([
            detailsView.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 2),
            detailsView.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 4),
            detailsView.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -4),
            detailsView.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: -2),
            detailsView.heightAnchor.constraint(equalToConstant: 142),
            detailsPlaceholder.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 17),
            detailsPlaceholder.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor, constant: 17),
            detailsPlaceholder.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor, constant: -17)
        ])
        contentStack.addArrangedSubview(detailsCard)

        let locationCard = CardView(radius: 24)
        locationCard.addSubview(locationField)
        locationField.translatesAutoresizingMaskIntoConstraints = false
        locationField.pinEdges(to: locationCard, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        contentStack.addArrangedSubview(locationCard)

        contentStack.addArrangedSubview(makeWhenCard())
        contentStack.addArrangedSubview(makeCapacityCard())

        contentStack.addArrangedSubview(
            ToolNoteView(
                text: "Gatherings are visible to everyone. Reserved places are tracked for your account, and you can remove a gathering from your profile at any time."
            )
        )
        contentStack.setCustomSpacing(22, after: detailsCard)
    }

    private func buildCover() {
        coverBox.translatesAutoresizingMaskIntoConstraints = false
        coverBox.heightAnchor.constraint(equalToConstant: 176).isActive = true

        coverPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        coverBox.addSubview(coverPlaceholder)
        coverPlaceholder.pinEdges(to: coverBox)

        let circle = UIView()
        circle.backgroundColor = Palette.moss.withAlphaComponent(0.12)
        circle.layer.cornerRadius = 24
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 48).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 48).isActive = true
        let icon = UIImageView(
            image: UIImage(
                systemName: "photo.badge.plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            )
        )
        icon.tintColor = Palette.moss
        circle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor).isActive = true
        icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor).isActive = true

        let title = UILabel()
        title.text = "Add a cover"
        title.font = Typeface.display(19, weight: .semibold)
        title.textColor = Palette.ink
        title.textAlignment = .center
        let subtitle = UILabel()
        subtitle.text = "A photograph of the room, the bench or the work."
        subtitle.font = Typeface.body(11)
        subtitle.textColor = Palette.inkFaint
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let stack = UIStackView(axis: .vertical, spacing: 6, alignment: .center, views: [circle, title, subtitle])
        coverPlaceholder.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.centerXAnchor.constraint(equalTo: coverPlaceholder.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: coverPlaceholder.centerYAnchor).isActive = true
        stack.leadingAnchor.constraint(greaterThanOrEqualTo: coverPlaceholder.leadingAnchor, constant: 20).isActive = true
        stack.trailingAnchor.constraint(lessThanOrEqualTo: coverPlaceholder.trailingAnchor, constant: -20).isActive = true
        coverPlaceholder.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPicker)))

        coverPreview.layer.cornerRadius = 24
        coverPreview.layer.cornerCurve = .continuous
        coverPreview.clipsToBounds = true
        coverPreview.isHidden = true
        coverBox.addSubview(coverPreview)
        coverPreview.translatesAutoresizingMaskIntoConstraints = false
        coverPreview.pinEdges(to: coverBox)

        coverBadge.backgroundColor = Palette.walnut.withAlphaComponent(0.55)
        coverBadge.layer.cornerRadius = 11
        coverBadge.isHidden = true
        let badgeLabel = UILabel()
        badgeLabel.text = "COVER"
        badgeLabel.font = Typeface.eyebrow(8)
        badgeLabel.textColor = Palette.paper
        coverBadge.addSubview(badgeLabel)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.pinEdges(to: coverBadge, insets: UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9))
        coverPreview.addSubview(coverBadge)
        coverBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverBadge.leadingAnchor.constraint(equalTo: coverPreview.leadingAnchor, constant: 12),
            coverBadge.topAnchor.constraint(equalTo: coverPreview.topAnchor, constant: 12)
        ])

        removeCover.backgroundColor = Palette.walnut.withAlphaComponent(0.7)
        removeCover.layer.cornerRadius = 14
        removeCover.tintColor = .white
        removeCover.setImage(
            UIImage(
                systemName: "xmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
            ),
            for: .normal
        )
        removeCover.translatesAutoresizingMaskIntoConstraints = false
        removeCover.widthAnchor.constraint(equalToConstant: 28).isActive = true
        removeCover.heightAnchor.constraint(equalToConstant: 28).isActive = true
        removeCover.isHidden = true
        removeCover.addTarget(self, action: #selector(removeCoverTapped), for: .touchUpInside)
        coverBox.addSubview(removeCover)
        NSLayoutConstraint.activate([
            removeCover.topAnchor.constraint(equalTo: coverBox.topAnchor, constant: 10),
            removeCover.trailingAnchor.constraint(equalTo: coverBox.trailingAnchor, constant: -10)
        ])

        let selection = UITapGestureRecognizer(target: self, action: #selector(openPicker))
        coverPreview.addGestureRecognizer(selection)
        coverPreview.isUserInteractionEnabled = true
    }

    private func makeWhenCard() -> UIView {
        let card = CardView(radius: 24)
        let label = EyebrowLabel("When", color: Palette.inkFaint, size: 9)

        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        datePicker.minimumDate = Date()
        datePicker.tintColor = Palette.terracotta
        datePicker.locale = Locale(identifier: "en_US")
        datePicker.date = Calendar.current.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        ) ?? Date()

        let stack = UIStackView(axis: .vertical, spacing: 8, views: [label, datePicker])
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 18, bottom: 16, right: 18))
        return card
    }

    private func makeCapacityCard() -> UIView {
        let card = CardView(radius: 24)
        let label = EyebrowLabel("Places", color: Palette.inkFaint, size: 9)

        capacityLabel.text = "8 makers"
        capacityLabel.font = Typeface.display(20, weight: .semibold)
        capacityLabel.textColor = Palette.ink

        capacityStepper.minimumValue = 2
        capacityStepper.maximumValue = 40
        capacityStepper.value = 8
        capacityStepper.tintColor = Palette.terracotta
        capacityStepper.addTarget(self, action: #selector(capacityChanged), for: .valueChanged)

        let row = UIStackView(axis: .horizontal, spacing: 12, alignment: .center, views: [capacityLabel])
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(capacityStepper)

        let stack = UIStackView(axis: .vertical, spacing: 8, views: [label, row])
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinEdges(to: card, insets: UIEdgeInsets(top: 16, left: 18, bottom: 16, right: 18))
        return card
    }

    @objc private func capacityChanged() {
        capacityLabel.text = "\(Int(capacityStepper.value)) makers"
    }

    @objc private func openPicker() {
        guard !isProcessingCover else { return }
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        isProcessingCover = true
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            let scaled = image.downscaled(maxDimension: 1600)
            let fileName = MediaLibrary.saveImage(scaled)
            DispatchQueue.main.async {
                guard let self else { return }
                self.isProcessingCover = false
                self.coverFileName = fileName
                self.coverPreview.isHidden = false
                self.coverPlaceholder.isHidden = true
                self.coverBadge.isHidden = false
                self.removeCover.isHidden = false
                self.coverPreview.configure(assetName: "event_user_poster", fileName: fileName)
                Haptics.success()
            }
        }
    }

    @objc private func removeCoverTapped() {
        MediaLibrary.removeMedia(named: coverFileName)
        coverFileName = nil
        coverPreview.isHidden = true
        coverPlaceholder.isHidden = false
        coverBadge.isHidden = true
        removeCover.isHidden = true
    }

    override func publishTapped() {
        let title = titleField.text.trimmed
        let summary = summaryField.text.trimmed
        let details = detailsView.text.trimmed
        let location = locationField.text.trimmed

        guard !title.isEmpty else {
            showToast("Give the gathering a name.", icon: "exclamationmark")
            return
        }
        guard !location.isEmpty else {
            showToast("Where will it happen?", icon: "exclamationmark")
            return
        }
        guard datePicker.date > Date().addingTimeInterval(-60) else {
            showToast("Choose a date in the future.", icon: "exclamationmark")
            return
        }

        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.submit(title: title, summary: summary, details: details, location: location)
        }) else { return }
        submit(title: title, summary: summary, details: details, location: location)
    }

    private func submit(title: String, summary: String, details: String, location: String) {
        let store = self.store
        let startsAt = datePicker.date
        let seats = Int(capacityStepper.value)
        let poster = coverFileName
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await LoadingVeil.run(message: "Opening the gathering…") {
                    _ = try await store.addEvent(
                        title: title,
                        summary: summary,
                        details: details.isEmpty ? summary : details,
                        location: location,
                        date: startsAt,
                        capacity: seats,
                        posterFile: poster
                    )
                }
                self.finishAndClose(message: "Gathering is open")
            } catch {
                Haptics.warn()
                self.showToast(error.localizedDescription, icon: "exclamationmark")
            }
        }
    }
}

extension ComposeEventViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        detailsPlaceholder.isHidden = !textView.text.isEmpty
    }
}
