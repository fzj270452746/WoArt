import UIKit
import PhotosUI

final class EditProfileViewController: BaseViewController {
    private let store = StudioStore.shared
    private let topBar = DetailTopBar(trailingSymbol: "checkmark")
    private let avatar = ArtworkView()
    private let cameraBadge = UIView()
    private let nameField = InputFieldView(title: "Display name", placeholder: "How your name appears")
    private let craftField = InputFieldView(title: "Craft", placeholder: "Furniture, carving, turning…")
    private let locationField = InputFieldView(title: "Where you work", placeholder: "City or region")
    private let bioCard = CardView(radius: 22)
    private let bioView = UITextView()
    private let bioPlaceholder = UILabel()
    private var pendingAvatarFile: String?

    override var hidesDock: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        build()
        populate()
    }

    private func build() {
        topBar.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        topBar.onTrailing = { [weak self] in
            self?.save()
        }
        configureBackBar(topBar)

        avatar.layer.cornerRadius = 46
        avatar.layer.borderWidth = 3
        avatar.layer.borderColor = Palette.card.cgColor
        avatar.clipsToBounds = true
        avatar.applySoftShadow(opacity: 0.16, radius: 22, y: 10)
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 92).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 92).isActive = true

        cameraBadge.backgroundColor = Palette.terracotta
        cameraBadge.layer.cornerRadius = 15
        cameraBadge.layer.borderWidth = 3
        cameraBadge.layer.borderColor = Palette.paper.cgColor
        cameraBadge.translatesAutoresizingMaskIntoConstraints = false
        cameraBadge.widthAnchor.constraint(equalToConstant: 30).isActive = true
        cameraBadge.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let cameraIcon = UIImageView(
            image: UIImage(
                systemName: "camera.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            )
        )
        cameraIcon.tintColor = .white
        cameraBadge.addSubview(cameraIcon)
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        cameraIcon.centerXAnchor.constraint(equalTo: cameraBadge.centerXAnchor).isActive = true
        cameraIcon.centerYAnchor.constraint(equalTo: cameraBadge.centerYAnchor).isActive = true

        let avatarHolder = UIView()
        avatarHolder.addSubviews(avatar, cameraBadge)
        avatarHolder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: avatarHolder.topAnchor),
            avatar.centerXAnchor.constraint(equalTo: avatarHolder.centerXAnchor),
            avatar.bottomAnchor.constraint(equalTo: avatarHolder.bottomAnchor),
            avatarHolder.heightAnchor.constraint(equalToConstant: 94),
            cameraBadge.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: -2),
            cameraBadge.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: -2)
        ])

        let hint = UILabel()
        hint.text = "Tap the portrait to choose a new photo."
        hint.font = Typeface.body(11.5)
        hint.textColor = Palette.inkFaint
        hint.textAlignment = .center

        let fieldsCard = CardView(radius: 26)
        let fieldsStack = UIStackView(
            axis: .vertical,
            spacing: 24,
            views: [nameField, craftField, locationField]
        )
        fieldsCard.addSubview(fieldsStack)
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        fieldsStack.pinEdges(to: fieldsCard, insets: UIEdgeInsets(top: 22, left: 20, bottom: 22, right: 20))

        let bioTitle = EyebrowLabel("About you", color: Palette.inkFaint, size: 10)
        bioView.backgroundColor = .clear
        bioView.font = Typeface.body(14.5)
        bioView.textColor = Palette.ink
        bioView.tintColor = Palette.terracotta
        bioView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        bioView.delegate = self

        bioPlaceholder.text = "A few lines about what you make, how you work, or what you are learning."
        bioPlaceholder.font = Typeface.body(14.5)
        bioPlaceholder.textColor = Palette.inkFaint.withAlphaComponent(0.8)
        bioPlaceholder.numberOfLines = 0

        bioCard.addSubviews(bioView, bioPlaceholder)
        NSLayoutConstraint.activate([
            bioView.topAnchor.constraint(equalTo: bioCard.topAnchor, constant: 2),
            bioView.leadingAnchor.constraint(equalTo: bioCard.leadingAnchor, constant: 4),
            bioView.trailingAnchor.constraint(equalTo: bioCard.trailingAnchor, constant: -4),
            bioView.bottomAnchor.constraint(equalTo: bioCard.bottomAnchor, constant: -2),
            bioView.heightAnchor.constraint(equalToConstant: 128),
            bioPlaceholder.topAnchor.constraint(equalTo: bioCard.topAnchor, constant: 14),
            bioPlaceholder.leadingAnchor.constraint(equalTo: bioCard.leadingAnchor, constant: 15),
            bioPlaceholder.trailingAnchor.constraint(equalTo: bioCard.trailingAnchor, constant: -15)
        ])

        let stack = UIStackView(
            axis: .vertical,
            spacing: 18,
            views: [avatarHolder, hint, fieldsCard, bioTitle, bioCard]
        )
        stack.setCustomSpacing(10, after: avatarHolder)
        stack.setCustomSpacing(26, after: hint)
        stack.setCustomSpacing(10, after: bioTitle)

        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .interactive
        scroll.addSubview(stack)
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 16),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -30),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
    }

    private func populate() {
        let profile = store.currentProfile
        nameField.textField.text = profile.displayName
        craftField.textField.text = profile.craft
        locationField.textField.text = profile.location
        bioView.text = profile.bio
        bioPlaceholder.isHidden = !profile.bio.isEmpty
        avatar.configure(
            assetName: profile.avatarAsset,
            fileName: profile.avatarFile,
            remoteURL: profile.avatarRemoteURL,
            avatar: true,
            monogram: profile.displayName
        )
    }

    @objc private func avatarTapped() {
        Haptics.tap()
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func save() {
        let name = nameField.text.trimmed
        guard !name.isEmpty else {
            showToast("Your display name can't be empty.", icon: "exclamationmark")
            return
        }
        let avatarFile = pendingAvatarFile
        let bio = bioView.text ?? ""
        let location = locationField.text
        let craft = craftField.text
        let store = self.store
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await LoadingVeil.run(message: "Updating your profile…") {
                    try await store.updateProfile(
                        displayName: name,
                        bio: bio,
                        location: location,
                        craft: craft,
                        avatarFile: avatarFile
                    )
                }
                Haptics.success()
                self.showToast("Profile updated", icon: "checkmark")
                self.navigationController?.popViewController(animated: true)
            } catch {
                Haptics.warn()
                self.showToast(error.localizedDescription, icon: "exclamationmark")
            }
        }
    }
}

extension EditProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        bioPlaceholder.isHidden = !textView.text.isEmpty
    }
}

extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard
            let provider = results.first?.itemProvider,
            provider.canLoadObject(ofClass: UIImage.self)
        else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            let compressed = image.downscaled(maxDimension: 900)
            DispatchQueue.main.async {
                guard let self else { return }
                if let fileName = MediaLibrary.saveImage(compressed) {
                    self.pendingAvatarFile = fileName
                    self.avatar.configure(
                        assetName: "avatar_me",
                        fileName: fileName,
                        avatar: true,
                        monogram: self.nameField.text
                    )
                    Haptics.success()
                }
            }
        }
    }
}

extension UIImage {
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
