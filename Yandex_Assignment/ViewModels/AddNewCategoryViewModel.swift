import Foundation
import CocoaLumberjackSwift

@Observable
final class AddNewCategoryViewModel {
    var color: Double = 0.1
    var name: String = ""

    private let model = CategoryManager()

    func addNew(with category: Category) {
        model.load()
        model.add(with: category)
        model.save()
        DDLogInfo("Добавлена новая категория \(category)")
    }
}
