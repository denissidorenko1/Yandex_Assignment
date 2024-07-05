import UIKit

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
