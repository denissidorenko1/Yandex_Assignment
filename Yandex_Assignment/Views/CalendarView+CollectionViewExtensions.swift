import UIKit

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
