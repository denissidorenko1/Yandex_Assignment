import Foundation
import CocoaLumberjackSwift

@Observable
final class ItemListViewModel: ListViewManageable, Sendable {
    private let url: URL
    private let fileName: String
    private let cacher: ItemCacher
    private(set) var doneItemsCount: Int
    private(set) var itemList: [TodoItem] = []
    private let networkHandler: NetworkingDataHandler
    
    var isDoneShown: Bool = false { didSet {
        fetch()
    }}

    init(
        cacher: ItemCacher,
        url: URL = URL(fileURLWithPath: ""),
        fileName: String = "smth.json",
        
        networkHandler: NetworkingDataHandler = NetworkingDataHandler.shared
    ) {
        self.cacher = cacher
        self.url = url
        self.fileName = fileName
        self.doneItemsCount = 0
        self.networkHandler = networkHandler
        DDLogInfo("\(Self.self) инициализирован")
    }

    func fetch() {
        do {
            if isDoneShown {
                try cacher.loadAllItemsFromFile(with: url, fileName: fileName)
                Task {
                    let allItems = try await networkHandler.getAll()
                    doneItemsCount = allItems.filter {$0.isCompleted == true}.count
                    itemList = allItems.sorted(by: { left, right in
                        left.creationDate > right.creationDate
                    })
                }
            } else {
                try cacher.loadAllItemsFromFile(with: url, fileName: fileName)
                Task {
                    let allItems = try await networkHandler.getAll()
                    doneItemsCount = allItems.filter {$0.isCompleted == true}.count
                    itemList = allItems.filter {$0.isCompleted == false}.sorted(by: { left, right in
                        left.creationDate > right.creationDate
                    })
                }
            }
            DDLogInfo("Items fetched from \(Self.self)")
        } catch {
            DDLogError("Fetch failed from \(Self.self)")
            print(error)
        }
        
    }
    
    func requestNetworkList() async {
        do {
            let allData = try await networkHandler.getAll()
            itemList = allData
        } catch {
            print(error)
            DDLogError("Network request failed from \(Self.self) with error \(error)")
        }
    }

    func toggleDone(with id: String)  {
        guard let item = cacher.items[id] else {  return }
        let newItem = TodoItem(
            id: item.id,
            text: item.text,
            priority: item.priority,
            deadLineDate: item.deadLineDate,
            isCompleted: !item.isCompleted,
            creationDate: item.creationDate,
            changeDate: item.changeDate,
            hex: item.hex
        )
        do {
            try cacher.editItem(with: id, newVersion: newItem)
            Task {
                try await networkHandler.editItem(with: newItem)
                save()
                DDLogInfo("Статус изменен в \(Self.self) с \(id) id")
                return
            }
        } catch {
            DDLogError("Изменение кэшера и сохранение в \(Self.self) упало")
            print(error)
        }

    }

    func add(newItem: TodoItem) {
        do {
            try cacher.addNewItem(with: newItem)
            Task {
                try await networkHandler.addNew(with: newItem)
            }
            save()
            DDLogInfo("Тудушка \(newItem) сохранена из \(Self.self)")
        } catch {
            DDLogError("Добавление и сохранение в \(Self.self) упало")
            print(error)
        }

    }

    func delete(with id: String) {
        cacher.deleteItem(with: id)
            Task {
                try await networkHandler.deleteByID(with: id)
            }
        save()
    }

    func update(with id: String, newVersion: TodoItem) {
        do {
            try cacher.editItem(with: id, newVersion: newVersion)
            Task {
                try await networkHandler.editItem(with: newVersion)
            }
            save()
            DDLogInfo("Тудушка обновлена из \(Self.self) с новой версией \(newVersion)")
        } catch {
            DDLogError("Обновление и сохранение упало в \(Self.self)")
            print(error)
        }

    }

    func save() {
        do {
            try cacher.saveAllItemsToFile(with: url, filename: fileName)
            fetch()
            DDLogInfo("Все тудушки сохранены и перезагружены в \(Self.self)")
        } catch {
            DDLogError("Сохранение и обновление тудушек упало в \(Self.self)")
            print(error)
        }
    }

}

protocol ListViewManageable: AnyObject {
    var doneItemsCount: Int { get }

    var itemList: [TodoItem] { get }

    var isDoneShown: Bool { get set }

    func toggleDone(with id: String) async

    func fetch()

    func delete(with id: String)

    func update(with id: String, newVersion: TodoItem)

    func add(newItem: TodoItem)

    func save()
    
    func requestNetworkList() async
}
