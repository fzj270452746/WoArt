import UIKit
import PhotosUI
import UniformTypeIdentifiers

final class ComposePostViewController: ComposeBaseViewController, PHPickerViewControllerDelegate {
    private let store = StudioStore.shared
    private let mediaPlaceholder = DashedCardView()
    private let mediaScroll = UIScrollView()
    private let mediaStack = UIStackView()
    private let mediaHint = UILabel()
    private let titleField = InputFieldView(title: "Title", placeholder: "A chair from one ash tree")
    private let storyCard = CardView(radius: 24)
    private let storyView = UITextView()
    private let storyPlaceholder = UILabel()
    private let tagsField = InputFieldView(title: "Tags", placeholder: "ash, joinery, hand tools")
    private var mediaItems: [MediaItem] = []
    private var isProcessing = false

    init() {
        super.init(
            eyebrow: "New piece",
            title: "What are you\nsharing?",
            subtitle: "A finished piece, a work in progress, or a film from the bench.",
            publishTitle: "Share with the bench"
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func buildFields() {
        buildMediaPlaceholder()

        mediaScroll.showsHorizontalScrollIndicator = false
        mediaScroll.isHidden = true
        mediaStack.axis = .horizontal
        mediaStack.spacing = 10
        mediaScroll.addSubview(mediaStack)
        mediaStack.translatesAutoresizingMaskIntoConstraints = false
        mediaScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mediaScroll.heightAnchor.constraint(equalToConstant: 126),
            mediaStack.topAnchor.constraint(equalTo: mediaScroll.contentLayoutGuide.topAnchor),
            mediaStack.leadingAnchor.constraint(equalTo: mediaScroll.contentLayoutGuide.leadingAnchor),
            mediaStack.trailingAnchor.constraint(equalTo: mediaScroll.contentLayoutGuide.trailingAnchor),
            mediaStack.bottomAnchor.constraint(equalTo: mediaScroll.contentLayoutGuide.bottomAnchor),
            mediaStack.heightAnchor.constraint(equalTo: mediaScroll.frameLayoutGuide.heightAnchor)
        ])

        mediaHint.text = "The first file becomes the cover. Up to six."
        mediaHint.font = Typeface.body(10.5)
        mediaHint.textColor = Palette.inkFaint
        mediaHint.isHidden = true

        contentStack.addArrangedSubview(mediaPlaceholder)
        contentStack.addArrangedSubview(mediaScroll)
        contentStack.addArrangedSubview(mediaHint)

        let titleCard = CardView(radius: 24)
        titleCard.addSubview(titleField)
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.pinEdges(to: titleCard, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        contentStack.addArrangedSubview(titleCard)

        storyView.backgroundColor = .clear
        storyView.font = Typeface.body(14.5)
        storyView.textColor = Palette.ink
        storyView.tintColor = Palette.terracotta
        storyView.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        storyView.delegate = self

        storyPlaceholder.text = "Talk about the wood, the mistakes, the thing you would do differently next time."
        storyPlaceholder.font = Typeface.body(14.5)
        storyPlaceholder.textColor = Palette.inkFaint.withAlphaComponent(0.85)
        storyPlaceholder.numberOfLines = 0

        storyCard.addSubviews(storyView, storyPlaceholder)
        NSLayoutConstraint.activate([
            storyView.topAnchor.constraint(equalTo: storyCard.topAnchor, constant: 2),
            storyView.leadingAnchor.constraint(equalTo: storyCard.leadingAnchor, constant: 4),
            storyView.trailingAnchor.constraint(equalTo: storyCard.trailingAnchor, constant: -4),
            storyView.bottomAnchor.constraint(equalTo: storyCard.bottomAnchor, constant: -2),
            storyView.heightAnchor.constraint(equalToConstant: 154),
            storyPlaceholder.topAnchor.constraint(equalTo: storyCard.topAnchor, constant: 17),
            storyPlaceholder.leadingAnchor.constraint(equalTo: storyCard.leadingAnchor, constant: 17),
            storyPlaceholder.trailingAnchor.constraint(equalTo: storyCard.trailingAnchor, constant: -17)
        ])
        contentStack.addArrangedSubview(storyCard)

        let tagsCard = CardView(radius: 24)
        tagsCard.addSubview(tagsField)
        tagsField.translatesAutoresizingMaskIntoConstraints = false
        tagsField.pinEdges(to: tagsCard, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        contentStack.addArrangedSubview(tagsCard)

        let tagsHint = UILabel()
        tagsHint.text = "Separate tags with commas. Three is plenty."
        tagsHint.font = Typeface.body(10.5)
        tagsHint.textColor = Palette.inkFaint
        contentStack.addArrangedSubview(tagsHint)

        contentStack.addArrangedSubview(
            ToolNoteView(
                text: "Only share work you made or have permission to share. Every post can be reported, and you can delete your own pieces at any time."
            )
        )
        contentStack.setCustomSpacing(22, after: storyCard)
        contentStack.setCustomSpacing(24, after: tagsHint)
    }

    private func buildMediaPlaceholder() {
        mediaPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        mediaPlaceholder.heightAnchor.constraint(equalToConstant: 142).isActive = true

        let circle = UIView()
        circle.backgroundColor = Palette.terracotta.withAlphaComponent(0.12)
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
        icon.tintColor = Palette.terracotta
        circle.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerXAnchor.constraint(equalTo: circle.centerXAnchor).isActive = true
        icon.centerYAnchor.constraint(equalTo: circle.centerYAnchor).isActive = true

        let title = UILabel()
        title.text = "Add photos or a film"
        title.font = Typeface.display(19, weight: .semibold)
        title.textColor = Palette.ink
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Choose up to six from your library."
        subtitle.font = Typeface.body(11)
        subtitle.textColor = Palette.inkFaint
        subtitle.textAlignment = .center

        let stack = UIStackView(axis: .vertical, spacing: 6, alignment: .center, views: [circle, title, subtitle])
        mediaPlaceholder.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.centerXAnchor.constraint(equalTo: mediaPlaceholder.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: mediaPlaceholder.centerYAnchor).isActive = true
        mediaPlaceholder.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPicker)))
    }

    private func rebuildMedia() {
        mediaStack.arrangedSubviews.forEach {
            mediaStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        mediaPlaceholder.isHidden = !mediaItems.isEmpty
        mediaScroll.isHidden = mediaItems.isEmpty
        mediaHint.isHidden = mediaItems.isEmpty

        for (index, item) in mediaItems.enumerated() {
            let tile = ComposeMediaTile(item: item) { [weak self] in
                self?.removeMedia(at: index)
            }
            mediaStack.addArrangedSubview(tile)
        }
        if mediaItems.count < 6 {
            let add = UIButton(type: .custom)
            add.layer.cornerRadius = 20
            add.layer.borderWidth = 1.2
            add.layer.borderColor = Palette.ink.withAlphaComponent(0.16).cgColor
            add.setImage(
                UIImage(
                    systemName: "plus",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
                ),
                for: .normal
            )
            add.tintColor = Palette.terracotta
            add.backgroundColor = Palette.cream.withAlphaComponent(0.5)
            add.translatesAutoresizingMaskIntoConstraints = false
            add.widthAnchor.constraint(equalToConstant: 92).isActive = true
            add.heightAnchor.constraint(equalToConstant: 118).isActive = true
            add.addTarget(self, action: #selector(openPicker), for: .touchUpInside)
            mediaStack.addArrangedSubview(add)
        }
    }

    private func removeMedia(at index: Int) {
        guard index < mediaItems.count else { return }
        let item = mediaItems.remove(at: index)
        MediaLibrary.removeMedia(named: item.fileName)
        MediaLibrary.removeMedia(named: item.videoFileName)
        rebuildMedia()
    }

    @objc private func openPicker() {
        guard mediaItems.count < 6 else {
            showToast("Six files is the limit for one piece.", icon: "exclamationmark")
            return
        }
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 6 - mediaItems.count
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Picker

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }
        isProcessing = true
        mediaHint.isHidden = false
        mediaHint.text = "Preparing \(results.count) file\(results.count == 1 ? "" : "s")…"

        let group = DispatchGroup()
        var loaded = Array<MediaItem?>(repeating: nil, count: results.count)

        for (index, result) in results.enumerated() {
            let provider = result.itemProvider
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    defer { group.leave() }
                    guard let image = object as? UIImage else { return }
                    let scaled = image.downscaled(maxDimension: 1600)
                    guard let fileName = MediaLibrary.saveImage(scaled) else { return }
                    let aspect = min(max(scaled.size.width / max(1, scaled.size.height), 0.6), 1.5)
                    loaded[index] = MediaItem(assetName: "user_media", fileName: fileName, aspect: aspect)
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                    defer { group.leave() }
                    guard let url, let videoName = MediaLibrary.copyVideo(from: url) else { return }
                    let thumbnail = MediaLibrary.videoThumbnail(fileName: videoName)
                    let posterName = thumbnail.flatMap { MediaLibrary.saveImage($0.downscaled(maxDimension: 1200)) }
                    let aspect = thumbnail.map {
                        min(max($0.size.width / max(1, $0.size.height), 0.6), 1.5)
                    } ?? 0.8
                    loaded[index] = MediaItem(
                        assetName: "user_media",
                        fileName: posterName,
                        videoFileName: videoName,
                        kind: .video,
                        aspect: aspect
                    )
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.mediaItems.append(contentsOf: loaded.compactMap { $0 })
            self.isProcessing = false
            self.rebuildMedia()
            self.mediaHint.text = self.mediaItems.isEmpty ? "" : "The first file becomes the cover. Up to six."
            self.mediaHint.isHidden = self.mediaItems.isEmpty
        }
    }

    // MARK: - Publish

    override func publishTapped() {
        let title = titleField.text.trimmed
        let story = storyView.text.trimmed
        guard !title.isEmpty else {
            showToast("Give your piece a title.", icon: "exclamationmark")
            return
        }
        guard !story.isEmpty || !mediaItems.isEmpty else {
            showToast("Add a photo, a film or a few words.", icon: "exclamationmark")
            return
        }
        guard !isProcessing else {
            showToast("Still preparing your files…", icon: "hourglass")
            return
        }
        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.submit(title: title, story: story)
        }) else { return }
        submit(title: title, story: story)
    }

    private func submit(title: String, story: String) {
        let parsedTags: [String] = tagsField.text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let tags = Array(parsedTags.prefix(3))

        let media = mediaItems
        let store = self.store
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await LoadingVeil.run(message: "Sharing with the bench…") {
                    _ = try await store.addPost(
                        title: title,
                        body: story,
                        media: media,
                        tags: tags
                    )
                }
                self.finishAndClose(message: "Shared with the bench")
            } catch {
                Haptics.warn()
                self.showToast(error.localizedDescription, icon: "exclamationmark")
            }
        }
    }
}

