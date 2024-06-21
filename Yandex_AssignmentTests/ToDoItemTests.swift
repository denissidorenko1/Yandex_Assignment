import XCTest
@testable import Yandex_Assignment

final class ToDoItemTests: XCTestCase {
    // путь и название файла для тестирования чтения CSV
    let csvTestURL = URL(fileURLWithPath: "")
    let csvTestFileName = "testFile.csv"
    
    // чистим файл с .csv
    override func tearDownWithError() throws {
        let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(csvTestFileName)
        
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // валидация JSON
    func testValidateJSON() {
        let id = "qwerty"
        let creationDate = Date.now
        let item = TodoItem(id: id, text: "text", priority: .important, isCompleted: true, creationDate: creationDate)
        
        let json = item.json
        guard let data = json as? Data else { return }
        guard let deserialised = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return  }
        XCTAssert(JSONSerialization.isValidJSONObject(deserialised))
    }
    
    // перебиваем ToDoItem в JSON, конвертируем обратно и проверяем их эквивалентность
    func testDecodedEqualsOriginal() {
        let id: String = "1234"
        let text: String = "text"
        let priority: TodoItem.Priority = .usual
        let isCompleted: Bool = true
        let creationDate: Date = .now
        
        let initialItem = TodoItem(
            id: id,
            text: text,
            priority: priority,
            isCompleted: isCompleted,
            creationDate: creationDate
        )
        
        let json = initialItem.json
        guard let parsed = TodoItem.parse(json: json) else { return }
        XCTAssert(initialItem == parsed)
    }
    
    // проверяем, что поле priority заполнено в JSON-е при .important
    func testImportant() {
        let item = TodoItem(
            text: "",
            priority: .important,
            isCompleted: true,
            creationDate: .now
        )
        
        guard let jsonData = item.json as? Data else {return}
        guard let deserialised = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else { return  }
        let importanceKey = TodoItem.FieldDescriptor.priority.rawValue
        XCTAssert(deserialised[importanceKey] != nil)
        
    }
    // проверяем, что поле priority заполнено в JSON-е при .unimportant
    func testUnimportant() {
        let item = TodoItem(
            text: "",
            priority: .unimportant,
            isCompleted: true,
            creationDate: .now
        )
        
        guard let jsonData = item.json as? Data else {return}
        guard let deserialised = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else { return  }
        let importanceKey = TodoItem.FieldDescriptor.priority.rawValue
        XCTAssert(deserialised[importanceKey] != nil)
    }
    
    // проверяем, что поле priority не заполнено в JSON-е при .usual
    func testUsualImportance() {
        let item = TodoItem(
            text: "",
            priority: .usual,
            deadLineDate: .now,
            isCompleted: true,
            creationDate: .now,
            changeDate: .now
        )
        
        guard let jsonData = item.json as? Data else {return}
        guard let deserialised = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else { return  }
        let importanceKey = TodoItem.FieldDescriptor.priority.rawValue
        XCTAssert(deserialised[importanceKey] == nil)
    }

    
    
    // проверяем что файл .csv создается
    func testCSVCreation() {
        let item = TodoItem(
            text: "Купи французских булок, да выпей чаю.",
            priority: .important,
            deadLineDate: .now,
            isCompleted: true,
            creationDate: .now,
            changeDate: .now
        )
        
        let csv = TodoItem.constructCompleteCSV(items: [item])
        TodoItem.writeCSVToFile(csv: csv, with: csvTestURL, filename: csvTestFileName)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(csvTestFileName)
        XCTAssert(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    // перебиваем ToDoItem в .csv, конвертируем обратно и проверяем их эквивалентность
    func testCSVEqualsOriginal() {
        let item = TodoItem(
            text: "Купи французских булок, да выпей чаю.",
            priority: .important,
            deadLineDate: .now,
            isCompleted: true,
            creationDate: .now,
            changeDate: .now
        )
        
        let csv = TodoItem.constructCompleteCSV(items: [item])
        TodoItem.writeCSVToFile(csv: csv, with: csvTestURL, filename: csvTestFileName)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let deconstructed = TodoItem.readCSVFromFile(with: csvTestURL, fileName: csvTestFileName)!
        let parsed = TodoItem.parseCSV(with: deconstructed)[0]
        XCTAssert(item == parsed)
    }
    
}

// расширение чтобы можно было сравнивать item-ы: например, до конвертации и после
extension TodoItem: Equatable {
    public static func == (lhs: TodoItem, rhs: TodoItem) -> Bool {
        guard lhs.id == rhs.id,
              lhs.text == lhs.text,
              lhs.isCompleted == rhs.isCompleted,
              lhs.priority == rhs.priority,
              // костыли: при конвертации в строку и обратно образуется неточность, которая ломает "==" для дат
              (((lhs.changeDate ?? Date.now).addingTimeInterval(1) )...((lhs.changeDate ?? Date.now).addingTimeInterval(3))).contains((rhs.changeDate ?? Date.now).addingTimeInterval(2)),
              (((lhs.creationDate).addingTimeInterval(1) )...((lhs.creationDate).addingTimeInterval(3))).contains((rhs.creationDate).addingTimeInterval(2)),
              (((lhs.deadLineDate ?? Date.now).addingTimeInterval(1))...((lhs.deadLineDate ?? Date.now).addingTimeInterval(3))).contains((rhs.deadLineDate ?? Date.now).addingTimeInterval(2))
        else {
            return false
        }
        return true
    }
}

// расширим ToDoItem для тестирования: добавим методы форматирования csv, записи в файл, чтения из файла
fileprivate extension TodoItem {
        static func constructCSVLine(item: TodoItem) -> String {
            let formatter = ISO8601DateFormatter()
            var csvRow = "\(item.id);\(item.text);\(item.priority.rawValue);"
            if let deadLineDate = item.deadLineDate {
                csvRow += "\(formatter.string(from: deadLineDate));"
            } else {
                csvRow += "\"\";"
            }
            csvRow += "\(item.isCompleted);"
            csvRow += "\(formatter.string(from: item.creationDate));"
            if let changeDate = item.changeDate {
                csvRow += "\(formatter.string(from: changeDate))"
            } else {
                csvRow += "\"\""
            }
            return csvRow
        }
        
        static func constructCompleteCSV(items: [TodoItem]) -> String {
            var csvData = "id;text;priority;deadLineDate;isCompleted;creationDate;changeDate\n"
            for item in items {
                csvData += constructCSVLine(item: item) + "\n"
            }
            return csvData
        }
        
        
    static func writeCSVToFile(csv: String, with fileURL: URL, filename: String) {
            do {
                guard let documentsDirectory = FileManager.default.urls(for:.documentDirectory,
                    in:.userDomainMask).first else { return }
                let fileURL = documentsDirectory.appendingPathComponent(filename)
    
                let csvData = csv.data(using: .utf8)!
                try csvData.write(to: fileURL)
            } catch {
    
            }
        }
        
        static func readCSVFromFile(with fileURL: URL, fileName: String) -> String? {
            guard let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)
                .first else {  return nil }
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            guard let str = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }
            return str
        }

}
