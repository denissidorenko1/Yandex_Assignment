import Foundation
import SwiftData
import SwiftUI
@_spi(Public) import MyPackage
// MARK: - FileCache, реализующий протокол с указанными требованиями
final class FileCache: ItemCacher {
    enum CacherErrors: Error {
        case itemDuplicationError
        case writeError
        case readError
        case invalidPath
        case encodingError
        case unknownError
        case nothingToEdit
    }
    
    // MARK: - хранение в SwiftData
    let container: ModelContainer
    private var modelContext: ModelContext
    private(set) var persistentItems: [TodoItem] = []
    
    // лучше быстро упасть, чем не заметить ошибку
    init(container: ModelContainer = try! ModelContainer(for: TodoItem.self)) {
        self.container = container
        self.modelContext = ModelContext(container)
    }
    
    func deleteAll() {
        do {
            try modelContext.delete(model: TodoItem.self)
            fetch()
        } catch {
            print("Failed to delete all items: \(error)")
        }
    }
    
    func fetch() {
        do {
            let descriptor: FetchDescriptor<TodoItem> = FetchDescriptor()
            let fetchedItems =  try modelContext.fetch(descriptor)
            persistentItems = fetchedItems
            try modelContext.save()
        } catch {
            print("Failed to fetch items: \(error)")
        }
    }
    
    func delete(_ todoItem: TodoItem) {
        modelContext.delete(todoItem)
        fetch()
    }
    
    func update(_ todoItem: TodoItem) {
        /*
         Это самый странный костыль что я писал за последнее время. в чем суть:
         У нас есть 2 айтема: старый и новый, id совпадают. У контекста нет метода обновления (в нашем функционале без вью)
         Обновить через insert - не вариант, оно падает при совпадении ключей, удалить старый и добавить новый не выходит по той же причине (наверно старый где-то в истории валяется
         и мешает)
         Что делаем? Смотрим что возвращает метод model - any PersistentModel,
         PersistentModel подписан на AnyObject и является reference типом
         Идем по ссылке и меняем элемент!
         */
        var toDelete = modelContext.model(for: todoItem.persistentModelID)
        toDelete = todoItem
        fetch()
    }
    
    func insert(_ todoItem: TodoItem) {
        modelContext.insert(todoItem)
        fetch()
    }
    
    func fetch(
        include: ((TodoItem) -> Bool)? = nil,
        // ААААА в SwiftData не работают дженерики, придется ставить костыль
        key: TodoItem.FieldDescriptor? = nil
    ) {
        do {
            var sorter: SortDescriptor<TodoItem>?
            switch key {
            case .id:
                sorter = SortDescriptor(\.id)
            case .text:
                sorter = SortDescriptor(\.text)
            case .priority:
                // почему не может сортировать по приоритету с имплементацией Comparable?
                sorter = SortDescriptor(\.priority.rawValue)
            case .deadLineDate:
                sorter = SortDescriptor(\.deadLineDate)
            case .isCompleted:
                // почему SortDescriptor не может сортировать по логическому значению?
                sorter = SortDescriptor(\.isCompleted.description)
            case .creationDate:
                sorter = SortDescriptor(\.creationDate)
            case .changeDate:
                sorter = SortDescriptor(\.changeDate)
            case .hex:
                sorter = SortDescriptor(\.hex)
            case .categoryName:
                sorter = SortDescriptor(\.category?.name)
            case .categoryColor:
                sorter = SortDescriptor(\.category?.hexColor)
            case nil:
                sorter = SortDescriptor(\.creationDate)
            }
            let descriptor: FetchDescriptor<TodoItem> = FetchDescriptor(sortBy: [sorter!])
            let fetchedItems = try modelContext.fetch(descriptor)
            persistentItems = fetchedItems.filter({ item in
                if include != nil {
                    return include!(item)
                }
                return true
            })
        } catch {
            print("Failed to fetch items: \(error)")
        }
    }

    // MARK: - файловое хранение
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    // используем словарь для O(1) обращений по ключу
    private(set)var items: [String: TodoItem] = [:]

    func addNewItem(with item: TodoItem) throws {
        // обрабатываем случай дублирования: бросаем ошибку если пытаемся записать уже хранящееся значение
        guard self.items[item.id] == nil else { throw CacherErrors.itemDuplicationError}
        self.items[item.id] = item
    }

    func deleteItem(with id: String) {
        items[id] = nil
    }

    // наверно, лучше бы сначала
    func editItem(with id: String, newVersion: TodoItem) throws {
        guard items[id] != nil else {throw CacherErrors.nothingToEdit}
        items[id] = newVersion
    }

    func saveAllItemsToFile(with fileURL: URL, filename: String) throws {
        // кастим все item-ы к Data, потом [Data] кодируем в Data
        guard let jsonData = try? encoder.encode(items.values
            .compactMap {$0.json as? Data}) else { throw CacherErrors.encodingError }
        // набираем путь до директории + название файла
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
            in: .userDomainMask).first else { throw CacherErrors.invalidPath }
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        // пишем Data в память
        guard ((try? jsonData.write(to: fileURL, options: .atomic)) != nil) else { throw CacherErrors.writeError }
    }

    func loadAllItemsFromFile(with fileURL: URL, fileName: String) throws {
        // вспомогательная функция для конвертации массива в словарь
        func fillCacheWithNewValues(arr: [TodoItem]) {
            for element in arr {
                self.items[element.id] = element
            }
        }

        // ищем файл
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first else { throw CacherErrors.invalidPath }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        // Получаем Data по пути
        guard let encodedData = try? Data(contentsOf: fileURL) else { throw CacherErrors.readError }
        // декодируем Data в [Data], затем парсим их
        guard let toDoItems = try? decoder.decode([Data].self, from: encodedData)
            .compactMap({TodoItem.parse(json: $0)}) else { throw CacherErrors.readError}

        // обновляем словарь загруженными данными
        items = [:]
        fillCacheWithNewValues(arr: toDoItems)
    }

}

// MARK: - протокол с набором требований из ТЗ
protocol ItemCacher {
    var items: [String: TodoItem] { get }

    func addNewItem(with item: TodoItem) throws

    func deleteItem(with id: String)

    func editItem(with id: String, newVersion: TodoItem) throws

    func saveAllItemsToFile(with fileURL: URL, filename: String) throws

    func loadAllItemsFromFile(with fileURL: URL, fileName: String) throws

}
