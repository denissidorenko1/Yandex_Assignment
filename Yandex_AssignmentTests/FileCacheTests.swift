import Foundation
import XCTest
@testable import Yandex_Assignment

final class FileCacheTests: XCTestCase {
    var cache: FileCache?
    let testURL = URL(fileURLWithPath: "")
    let testFileName = "testFile.dat"
        
    override func setUpWithError() throws {
        cache = FileCache()
    }

    override func tearDownWithError() throws {
        let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(testFileName)
        
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testAddNewItem() {
        let item = TodoItem(
            text: "test",
            priority: .unimportant,
            isCompleted: true,
            creationDate: .now,
            hex: nil
        )
        guard let cache else { XCTFail(); return}
        try? cache.addNewItem(with: item)
        
        XCTAssert(cache.items.values.first! == item)
    }
    
    func testDeleteById() {
        guard let cache else { XCTFail(); return}
        let id = "1234"
        let item = TodoItem(
            id: id,
            text: "test",
            priority: .unimportant,
            isCompleted: true,
            creationDate: Date.now,
            hex: nil
        )
        
        try? cache.addNewItem(with: item)
        // проверим наличие
        guard cache.items.values.first! == item else { XCTFail(); return}
        cache.deleteItem(with: id)
        XCTAssert(cache.items.isEmpty)
    }
    
    func testSaveToFile() {
        guard let cache else {XCTFail();  return}
        let item = TodoItem(
            text: "test",
            priority: .unimportant,
            isCompleted: true,
            creationDate: Date.now,
            hex: nil
        )
        guard let _ = try? cache.addNewItem(with: item) else { XCTFail(); return }
        guard let _ = try? cache.saveAllItemsToFile(with: testURL, filename: testFileName) else { XCTFail(); return }
        let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(testFileName)
        XCTAssert(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testSaveAndReadFromFile() {
        guard let cache else {return}
        let id = "1234"
        let item = TodoItem(
            id: id,
            text: "test",
            priority: .unimportant,
            isCompleted: true,
            creationDate: Date.now,
            hex: nil
        )
        try! cache.addNewItem(with: item)
        guard let _ = try? cache.saveAllItemsToFile(with: testURL, filename: testFileName) else { XCTFail(); return }
        cache.deleteItem(with: id)
        
        guard let _ = try? cache.loadAllItemsFromFile(with: testURL, fileName: testFileName) else { XCTFail(); return }
        guard let element = cache.items[id] else { XCTFail(); return}
        XCTAssert([element] == [item])
    }


}
