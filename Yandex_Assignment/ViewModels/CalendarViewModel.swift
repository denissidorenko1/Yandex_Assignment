//
//  CalendarViewModel.swift
//  Yandex_Assignment
//
//  Created by Denis on 04.07.2024.
//

import Foundation

final class CalendarViewModel {
    private let url: URL
    private let fileName: String

    weak var itemListVM: ListViewManageable?
    let model: ItemCacher

    var itemsGroupedByDate: [Date?: [TodoItem]] = [:]
    var sortedKeys: [Date?] = []

    init(
        model: ItemCacher,
        itemListViewModel: ListViewManageable?,
        url: URL = URL(fileURLWithPath: ""),
        fileName: String = "smth.json"
    ) {
        self.model = model
        self.url = url
        self.fileName = fileName
        self.itemListVM = itemListViewModel
    }

    func fetch() {
        do {
            try model.loadAllItemsFromFile(with: url, fileName: fileName)
            itemListVM?.fetch()
            sortDates()
            groupDates()
        } catch {
            print(error.localizedDescription)
        }
    }

    func setItemDone(with id: String) {
        guard let item = model.items[id] else { return }
        let newItem = TodoItem(
            id: item.id,
            text: item.text,
            priority: item.priority,
            deadLineDate: item.deadLineDate,
            isCompleted: !item.isCompleted,
            creationDate: item.creationDate,
            changeDate: item.changeDate,
            hex: item.hex,
            category: item.category
        )
        do {
            try model.editItem(with: id, newVersion: newItem)
            save()
        } catch {
            print(error)
        }
    }

    func save() {
        do {
            try model.saveAllItemsToFile(with: url, filename: fileName)
            fetch()
        } catch {
            print(error)
        }
    }

    // сортируем ключи для верхней части календаря
    private func sortDates() {
        var dates: Set<Date?> = []
        for item in model.items {
            dates.insert(item.value.deadLineDate.map {Calendar.current.startOfDay(for: $0)})
        }
        sortedKeys = dates.sorted(by: { left, right in
            if let left = left, let right = right {
                return left < right
            } else {
                if left == nil {
                    return false
                } else {
                    return true
                }
            }
        })
    }

    // группируем даты по ключам, и сортируем их чтобы при обновлении не перемешивались
    private func groupDates() {
        itemsGroupedByDate = [:]
        for item in model.items {
            if let dat = item.value.deadLineDate {
                itemsGroupedByDate[Calendar.current.startOfDay(for: dat), default: []].append(item.value)
            } else {
                itemsGroupedByDate[nil, default: []].append(item.value)
            }
        }

        for key in itemsGroupedByDate.keys {
            itemsGroupedByDate[key]! = itemsGroupedByDate[key]!.sorted(by: { left, right in
                return left.id < right.id
            })
        }
    }
}
