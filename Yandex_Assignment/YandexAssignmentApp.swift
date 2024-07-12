import SwiftUI
import CocoaLumberjackSwift

@main
struct YandexAssignmentApp: App {
    var body: some Scene {
        WindowGroup {
            ItemListScreenView()
        }
    }

    init() {
        DDLog.add(DDOSLogger.sharedInstance)
        let fileLogger: DDFileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }
}
