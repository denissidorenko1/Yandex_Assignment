import SwiftUI
import UIKit

struct CalendarWrapper: UIViewControllerRepresentable {
    let calendarVM: CalendarViewModel
    
    typealias UIViewControllerType = CalendarView

    func makeUIViewController(context: Context) -> CalendarView {
        let calendar = CalendarView()
        calendar.viewModel = calendarVM
        return calendar
    }

    func updateUIViewController(_ uiViewController: CalendarView, context: Context) {
        
    }
}

