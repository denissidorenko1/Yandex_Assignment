import Foundation
import SwiftUI
import UIKit

@_spi(Public) public struct Activity: Codable {
    public let name: String
    public let hexColor: String

    public init(name: String, hexColor: String) {
        self.name = name
        self.hexColor = hexColor
    }
}

extension Activity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(hexColor)
    }
}

@_spi(Public) public final class CategoryManager {
    public private(set) var categories: [Activity] = [
        Activity(name: "Работа", hexColor: "FF0000"),
        Activity(name: "Учеба", hexColor: "0000FF"),
        Activity(name: "Хобби", hexColor: "00FF00"),
        Activity(name: "Другое", hexColor: "FFFFFF")
    ]

    public init() {

    }

    public static let categoryKey: String = "Categories"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public func add(with category: Activity) {
        categories.append(category)
    }

    public func save() {
        if let encodedCategories = try? encoder.encode(categories) {
            UserDefaults.standard.set(encodedCategories, forKey: CategoryManager.categoryKey)
        } else {
        }
    }

    public func load() {
        if let savedCategories = UserDefaults.standard.data(forKey: CategoryManager.categoryKey),
           let decodedCategories = try? decoder.decode([Activity].self, from: savedCategories) {
            categories = decodedCategories
        } else {
        }
    }

    public func deleteAll() {
        UserDefaults.standard.removeObject(forKey: CategoryManager.categoryKey)
    }
}
