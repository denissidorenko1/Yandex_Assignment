import Foundation

// состояние работы с вью
enum ViewState {
    case editing
    case adding
}

@Observable
final class TaskViewModel: TaskViewModelManageable {
    var item: TodoItem
    var viewState: ViewState
    weak var itemListVM: ListViewManageable?
    var categories: [Category] = []

    var categoryManager = CategoryManager()

    init(
        item: TodoItem,
        itemListViewModel: ListViewManageable,
        viewState: ViewState
    ) {
        self.item = item
        self.itemListVM = itemListViewModel
        self.viewState = viewState
        updateCategories()
    }

    func add(newItem: TodoItem) {
        guard let itemListVM else {return}

        switch viewState {
        case .editing:
            edit(newValue: newItem)
        case .adding:
            itemListVM.add(newItem: newItem)
            itemListVM.save()
        }
    }

    func delete() {
        guard let itemListVM else {return}

        switch viewState {
        case .editing:
            itemListVM.delete(with: item.id)
            itemListVM.save()
        case .adding:
            return
        }

    }

    func updateCategories() {
        categoryManager.load()
        categories = categoryManager.categories
    }

    func edit(newValue: TodoItem) {
        guard let itemListVM else {return}
        switch viewState {
        case .editing:

            // обновим дату редактирования
            let newVersion = TodoItem(
                id: newValue.id,
                text: newValue.text,
                priority: newValue.priority,
                deadLineDate: newValue.deadLineDate,
                isCompleted: newValue.isCompleted,
                creationDate: newValue.creationDate,
                changeDate: .now,
                hex: newValue.hex,
                category: newValue.category
            )
            itemListVM.update(with: item.id, newVersion: newVersion)
            itemListVM.save()
        case .adding:
            return
        }
    }
}

protocol TaskViewModelManageable: AnyObject {
    var item: TodoItem {get}

    var categories: [Category] {get}

    var viewState: ViewState {get}

    var itemListVM: ListViewManageable? {get}

    func add(newItem: TodoItem)

    func delete()

    func edit(newValue: TodoItem)

    func updateCategories()
}
