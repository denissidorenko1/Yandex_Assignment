import Foundation
actor NetworkingDataHandler {
    var items: [NetworkingItem] = []
    
    var isDirty: Bool = false
    
    var service: NetworkingService
    
    init(service: NetworkingService) {
        self.service = service
    }
    
    static let shared: NetworkingDataHandler = NetworkingDataHandler(service: DefaultNetworkingService(lastRevision: 0))
    
    private func handleOutOfSync() async throws {
        print("data is dirty!")
        isDirty = true
        items = try await service.updateList(with: items)
        isDirty = false
    }
    
    
    func getAll() async throws -> [TodoItem] {
        isDirty = true
        items = try await service.getList()
        isDirty = false
        return convertMockToToDoItem(with: items)
    }
    
    func getByID(with id: String) async throws -> TodoItem {
        
        let item = try await service.getItem(with: id)
        return convertSingleMock(with: item)
    }
    
    func addNew(with item: TodoItem) async throws -> [TodoItem] {
        guard !isDirty else {
            try await handleOutOfSync()
            return convertMockToToDoItem(with: items)
        }
        let mock = convertSingleToDo(with: item)
        let newItem = try await service.addItem(with: mock)
        items.append(newItem)
        return convertMockToToDoItem(with: items)
    }
    
    func editItem(with newVersion: TodoItem) async throws -> [TodoItem] {
        guard !isDirty else {
            try await handleOutOfSync()
            return convertMockToToDoItem(with: items)
        }
        let newItem = convertSingleToDo(with: newVersion)
        let newMock = try await service.editItem(with: newItem) // - вот отсюда ошибки лезут
        if let index = items.firstIndex(where: { $0.id == newMock.id }) {
            items[index] = newMock
            return convertMockToToDoItem(with: items)
        } else {
            return convertMockToToDoItem(with: items)
        }
    }
    
    func updateAll(with newItems: [TodoItem]) async throws -> [TodoItem] {
        let mockItems = convertToDoToMock(with: newItems)
        let updated = try await service.updateList(with: mockItems)
        isDirty = false
        return convertMockToToDoItem(with: updated)
    }
    
    func deleteByID(with id: String) async throws -> [TodoItem] {
        guard !isDirty else {
            try await handleOutOfSync()
            return convertMockToToDoItem(with: items)
        }
        try await service.deleteItem(with: id) // возвращает удаленную задачу, а зачем она вообще нужна теперь?
        return try await getAll()
    }
    
    private func convertMockToToDoItem(with networkingItems: [NetworkingItem]) -> [TodoItem] {
        var toDoItems: [TodoItem] = []
        
        for mockItem in networkingItems {
            var deadLineDate: Date?
            
            if let deadline = mockItem.deadline {
                deadLineDate = Date(timeIntervalSince1970: Double(deadline))
            }
            
            let item = TodoItem(
                id: mockItem.id,
                text: mockItem.text,
                priority: NetworkingImportance.mapPriority(with: mockItem.importance),
                deadLineDate: deadLineDate,
                isCompleted: mockItem.done,
                creationDate: Date(timeIntervalSince1970: Double(mockItem.created_at)),
                changeDate: Date(timeIntervalSince1970: Double(mockItem.changed_at)),
                hex: mockItem.color
            )
            toDoItems.append(item)
        }
        return toDoItems
    }
    
    private func convertToDoToMock(with toDoItems: [TodoItem]) -> [NetworkingItem] {
        var networkingItems: [NetworkingItem] = []
        for item in toDoItems {
            let newMock = NetworkingItem(
                files: nil,
                id: item.id,
                text: item.text,
                importance: NetworkingImportance.mapImportance(with: item.priority),
                deadline: item.deadLineDate?.unixTimeStamp,
                done: item.isCompleted,
                color: item.hex,
                created_at: item.creationDate.unixTimeStamp ?? Date.unixNow,
                changed_at: item.changeDate?.unixTimeStamp ?? Date.unixNow,
                last_updated_by: "qq"
                
            )
            networkingItems.append(newMock)
        }
        return networkingItems
    }
    
    private func convertSingleMock(with networkingItem: NetworkingItem) -> TodoItem {
        var deadLineDate: Date?
        if let deadline = networkingItem.deadline {
            deadLineDate = Date(timeIntervalSince1970: Double(deadline))
        }
        
        return TodoItem(
            id: networkingItem.id,
            text: networkingItem.text,
            priority: NetworkingImportance.mapPriority(with: networkingItem.importance),
            deadLineDate: deadLineDate,
            isCompleted: networkingItem.done,
            creationDate: Date(timeIntervalSince1970: Double(networkingItem.created_at)),
            changeDate: Date(timeIntervalSince1970: Double(networkingItem.changed_at)),
            hex: networkingItem.color
        )
    }
    
    private func convertSingleToDo(with toDo: TodoItem) -> NetworkingItem {
        return NetworkingItem(
            files: nil,
            id: toDo.id,
            text: toDo.text,
            importance: NetworkingImportance.mapImportance(with: toDo.priority),
            deadline: toDo.deadLineDate?.unixTimeStamp,
            done: toDo.isCompleted,
            color: toDo.hex,
            created_at: toDo.creationDate.unixTimeStamp ?? Date.unixNow,
            changed_at: toDo.changeDate?.unixTimeStamp ?? Date.unixNow,
            last_updated_by: "qq"
        )
    }
}
