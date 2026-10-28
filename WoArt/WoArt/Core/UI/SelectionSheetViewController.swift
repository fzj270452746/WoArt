import UIKit

final class SelectionSheetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    struct Item {
        let title: String
        let subtitle: String?

        init(title: String, subtitle: String? = nil) {
            self.title = title
            self.subtitle = subtitle
        }
    }

    private let sheetTitle: String
    private let items: [Item]
    private let onSelect: (Int) -> Void
    private let tableView = UITableView(frame: .zero, style: .plain)

    static func present(
        from presenter: UIViewController,
        title: String,
        items: [Item],
        onSelect: @escaping (Int) -> Void
    ) {
        let controller = SelectionSheetViewController(title: title, items: items, onSelect: onSelect)
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 34
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        presenter.present(controller, animated: true)
    }

    private init(title: String, items: [Item], onSelect: @escaping (Int) -> Void) {
        sheetTitle = title
        self.items = items
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.paper

        let titleLabel = UILabel()
        titleLabel.text = sheetTitle
        titleLabel.font = Typeface.display(26, weight: .bold)
        titleLabel.textColor = Palette.ink
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SelectionCell.self, forCellReuseIdentifier: SelectionCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 20, right: 0)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        62
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectionCell.reuseID, for: indexPath) as! SelectionCell
        cell.configure(item: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        Haptics.tap()
        let index = indexPath.row
        dismiss(animated: true) { [onSelect] in
            onSelect(index)
        }
    }
}

private final class SelectionCell: UITableViewCell {
    static let reuseID = "SelectionCell"

    private let card = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = Palette.card
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.ink.withAlphaComponent(0.05).cgColor
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = Typeface.chip(15, weight: .semibold)
        titleLabel.textColor = Palette.ink
        subtitleLabel.font = Typeface.body(11.5)
        subtitleLabel.textColor = Palette.inkFaint

        let stack = UIStackView(axis: .vertical, spacing: 2, views: [titleLabel, subtitleLabel])
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(item: SelectionSheetViewController.Item) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil
    }
}
