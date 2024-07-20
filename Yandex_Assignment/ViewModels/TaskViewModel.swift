import Foundation
import CocoaLumberjackSwift
@_spi(Public) import MyPackage

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
    var categories: [Activity] = []

    var categoryManager = CategoryManager()
    let networkHandler: DefaultNetworkingService = DefaultNetworkingService.shared

    init(
        item: TodoItem,
        itemListViewModel: ListViewManageable,
        viewState: ViewState
    ) {
        self.item = item
        self.itemListVM = itemListViewModel
        self.viewState = viewState
        DDLogInfo("\(Self.self) инициализировано с состоянием \(viewState)")
        updateCategories()
    }

    func add(newItem: TodoItem) {
        guard let itemListVM else {return}
        switch viewState {
        case .editing:
            DDLogInfo("\(Self.self) изменяет данные с айтемом \(newItem)")
            edit(newValue: newItem)
        case .adding:
            DDLogInfo("\(Self.self) добавляет данные с айтемом \(newItem)")
            itemListVM.add(newItem: newItem)
            itemListVM.save()
        }
    }

    func delete() {
        guard let itemListVM else {
            DDLogWarn("ItemListVM не инициализирован")
            return
        }

        switch viewState {
        case .editing:
            itemListVM.delete(with: item.id)
            itemListVM.save()
            DDLogInfo("\(Self.self) удаляет айтем с id \(item.id)")
        case .adding:
            DDLogWarn("\(Self.self) пытается удалить данные из режима добавления, это так не должно рабоать")
            return
        }

    }

    func updateCategories() {
        categoryManager.load()
        categories = categoryManager.categories
        DDLogInfo("Обновление данных в \(Self.self)")
    }

    func edit(newValue: TodoItem) {
        guard let itemListVM else {
            DDLogWarn("ItemListVM не инициализирован")
            return
        }
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
            DDLogInfo("\(Self.self) редактирует данные с новым айтемом \(newValue)")
        case .adding:
            DDLogWarn("\(Self.self) пытается изменить данные из режима добавления, это так не должно работать")
            return
        }
    }
}

protocol TaskViewModelManageable: AnyObject {
    var item: TodoItem {get}

    var categories: [Activity] {get}

    var viewState: ViewState {get}

    var itemListVM: ListViewManageable? {get}

    func add(newItem: TodoItem)

    func delete()

    func edit(newValue: TodoItem)

    func updateCategories()
}
