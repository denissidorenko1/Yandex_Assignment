import Foundation
import UIKit

enum NetworkingError: Error {
    case someError
}

enum ImportanceTest: String, Codable {
    case low
    case basic
    case important
    
    static func mapImportance(with smth: TodoItem.Priority) -> ImportanceTest {
        switch smth {
        case .unimportant:
            return ImportanceTest.low
        case .usual:
            return ImportanceTest.basic
        case .important:
            return ImportanceTest.important
        }
    }
    
    static func mapPriority(with smth: ImportanceTest) -> TodoItem.Priority {
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

struct MockItem: Codable {
    let files: String?
    let id: String
    let text: String
    let importance: ImportanceTest
    let deadline: Int?
    let done: Bool
    let color: String?
    let created_at: Int
    let changed_at: Int
    let last_updated_by: String
    
}

struct MockAdd: Codable {
    let status: String
    let element: MockItem
    let revision: Int
}

struct NetworkingServiceResponse: Codable {
    let list: [MockItem]
    let revision: Int
    let status: String
}

protocol NetworkingService: Actor {
    func getList() async throws -> [MockItem]
    func addItem(with item: MockItem) async throws -> MockItem
    func getItem(with id: String) async throws -> MockItem
    func deleteItem(with id: String) async throws -> MockItem
    func editItem(with newVersion: MockItem) async throws -> MockItem
    func updateList(with items: [MockItem]) async throws -> [MockItem]
}

actor DefaultNetworkingService: NetworkingService {
    var lastRevision: Int { didSet {
        print("Последняя ревизия: \(lastRevision)")
    }}
    
    static let baseURL = URL(string: "https://hive.mrdekk.ru/todo")!
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    init(lastRevision: Int) {
        self.lastRevision = lastRevision
    }

    
    private static func getRevision() async throws -> Int {
        let listURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        listRequest.setValue("Bearer Rosiel", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.dataTask(for: listRequest)
        let decoded = try JSONDecoder().decode(NetworkingServiceResponse.self, from: data)
        return decoded.revision
    }
    
    
    func getList() async throws -> [MockItem] {
        let listURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        listRequest.setValue("Bearer Rosiel", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.dataTask(for: listRequest)
        let decoded = try decoder.decode(NetworkingServiceResponse.self, from: data)
        lastRevision = decoded.revision
        return decoded.list
    }
    
    func addItem(with item: MockItem) async throws -> MockItem {
        let addURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var addRequest = URLRequest(url: addURL)
        addRequest.httpMethod = "POST"
        let mockadd = MockAdd(status: "ok", element: item, revision: lastRevision)
        addRequest.addValue("Bearer Rosiel", forHTTPHeaderField: "Authorization")
        addRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        let encodedData = try encoder.encode(mockadd)
        addRequest.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.data(for: addRequest)
            let decoded = try decoder.decode(MockAdd.self, from: data)
            print(String(decoding: data, as: UTF8.self))
            if let code = response.statusCode(), code != 200 {
                print("error code is not 200")
            }
            print("printing element \(decoded.element)")
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("1")
            print("error \(error)")
            throw NetworkingError.someError
        }
        
        

        
    }
    
    func getItem(with id: String) async throws -> MockItem {
        let getSpecificItemURL = DefaultNetworkingService.baseURL.appendingPathComponent("list").appendingPathComponent("\(id)")
        var getItemRequest = URLRequest(url: getSpecificItemURL)
        getItemRequest.httpMethod = "GET"
        getItemRequest.setValue("Bearer Rosiel", forHTTPHeaderField: "Authorization")
        getItemRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: getItemRequest)
            let decoded = try decoder.decode(MockAdd.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("error code is not 200")
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error 2")
            print("error \(error)")
            throw NetworkingError.someError
        }

    }
    
    func deleteItem(with id: String) async throws -> MockItem {
        let deleteURL = DefaultNetworkingService.baseURL.appendingPathComponent("list").appendingPathComponent("\(id)")
        var deleteRequest = URLRequest(url: deleteURL)
        deleteRequest.httpMethod = "DELETE"
        deleteRequest.setValue("Bearer Rosiel", forHTTPHeaderField: "Authorization")
        deleteRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: deleteRequest)
            let decoded = try decoder.decode(MockAdd.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("error code is not 200")
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error 2")
            print("error \(error)")
            throw NetworkingError.someError
        }

    }
    
    func editItem(with newVersion: MockItem) async throws -> MockItem {
        let changeURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
            .appendingPathComponent("\(newVersion.id)")
        var changeRequest = URLRequest(url: changeURL)
        changeRequest.httpMethod = "PUT"
        let mockadd = MockAdd(status: "ok", element: newVersion, revision: lastRevision)
        print(mockadd)
        changeRequest.addValue("Bearer Rosiel", forHTTPHeaderField: "Authorization")
        changeRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        print("editor 1")
        let encodedData = try? encoder.encode(mockadd)
        print("editor 2")
        changeRequest.httpBody = encodedData
        print("newversion id is \(newVersion.id)")
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: changeRequest)
            if let code = response.statusCode(), code != 200 {
                // FIXME: - падает
                print(code)
                print("error code is not 200")
            }
            print("editor 3")
            print(String(decoding: data, as: UTF8.self))
            let decoded = try decoder.decode(MockAdd.self, from: data)
            return decoded.element
        } catch {
            print(error)
            throw NetworkingError.someError
        }
//        let (data, _) = try await URLSession.shared.data(for: changeRequest)
//        print("editor 3")
//        print(String(decoding: data, as: UTF8.self))
//        let decoded = try decoder.decode(MockAdd.self, from: data)
//        print("editor 4")
//        lastRevision = decoded.revision
//        return decoded.element
    }
    
    func updateList(with items: [MockItem]) async throws -> [MockItem] {
        let updateListURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
            
        var updateListRequest = URLRequest(url: updateListURL)
        updateListRequest.httpMethod = "PATCH"
        let newStuff = NetworkingServiceResponse(list: items, revision: lastRevision, status: "ok")
        updateListRequest.addValue("Bearer Rosiel", forHTTPHeaderField: "Authorization")
        updateListRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        let encodedData = try? encoder.encode(newStuff)
        updateListRequest.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.data(for: updateListRequest)
            let decoded = try decoder.decode(NetworkingServiceResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("error code is not 200")
            }
            lastRevision = decoded.revision
            return decoded.list
        } catch {
            print("error 4")
            print("error \(error)")
            throw NetworkingError.someError
        }
        
    }
    
}


extension URLResponse {
    func statusCode() -> Int? {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return nil
    }
}
