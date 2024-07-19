import Foundation
import UIKit

protocol NetworkingService: Actor {
    @discardableResult func getList() async throws -> [NetworkingItem]
    @discardableResult func addItem(with item: NetworkingItem) async throws -> NetworkingItem
    @discardableResult func getItem(with id: String) async throws -> NetworkingItem
    @discardableResult func deleteItem(with id: String) async throws -> NetworkingItem
    @discardableResult func editItem(with newVersion: NetworkingItem) async throws -> NetworkingItem
    @discardableResult func updateList(with items: [NetworkingItem]) async throws -> [NetworkingItem]
}

actor DefaultNetworkingService: NetworkingService {
    var lastRevision: Int { didSet {
        print("Последняя ревизия: \(lastRevision)")
    }}
    
    private static let baseURL = URL(string: "https://hive.mrdekk.ru/todo")!
    private static let token = "Rosiel"
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    init(lastRevision: Int) {
        self.lastRevision = lastRevision
    }
    
    private static func getRevision() async throws -> Int {
        let listURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        listRequest.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.dataTask(for: listRequest)
        let decoded = try JSONDecoder().decode(NetworkingListResponse.self, from: data)
        return decoded.revision
    }
    
    @discardableResult
    func getList() async throws -> [NetworkingItem] {
        let listURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        listRequest.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.dataTask(for: listRequest)
        let decoded = try decoder.decode(NetworkingListResponse.self, from: data)
        lastRevision = decoded.revision
        return decoded.list
    }
    
    @discardableResult
    func addItem(with item: NetworkingItem) async throws -> NetworkingItem {
        let addURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var addRequest = URLRequest(url: addURL)
        addRequest.httpMethod = "POST"
        let mockadd = NetworkingSingleResponse(status: "ok", element: item, revision: lastRevision)
        addRequest.addValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        addRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        let encodedData = try encoder.encode(mockadd)
        addRequest.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: addRequest)
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }
    }
    
    @discardableResult
    func getItem(with id: String) async throws -> NetworkingItem {
        let getSpecificItemURL = DefaultNetworkingService.baseURL.appendingPathComponent("list").appendingPathComponent("\(id)")
        var getItemRequest = URLRequest(url: getSpecificItemURL)
        getItemRequest.httpMethod = "GET"
        getItemRequest.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        getItemRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: getItemRequest)
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }

    }
    
    @discardableResult
    func deleteItem(with id: String) async throws -> NetworkingItem {
        let deleteURL = DefaultNetworkingService.baseURL.appendingPathComponent("list").appendingPathComponent("\(id)")
        var deleteRequest = URLRequest(url: deleteURL)
        deleteRequest.httpMethod = "DELETE"
        deleteRequest.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        deleteRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: deleteRequest)
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }

    }
    
    @discardableResult
    func editItem(with newVersion: NetworkingItem) async throws -> NetworkingItem {
        let changeURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
            .appendingPathComponent("\(newVersion.id)")
        var changeRequest = URLRequest(url: changeURL)
        changeRequest.httpMethod = "PUT"
        let mockadd = NetworkingSingleResponse(status: "ok", element: newVersion, revision: lastRevision)
        changeRequest.addValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        changeRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        let encodedData = try? encoder.encode(mockadd)
        changeRequest.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: changeRequest)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
            }
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            return decoded.element
        } catch {
            print(error)
            throw NetworkingError.someError
        }
    }
    
    @discardableResult
    func updateList(with items: [NetworkingItem]) async throws -> [NetworkingItem] {
        let updateListURL = DefaultNetworkingService.baseURL.appendingPathComponent("list")
            
        var updateListRequest = URLRequest(url: updateListURL)
        updateListRequest.httpMethod = "PATCH"
        let newStuff = NetworkingListResponse(list: items, revision: lastRevision, status: "ok")
        updateListRequest.addValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        updateListRequest.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        let encodedData = try? encoder.encode(newStuff)
        updateListRequest.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.data(for: updateListRequest)
            let decoded = try decoder.decode(NetworkingListResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("error code is not 200")
            }
            lastRevision = decoded.revision
            return decoded.list
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }
    }
}


