import Foundation
import XCTest
@testable import Yandex_Assignment


final class FileCachePersistanceTests: XCTestCase {
    var cache: FileCache?
    
    override func tearDown() {
    }
    
    override func setUpWithError() throws {
        cache = FileCache()
        cache!.deleteAll()
    }
    
    func testAdd() throws {
        guard let cache = cache else { XCTFail("cache hasn't been set up"); return }
        let newItem = TodoItem(
            text: "text",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        
        cache.insert(newItem)
        XCTAssertTrue(cache.persistentItems[0] == newItem)
    }
    
    func testUpdate() throws {
        guard let cache = cache else { XCTFail("cache hasn't been set up"); return }
        let oldItem = TodoItem(
            text: "old",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        let newItem = TodoItem(
            id: oldItem.id,
            text: "new",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        
        cache.insert(oldItem)
        cache.update(newItem)
        XCTAssertTrue(cache.persistentItems.count == 1)
        XCTAssertTrue(cache.persistentItems[0] == newItem)
    }
    
    func testDelete() throws {
        guard let cache = cache else { XCTFail("cache hasn't been set up"); return }
        let item = TodoItem(
            text: "old",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        cache.insert(item)
        cache.delete(item)
        XCTAssertTrue(cache.persistentItems.count == 0)
    }
    
    // проверка сохранения в долгосрочное хранилище
    func testPersistanceBetweenLaunches() {
        var cache: FileCache? = FileCache()
        // удаляем все элементы хранилища
        cache!.deleteAll()
        let item = TodoItem(
            text: "qqq",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        // добавляем элемент
        cache!.insert(item)
        // деаллоцируем FileCache. Теперь единственный источник данных - SwiftData
        cache = nil
        cache = FileCache()
        // инициализируем и загружаем данные
        cache!.fetch()
        XCTAssert(cache!.persistentItems.count == 1)
    }
    
    // тест сортировки по ключу
    func testFetchWithSorter() {
        guard let cache = cache else { XCTFail("cache hasn't been set up"); return }
        let item1 = TodoItem(
            text: "111",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        let item2 = TodoItem(
            text: "666",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        let item3 = TodoItem(
            text: "222",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        let item4 = TodoItem(
            text: "333",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        cache.insert(item1)
        cache.insert(item2)
        cache.insert(item3)
        cache.insert(item4)
        cache.fetch(key: .text)
        let fetched = cache.persistentItems
        XCTAssert(
            fetched[0].text <= fetched[1].text && fetched[1].text <= fetched[2].text &&
            fetched[2].text <= fetched[3].text
        )
    }
    
    // тести фильтрации значений
    func testFetchWithFilter() {
        guard let cache = cache else { XCTFail("cache hasn't been set up"); return }
        let item1 = TodoItem(
            text: "111",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        let item2 = TodoItem(
            text: "666",
            priority: .important,
            isCompleted: false,
            hex: nil
        )
        let item3 = TodoItem(
            text: "222",
            priority: .usual,
            isCompleted: false,
            hex: nil
        )
        let item4 = TodoItem(
            text: "333",
            priority: .unimportant,
            isCompleted: false,
            hex: nil
        )
        cache.insert(item1)
        cache.insert(item2)
        cache.insert(item3)
        cache.insert(item4)
        cache.fetch(include: { item in
            return item.priority == .important
        })
        let fetched = cache.persistentItems
        XCTAssert( fetched.count == 2 )
    }
}
