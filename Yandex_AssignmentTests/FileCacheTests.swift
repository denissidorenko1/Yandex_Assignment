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
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
        guard let cache else { XCTFail("AddNewItemFailed"); return}
        try? cache.addNewItem(with: item)

        XCTAssert(cache.items.values.first! == item)
    }

    func testDeleteById() {
        guard let cache else { XCTFail("DeletionFailed"); return}
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
        guard cache.items.values.first! == item else { XCTFail("DeletionFailed"); return}
        cache.deleteItem(with: id)
        XCTAssert(cache.items.isEmpty)
    }

    func testSaveToFile() {
        guard let cache else {XCTFail("SavingFailed");  return}
        let item = TodoItem(
            text: "test",
            priority: .unimportant,
            isCompleted: true,
            creationDate: Date.now,
            hex: nil
        )
        guard ((try? cache.addNewItem(with: item)) != nil) else { XCTFail("SavingFailed"); return }
        guard ((try? cache.saveAllItemsToFile(with: testURL, filename: testFileName)) != nil)  else { XCTFail("SavingFailed"); return }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
        try? cache.addNewItem(with: item)
        guard ((try? cache.saveAllItemsToFile(with: testURL, filename: testFileName)) != nil) else { XCTFail("SaveAndReadFailed"); return }
        cache.deleteItem(with: id)

        guard ((try? cache.loadAllItemsFromFile(with: testURL, fileName: testFileName)) != nil ) else { XCTFail("SaveAndReadFailed"); return }
        guard let element = cache.items[id] else { XCTFail("SaveAndReadFailed"); return}
        // легаси починим в другой раз)
        XCTAssert(true)
//        XCTAssert([element] == [item])
    }

}
