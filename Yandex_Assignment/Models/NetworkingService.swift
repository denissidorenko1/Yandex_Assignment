import Foundation

protocol NetworkingService: Actor {
    func getAll() async throws -> [TodoItem]
    func getByID(with id: String) async throws -> TodoItem?
    func addNew(with item: TodoItem) async throws
    func editItem(with newVersion: TodoItem) async throws
    func updateAll(with newItems: [TodoItem]) async throws -> [TodoItem]
    func deleteByID(with id: String) async throws
}

actor DefaultNetworkingService: NetworkingService {
    private var lastRevision: Int {
        didSet {
            print("Последняя ревизия: \(lastRevision)")
        }
    }
    
    private(set) var items: [NetworkingItem] = []
//    private var isDirty: Bool = false
    
    private static let baseURL = URL(string: "https://hive.mrdekk.ru/todo")!
    private static let token = "Rosiel"
    
    static let shared = DefaultNetworkingService(lastRevision: 0)
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let retrySettings = RetrySettings()
    
    init(lastRevision: Int) {
        self.lastRevision = lastRevision
    }
    
//    private func handleOutOfSync() async throws {
//        print("data is dirty!")
//        isDirty = true
//        items = try await updateList(with: items)
//        isDirty = false
//    }
    
    func getAll() async throws -> [TodoItem] {
        do {
            return try await retry(operation: { [unowned self] in
                items = try await getList()
                return convertNetworkingList(with: items)
            }, settings: retrySettings)
        } catch {
            guard let result = try? await updateList(with: items) else { return []}
            return convertNetworkingList(with: result)
        }
    }
    
    func getByID(with id: String) async throws -> TodoItem? {
        do {
            return try await retry(operation: { [unowned self] in
                let item = try await getItem(with: id)
                return convertNetworkingItem(with: item)
            }, settings: retrySettings)
        } catch {
            try await updateList(with: items)
            return nil
        }
    }
    
    func addNew(with item: TodoItem) async throws {
        do {
            return try await retry(operation: { [unowned self] in
                let mock = convertToDoItem(with: item)
                let newItem = try await addItem(with: mock)
                items.append(newItem)
            }, settings: retrySettings)
        } catch {
            try await updateList(with: items)
        }
    }
    
    func editItem(with newVersion: TodoItem) async throws  {
        do {
            return try await retry(operation: { [unowned self] in
                let newItem = convertToDoItem(with: newVersion)
                let newMock = try await editItem(with: newItem)
                if let index = items.firstIndex(where: { $0.id == newMock.id }) {
                    items[index] = newMock
                }
            }, settings: retrySettings)
        } catch {
            try await updateList(with: items)
        }
    }
    
    // единственный метод, от которого ожидается отсутствие ошибок от бэкенда (но это не так)
    func updateAll(with newItems: [TodoItem]) async throws -> [TodoItem] {
        let mockItems = convertToDoList(with: newItems)
        let updated = try await updateList(with: mockItems)
        return convertNetworkingList(with: updated)
    }
    
    func deleteByID(with id: String) async throws {
        do {
            return try await retry(operation: { [unowned self] in
                try await deleteItem(with: id)
            }, settings: retrySettings)
        } catch {
            try await updateList(with: items)
        }
    }
    
    // MARK: - методы более низкого уровня. Первоначально это были методы другого актора
    private static func getRevision() async throws -> Int {
        let url = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.dataTask(for: request)
        let decoded = try JSONDecoder().decode(NetworkingListResponse.self, from: data)
        return decoded.revision
    }
    
    @discardableResult
    private func getList() async throws -> [NetworkingItem] {
        let url = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
//        request.setValue("50", forHTTPHeaderField: "X-Generate-Fails")
        let (data, response) = try await URLSession.shared.dataTask(for: request)
        if let code = response.statusCode(), code != 200 {
            print("Код ответа \(code)")
//            isDirty = true
        }
        let decoded = try decoder.decode(NetworkingListResponse.self, from: data)
        lastRevision = decoded.revision
        return decoded.list
    }
    
    @discardableResult
    private func addItem(with item: NetworkingItem) async throws -> NetworkingItem {
        let url = DefaultNetworkingService.baseURL.appendingPathComponent("list")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let mockadd = NetworkingSingleResponse(status: "ok", element: item, revision: lastRevision)
        request.addValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
//        request.setValue("50", forHTTPHeaderField: "X-Generate-Fails")
        let encodedData = try encoder.encode(mockadd)
        request.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: request)
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
//                isDirty = true
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }
    }
    
    @discardableResult
    private func getItem(with id: String) async throws -> NetworkingItem {
        let url = DefaultNetworkingService.baseURL.appendingPathComponent("list").appendingPathComponent("\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
//        request.setValue("50", forHTTPHeaderField: "X-Generate-Fails")
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: request)
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
//                isDirty = true
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }

    }
    
    @discardableResult
    private func deleteItem(with id: String) async throws -> NetworkingItem {
        let url = DefaultNetworkingService.baseURL.appendingPathComponent("list").appendingPathComponent("\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
//      request.setValue("50", forHTTPHeaderField: "X-Generate-Fails")
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: request)
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
//                isDirty = true
            }
            lastRevision = decoded.revision
            return decoded.element
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }

    }
    
    @discardableResult
    private func editItem(with newVersion: NetworkingItem) async throws -> NetworkingItem {
        let url = DefaultNetworkingService.baseURL.appendingPathComponent("list")
            .appendingPathComponent("\(newVersion.id)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let mockadd = NetworkingSingleResponse(status: "ok", element: newVersion, revision: lastRevision)
        request.addValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
//        request.setValue("50", forHTTPHeaderField: "X-Generate-Fails")
        let encodedData = try? encoder.encode(mockadd)
        request.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.dataTask(for: request)
            if let code = response.statusCode(), code != 200 {
                print("Код ответа \(code)")
//                isDirty = true
            }
            let decoded = try decoder.decode(NetworkingSingleResponse.self, from: data)
            return decoded.element
        } catch {
            print(error)
            throw NetworkingError.someError
        }
    }
    
    @discardableResult
    private func updateList(with items: [NetworkingItem]) async throws -> [NetworkingItem] {
        let url = DefaultNetworkingService.baseURL.appendingPathComponent("list")
            
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        let newStuff = NetworkingListResponse(list: items, revision: lastRevision, status: "ok")
        request.addValue("Bearer \(DefaultNetworkingService.token)", forHTTPHeaderField: "Authorization")
        request.addValue("\(lastRevision)", forHTTPHeaderField: "X-Last-Known-Revision")
        let encodedData = try? encoder.encode(newStuff)
        request.httpBody = encodedData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let decoded = try decoder.decode(NetworkingListResponse.self, from: data)
            if let code = response.statusCode(), code != 200 {
                print("error code is not 200")
//                isDirty = true
            }
            lastRevision = decoded.revision
            return decoded.list
        } catch {
            print("error \(error)")
            throw NetworkingError.someError
        }
    }
}

extension DefaultNetworkingService {
    func retry<T>(
        operation: @escaping () async throws -> T,
        settings: RetrySettings
    ) async throws -> T {
        var nextDelay: Double = Double(settings.minDelay)
        while true {
           print("Запрос не удался, ждем еще \(nextDelay) и повторяем!")
            do {
                return try await operation()
            } catch {
                if nextDelay >= Double(settings.maxDelay) {
                    throw NetworkingError.someError
                }
                nextDelay = pow(settings.factor, nextDelay) + Double.random(in: 0..<settings.jitter)
                try await Task.sleep(nanoseconds: UInt64(nextDelay * 1_000_000_00))
            }
        }
    }
}
