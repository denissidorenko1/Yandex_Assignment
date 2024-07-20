import Foundation

enum NetworkingError: Error {
    case someError
}

enum NetworkingImportance: String, Codable {
    case low
    case basic
    case important
    
    static func mapImportance(with smth: TodoItem.Priority) -> NetworkingImportance {
        switch smth {
        case .unimportant:
            return NetworkingImportance.low
        case .usual:
            return NetworkingImportance.basic
        case .important:
            return NetworkingImportance.important
        }
    }
    
    static func mapPriority(with smth: NetworkingImportance) -> TodoItem.Priority {
        switch smth {
        case .low:
            return .unimportant
        case .basic:
            return .usual
        case .important:
            return .important
        }
    }
}

struct NetworkingItem: Codable {
    let files: [String]?
    let id: String
    let text: String
    let importance: NetworkingImportance
    let deadline: Int?
    let done: Bool
    let color: String?
    let created_at: Int
    let changed_at: Int
    let last_updated_by: String
    
}

struct NetworkingSingleResponse: Codable {
    let status: String
    let element: NetworkingItem
    let revision: Int
}

struct NetworkingListResponse: Codable {
    let list: [NetworkingItem]
    let revision: Int
    let status: String
}

struct RetrySettings {
    let minDelay = 2
    let maxDelay = 120
    let factor = 1.5
    let jitter = 0.05
}
