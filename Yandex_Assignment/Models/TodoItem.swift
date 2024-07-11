import Foundation
@_spi(Public) import MyPackage
// MARK: - структура ToDoItem
struct TodoItem {
    enum Priority: String {
        case unimportant
        case usual
        case important
    }

    let id: String
    let text: String
    let priority: Priority
    let deadLineDate: Date?
    let isCompleted: Bool
    let creationDate: Date
    let changeDate: Date?
    let hex: String?
    let category: Activity

    init(
        id: String = UUID().uuidString,
        text: String,
        priority: Priority,
        deadLineDate: Date? = nil,
        isCompleted: Bool,
        creationDate: Date = .now,
        changeDate: Date? = nil,
        hex: String?,
        category: Activity = Activity(name: "Другое", hexColor: "FFFFFF")
    ) {
        self.id = id
        self.text = text
        self.priority = priority
        self.deadLineDate = deadLineDate
        self.isCompleted = isCompleted
        self.creationDate = creationDate
        self.changeDate = changeDate
        self.hex = hex
        self.category = category
    }
}

// MARK: - расширение для работы с JSON-ом
extension TodoItem {
    // описатель полей JSON-а, всяко удобней чем строки хардкодить
    enum FieldDescriptor: String {
        case id
        case text
        case priority
        case deadLineDate
        case isCompleted
        case creationDate
        case changeDate
        case hex
        case categoryName
        case categoryColor
    }

    static func parse(json: Any) -> TodoItem? {
        guard let data = json as? Data else { return nil}
        guard let deserialised = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return nil }

        // обязательные значения, без которых мы не соберем минимальный ToDoItem
        guard let id = deserialised[FieldDescriptor.id.rawValue],
              let text = deserialised[FieldDescriptor.text.rawValue],
              let isCompleted = deserialised[FieldDescriptor.isCompleted.rawValue],
              let creationDate = deserialised[FieldDescriptor.creationDate.rawValue],
              let created = try? Date(creationDate, strategy: .iso8601),
              let categoryName = deserialised[FieldDescriptor.categoryName.rawValue],
              let categoryColor = deserialised[FieldDescriptor.categoryColor.rawValue]
        else { return nil }

        // Опциональные значения и развертывания
        let completed = isCompleted == "false" ? false : true
        let priority = deserialised[FieldDescriptor.priority.rawValue] == nil ? Priority.usual :
        Priority(rawValue: deserialised[FieldDescriptor.priority.rawValue]!)!
        let deadLineDate = try? Date(deserialised[FieldDescriptor.deadLineDate.rawValue] ?? "", strategy: .iso8601)
        let changeDate = try? Date(deserialised[FieldDescriptor.changeDate.rawValue] ?? "", strategy: .iso8601)
        let hex = deserialised[FieldDescriptor.hex.rawValue]

        return TodoItem(
            id: id,
            text: text,
            priority: priority,
            deadLineDate: deadLineDate,
            isCompleted: completed,
            creationDate: created,
            changeDate: changeDate,
            hex: hex,
            category: Activity(name: categoryName, hexColor: categoryColor)
        )
    }

    // вычисляемое значение для сборки JSON-а
    private var asDictionary: [String: String] {
        let formatter = ISO8601DateFormatter()

        var dict = [String: String]()
        dict[FieldDescriptor.id.rawValue] = id
        dict[FieldDescriptor.text.rawValue] = text
        dict[FieldDescriptor.isCompleted.rawValue] = isCompleted.description
        dict[FieldDescriptor.creationDate.rawValue] = formatter.string(from: creationDate)
        dict[FieldDescriptor.hex.rawValue] = hex
        dict[FieldDescriptor.categoryName.rawValue] = category.name
        dict[FieldDescriptor.categoryColor.rawValue] = category.hexColor

        if changeDate != nil { dict[FieldDescriptor.changeDate.rawValue] = formatter.string(from: changeDate!) }
        if priority != .usual { dict[FieldDescriptor.priority.rawValue] = priority.rawValue }
        if deadLineDate != nil { dict[FieldDescriptor.deadLineDate.rawValue] = formatter.string(from: deadLineDate!) }
        return dict
    }

    var json: Any {
        let data = try? JSONSerialization.data(withJSONObject: asDictionary, options: [])
        return data ?? Data()
    }
}

// MARK: - расширение для работы с CSV
extension TodoItem {
    // наверно, брать строку с множеством значений более уместно чем обрабатывать только 1 строку
    static func parseCSV(with CSVString: String) -> [TodoItem] {
        let formatter = ISO8601DateFormatter() // форматтер чтобы считывать дату из строки

        var items: [TodoItem] = []
        var separatedByNewLine = CSVString.split(separator: "\n")
        separatedByNewLine.removeFirst() // дропнем заголовок
        for line in separatedByNewLine {
            let splitLines = line.split(separator: #";"#).map {String($0)}
            if Priority(rawValue: splitLines[2]) == nil { continue }

            let id: String = splitLines[0]
            let text: String = splitLines[1]
            let priority: Priority = Priority(rawValue: splitLines[2]) ?? .usual
            let deadLineDate: Date? = formatter.date(from: splitLines[3])
            let isCompleted: Bool = splitLines[4] == "false" ? false : true
            let creationDate: Date = formatter.date(from: splitLines[5]) ?? .now // фиксить
            let changeDate: Date? = formatter.date(from: splitLines[6])

            let item = TodoItem(
                id: id,
                text: text,
                priority: priority,
                deadLineDate: deadLineDate,
                isCompleted: isCompleted,
                creationDate: creationDate,
                changeDate: changeDate,
                hex: nil
            )
            items.append(item)
        }
        return items
    }
}
