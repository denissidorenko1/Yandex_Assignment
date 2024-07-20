import UIKit
import SwiftUI

final class CalendarView: UIViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    let addNewButton =  UIButton()
    let separator = UILabel()

    var viewModel: CalendarViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCollectionView()
        registerCells()
        view.addSubview(tableView)
        view.addSubview(collectionView)
        view.addSubview(addNewButton)
        view.addSubview(separator)
        setupConstraints()
        setupActions()
        setupStyles()
        viewModel.fetch()
    }

    private func setupStyles() {
        view.backgroundColor = .backPrimary
        collectionView.backgroundColor = .backPrimary
        tableView.backgroundColor = .backPrimary

        addNewButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addNewButton.imageView?.contentMode = .scaleAspectFill
        addNewButton.contentVerticalAlignment = .fill
        addNewButton.contentHorizontalAlignment = .fill
        addNewButton.layer.shadowColor = UIColor.black.cgColor
        addNewButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        addNewButton.layer.shadowRadius = 10
        addNewButton.layer.shadowOpacity = 0.5

        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsMultipleSelection = false

        separator.backgroundColor = .separator
    }

    private func setupActions() {
        addNewButton.addAction(UIAction { [weak self] _ in
            guard let itemListVM = self?.viewModel.itemListVM else { return }
            let hostingController = UIHostingController(
                rootView: TaskView(
                    item: TodoItem(
                        text: "",
                        priority: .usual,
                        isCompleted: false,
                        hex: nil
                    ),
                    viewModel: itemListVM,
                    viewState: .adding
                )
            )
            self?.navigationController?.pushViewController(hostingController, animated: true)
        }, for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.fetch()
        tableView.reloadData()
        collectionView.reloadData()
        selectTapped(didSelectItemAt: IndexPath(row: 0, section: 0))
    }

    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addNewButton.translatesAutoresizingMaskIntoConstraints = false
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),

            view.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: collectionView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: separator.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.bottomAnchor.constraint(equalTo: tableView.topAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 80),

            addNewButton.heightAnchor.constraint(equalToConstant: 44),
            addNewButton.widthAnchor.constraint(equalToConstant: 44),
            addNewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addNewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -75),

            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 70)
        collectionView.collectionViewLayout = layout
    }

    private func setupCollectionView() {
        setupCollectionViewLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func registerCells() {
        tableView.register(CalendarViewItemCell.self, forCellReuseIdentifier: CalendarViewItemCell.ReuseId)
        collectionView.register(CalendarViewDateCell.self, forCellWithReuseIdentifier: CalendarViewDateCell.ReuseId)
    }
}
