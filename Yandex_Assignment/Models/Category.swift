import Foundation
import SwiftUI
import UIKit
import CocoaLumberjackSwift

struct Category: Codable {
    let name: String
    let hexColor: String
}

extension Category: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(hexColor)
    }
}

final class CategoryManager {
    private(set)var categories: [Category] = [
        Category(name: "Работа", hexColor: "FF0000"),
        Category(name: "Учеба", hexColor: "0000FF"),
        Category(name: "Хобби", hexColor: "00FF00"),
        Category(name: "Другое", hexColor: "FFFFFF")
    ]

    static let categoryKey: String = "Categories"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func add(with category: Category) {
        categories.append(category)
        DDLogInfo("Добавлена категория в \(Self.self)")
    }

    func save() {
        if let encodedCategories = try? encoder.encode(categories) {
            UserDefaults.standard.set(encodedCategories, forKey: CategoryManager.categoryKey)
        } else {
            DDLogWarn("В \(Self.self) не сработало сохранение")
        }
    }

    func load() {
        if let savedCategories = UserDefaults.standard.data(forKey: CategoryManager.categoryKey),
           let decodedCategories = try? decoder.decode([Category].self, from: savedCategories) {
            categories = decodedCategories
        } else {
            DDLogWarn("В \(Self.self) не сработала загрузка")
        }
    }

    func deleteAll() {
        UserDefaults.standard.removeObject(forKey: CategoryManager.categoryKey)
        DDLogInfo("Все данные о категориях удалены")
    }
}