extension ComposePostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        storyPlaceholder.isHidden = !textView.text.isEmpty
    }
}

private final class ComposeMediaTile: UIView {
    init(item: MediaItem, onRemove: @escaping () -> Void) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 92).isActive = true
        heightAnchor.constraint(equalToConstant: 118).isActive = true

        let artwork = ArtworkView()
        artwork.layer.cornerRadius = 18
        artwork.layer.cornerCurve = .continuous
        artwork.clipsToBounds = true
        artwork.translatesAutoresizingMaskIntoConstraints = false
        artwork.configure(assetName: item.assetName, fileName: item.fileName)
        addSubview(artwork)
        artwork.pinEdges(to: self)

        if item.kind == .video {
            let play = UIImageView(
                image: UIImage(
                    systemName: "play.circle.fill",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
                )
            )
            play.tintColor = UIColor.white.withAlphaComponent(0.92)
            play.translatesAutoresizingMaskIntoConstraints = false
            addSubview(play)
            NSLayoutConstraint.activate([
                play.centerXAnchor.constraint(equalTo: centerXAnchor),
                play.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }

        let remove = UIButton(type: .custom)
        remove.backgroundColor = Palette.walnut.withAlphaComponent(0.75)
        remove.tintColor = .white
        remove.layer.cornerRadius = 12
        remove.setImage(
            UIImage(
                systemName: "xmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
            ),
            for: .normal
        )
        remove.translatesAutoresizingMaskIntoConstraints = false
        remove.widthAnchor.constraint(equalToConstant: 24).isActive = true
        remove.heightAnchor.constraint(equalToConstant: 24).isActive = true
        remove.addAction(UIAction { _ in onRemove() }, for: .touchUpInside)
        addSubview(remove)
        NSLayoutConstraint.activate([
            remove.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            remove.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
