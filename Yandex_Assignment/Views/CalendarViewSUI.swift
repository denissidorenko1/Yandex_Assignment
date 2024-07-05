import SwiftUI

struct CalendarViewSUI: View {
    var body: some View {
        CalendarWrapper(
            calendarVM: CalendarViewModel(
                model: FileCache(),
                itemListViewModel: nil
            )
        )
            .ignoresSafeArea(.container)
    }
}

#Preview {
    CalendarViewSUI()
}
