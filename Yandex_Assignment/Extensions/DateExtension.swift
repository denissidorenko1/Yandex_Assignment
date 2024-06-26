import Foundation

extension Date {
    // небольшой форматтер для локализации даты
    func getFormattedDateString() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "Ru-ru")
        let components = cal.dateComponents([.day, .month], from: self)
        return "\(components.day!) \(cal.monthSymbols[components.month!-1])"
    }
}

