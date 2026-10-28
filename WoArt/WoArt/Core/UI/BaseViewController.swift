import UIKit

class BaseViewController: UIViewController {
    let backdrop = StudioBackdropView()

    /// Screens pushed above a first-level page hide the floating dock.
    var hidesDock: Bool { false }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.paper
        view.addSubview(backdrop)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        backdrop.pinEdges(to: view)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func pinTopBar(_ bar: UIView, topInset: CGFloat = 6) {
        view.addSubview(bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Metrics.gutter),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Metrics.gutter),
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topInset)
        ])
    }

    func configureBackBar(_ bar: DetailTopBar) {
        bar.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        pinTopBar(bar)
    }
}

extension UIView {
    func addPinned(_ child: UIView, insets: UIEdgeInsets = .zero) {
        addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            child.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            child.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            child.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
}
