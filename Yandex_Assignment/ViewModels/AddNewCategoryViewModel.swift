import Foundation
import CocoaLumberjackSwift
@_spi(Public) import MyPackage

@Observable
final class AddNewCategoryViewModel {
    var color: Double = 0.1
    var name: String = ""

    private let model = CategoryManager()

    func addNew(with category: Activity) {
        model.load()
        model.add(with: category)
        model.save()
        DDLogInfo("Добавлена новая категория \(category)")
    }
}

