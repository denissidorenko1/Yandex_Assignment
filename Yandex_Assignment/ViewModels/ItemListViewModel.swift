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
        print("fetching")
        do {
            if isDoneShown {
                try cacher.loadAllItemsFromFile(with: url, fileName: fileName)
//                doneItemsCount = cacher.items.values.filter {$0.isCompleted == true}.count
//                itemList = cacher.items.values.map {$0}.sorted(by: { left, right in
//                    left.creationDate > right.creationDate
//                })
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
//                doneItemsCount = cacher.items.values.filter {$0.isCompleted == true}.count
//                itemList = cacher.items.values.map {$0}.filter {$0.isCompleted == false}.sorted(by: { left, right in
//                    left.creationDate > right.creationDate
//                })
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
            DDLogError("Network request failed from \(Self.self)")
        }
    }

    func toggleDone(with id: String)  {
        print("done toggled")
        guard let item = cacher.items[id] else { 
            print("no id in cacher");  return }
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
//                print("trying to toggle")
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
        print("added")
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
        print("deleting")
        cacher.deleteItem(with: id)
        do {
            Task {
                try await networkHandler.deleteByID(with: id)
            }
        } catch {
            print("ошибка удаления")
            DDLogError("Удаление \(Self.self) упало")
        }
        save()
    }

    func update(with id: String, newVersion: TodoItem) {
        print("updating")
        do {
            try cacher.editItem(with: id, newVersion: newVersion)
            Task {
                // тут выпало исключение
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
        print("saving")
        do {
            try cacher.saveAllItemsToFile(with: url, filename: fileName)
            // если пытаться обновить все то упадет добавление
//            Task {
//                try await networkHandler.updateAll(with: itemList)
//            }
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
