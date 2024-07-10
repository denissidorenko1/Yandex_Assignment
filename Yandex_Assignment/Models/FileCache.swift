import Foundation

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
