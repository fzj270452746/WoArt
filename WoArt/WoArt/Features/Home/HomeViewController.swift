import UIKit

final class HomeViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, PostCardCellDelegate {
    private var collectionView: UICollectionView!
    private let refreshControl = UIRefreshControl()
    private let store = StudioStore.shared
    private var posts: [Post] = []
    private var visibleCount = 6
    private var isLoadingMore = false

    override func viewDidLoad() {
        super.viewDidLoad()
        buildCollection()
        posts = Array(store.feed.prefix(visibleCount))
        collectionView.reloadData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .studioDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataChanged),
            name: .authDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncFromStore()
        store.refreshAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateInlineVideoPlayback()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseInlineVideos()
    }

    // MARK: - Building

    private func buildCollection() {
        let layout = UICollectionViewCompositionalLayout { section, _ in
            switch section {
            case 0:
                let size = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(320)
                )
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 0, trailing: 0)
                return section

            case 1:
                let size = NSCollectionLayoutSize(
                    widthDimension: .absolute(220),
                    heightDimension: .absolute(176)
                )
                let item = NSCollectionLayoutItem(layoutSize: size)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 10
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 22, bottom: 8, trailing: 22)
                return section

            default:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .estimated(320)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 14
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .estimated(80)
                    ),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]
                return section
            }
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Metrics.contentBottomInset, right: 0)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.decelerationRate = .normal
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HomeMastheadCell.self, forCellWithReuseIdentifier: HomeMastheadCell.reuseID)
        collectionView.register(EventCardCell.self, forCellWithReuseIdentifier: EventCardCell.reuseID)
        collectionView.register(PostCardCell.self, forCellWithReuseIdentifier: PostCardCell.reuseID)
        collectionView.register(FeedEmptyCell.self, forCellWithReuseIdentifier: FeedEmptyCell.reuseID)
        collectionView.register(
            HomeFeedHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeFeedHeaderView.reuseID
        )

        refreshControl.tintColor = Palette.terracotta
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data

    private func syncFromStore() {
        let fresh = Array(store.feed.prefix(visibleCount))
        let changed = fresh.map(\.id) != posts.map(\.id)
        posts = fresh
        if changed {
            collectionView.reloadData()
            DispatchQueue.main.async { [weak self] in
                self?.updateInlineVideoPlayback()
            }
        } else {
            refreshVisibleCells()
        }
    }

    @objc private func dataChanged() {
        syncFromStore()
    }

    private func refreshVisibleCells() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            if indexPath.section == 0, let cell = collectionView.cellForItem(at: indexPath) as? HomeMastheadCell {
                cell.update(store: store)
            }
            if indexPath.section == 1,
               let cell = collectionView.cellForItem(at: indexPath) as? EventCardCell,
               indexPath.item < store.upcomingEvents.count {
                let event = store.upcomingEvents[indexPath.item]
                cell.configure(
                    event: event,
                    host: store.maker(id: event.hostID),
                    seatsLeft: store.seatsLeft(for: event)
                )
            }
            if indexPath.section == 2,
               !posts.isEmpty,
               indexPath.item < posts.count,
               let cell = collectionView.cellForItem(at: indexPath) as? PostCardCell {
                cell.configure(post: posts[indexPath.item], index: indexPath.item, store: store)
            }
        }
        if let header = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 2)
        ) as? HomeFeedHeaderView {
            header.update(count: store.feed.count)
        }
    }

    @objc private func refreshPulled() {
        visibleCount = max(visibleCount, 6)
        store.refreshHome { [weak self] in
            DispatchQueue.main.async {
                self?.syncFromStore()
                self?.refreshControl.endRefreshing()
            }
        }
    }

    private func loadMore() {
        let total = store.feed.count
        guard posts.count < total, !isLoadingMore else { return }
        isLoadingMore = true
        let oldCount = posts.count
        let newCount = min(total, oldCount + 4)
        posts = Array(store.feed.prefix(newCount))
        let indexPaths = (oldCount..<newCount).map { IndexPath(item: $0, section: 2) }
        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        } completion: { [weak self] _ in
            self?.isLoadingMore = false
        }
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return store.upcomingEvents.count
        default: return posts.isEmpty ? 1 : posts.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeMastheadCell.reuseID,
                for: indexPath
            ) as! HomeMastheadCell
            cell.update(store: store)
            cell.onOpenProfile = { [weak self] in self?.switchTab(3) }
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EventCardCell.reuseID,
                for: indexPath
            ) as! EventCardCell
            let event = store.upcomingEvents[indexPath.item]
            cell.configure(
                event: event,
                host: store.maker(id: event.hostID),
                seatsLeft: store.seatsLeft(for: event)
            )
            cell.onOpen = { [weak self, weak cell] in
                guard let self, cell != nil else { return }
                let detail = EventDetailViewController(eventID: event.id)
                self.navigationController?.pushViewController(detail, animated: true)
            }
            return cell

        default:
            if posts.isEmpty {
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: FeedEmptyCell.reuseID,
                    for: indexPath
                )
            }
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PostCardCell.reuseID,
                for: indexPath
            ) as! PostCardCell
            let post = posts[indexPath.item]
            cell.configure(post: post, index: indexPath.item, store: store)
            cell.delegate = self
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: HomeFeedHeaderView.reuseID,
            for: indexPath
        ) as! HomeFeedHeaderView
        header.update(count: store.feed.count)
        return header
    }

    // MARK: - Scroll

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        updateInlineVideoPlayback()
        let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height
        if remaining < 420 {
            loadMore()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? PostCardCell)?.pauseVideo()
    }

    /// Films start on their own once enough of the card is in view, and stop
    /// as soon as the reader scrolls past it.
    private func updateInlineVideoPlayback() {
        for indexPath in collectionView.indexPathsForVisibleItems where indexPath.section == 2 {
            guard
                indexPath.item < posts.count,
                posts[indexPath.item].media.contains(where: { $0.kind == .video }),
                let cell = collectionView.cellForItem(at: indexPath) as? PostCardCell
            else { continue }

            let frame = cell.convert(cell.bounds, to: collectionView)
            let shown = collectionView.bounds.intersection(frame)
            let ratio = shown.isNull ? 0 : shown.height / max(frame.height, 1)
            if ratio > 0.55 {
                cell.playVideoIfNeeded()
            } else {
                cell.pauseVideo()
            }
        }
    }

    private func pauseInlineVideos() {
        for indexPath in collectionView.indexPathsForVisibleItems {
            (collectionView.cellForItem(at: indexPath) as? PostCardCell)?.pauseVideo()
        }
    }

    // MARK: - PostCardCellDelegate

    func postCard(_ cell: PostCardCell, didOpen post: Post) {
        let detail = PostDetailViewController(postID: post.id)
        navigationController?.pushViewController(detail, animated: true)
    }

    func postCard(_ cell: PostCardCell, didToggleLike post: Post) {
        guard AuthGate.requireLogin(from: self, then: { [weak self] in
            self?.applyLike(post)
        }) else { return }
        applyLike(post)
    }

    private func applyLike(_ post: Post) {
        let liked = store.toggleLike(postID: post.id)
        if liked { Haptics.success() }
        syncFromStore()
    }

    // MARK: - Helpers

    private func switchTab(_ index: Int) {
        (navigationController?.parent as? RootShellViewController)?.selectTab(index: index)
    }
}
