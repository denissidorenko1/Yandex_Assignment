import UIKit
import SwiftUI

class CalendarView: UIViewController {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    let addNewButton =  UIButton()
    
    var viewModel: CalendarViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupCollectionView()
        registerCells()
        view.addSubview(tableView)
        view.addSubview(collectionView)
        view.addSubview(addNewButton)
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
                    vm: itemListVM,
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
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            
            view.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: collectionView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: tableView.topAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 80),
            
            
            addNewButton.heightAnchor.constraint(equalToConstant: 44),
            addNewButton.widthAnchor.constraint(equalToConstant: 44),
            addNewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addNewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -75)
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

// MARK: - UITableViewDataSource
extension CalendarView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.itemsGroupedByDate.keys.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let date = viewModel.sortedKeys[section] {
            return date.getFormattedDateString()
        } else {
            return "Другое"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.itemsGroupedByDate[viewModel.sortedKeys[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CalendarViewItemCell.ReuseId
        ) as? CalendarViewItemCell else  { return UITableViewCell() }
        if let date = viewModel.itemsGroupedByDate[viewModel.sortedKeys[indexPath.section]] {
            cell.setContent(with: date[indexPath.item])
        }
        cell.sectionIndex = indexPath.section
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CalendarView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        55
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let changeStatusAction = UIContextualAction(style: .normal, title: "Поменять") { [weak self] (_, _, completionHandler)  in
            // FIXME: - рефакторить
            if let date = self?.viewModel.itemsGroupedByDate[self?.viewModel.sortedKeys[indexPath.section]] {
                self?.viewModel.setItemDone(with: date[indexPath.item].id)
                self?.viewModel.fetch()
                self?.tableView.reloadData()
            }
            completionHandler(true)
        }
        changeStatusAction.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [changeStatusAction])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView {
            guard let visibleCells = tableView.visibleCells as? [CalendarViewItemCell],
                  let firstVisibleCell = visibleCells.first else { return }
            guard let index = firstVisibleCell.sectionIndex else { return }
            deselectAll()
            let targetIndexPath = IndexPath(item: index, section: 0)
            selectTapped(didSelectItemAt: targetIndexPath)
            collectionView.scrollToItem(at: targetIndexPath, at: .left, animated: true)
        }
    }

}

// MARK: - UICollectionViewDelegate
extension CalendarView: UICollectionViewDelegate {
    func deselectAll() {
        collectionView.visibleCells.forEach { cell in
            if let ident = cell as? CalendarViewDateCell {
                ident.deselect()
            }
        }
    }
    
    func selectTapped(didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? CalendarViewDateCell else { return }
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4) {
                cell.makeSelected()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deselectAll()
        let ip = IndexPath(row: 0, section: indexPath.item)
        tableView.scrollToRow(at: ip, at: .top, animated: true)
        selectTapped(didSelectItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}

// MARK: - UICollectionViewDataSource
extension CalendarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.sortedKeys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarViewDateCell.ReuseId, for: indexPath) as? CalendarViewDateCell else { return UICollectionViewCell() }
        cell.deselect()
        cell.setContent(with: viewModel.sortedKeys[indexPath.item])
        return cell
    }
    
    
}
