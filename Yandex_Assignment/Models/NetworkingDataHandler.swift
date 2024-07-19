import Foundation
actor NetworkingDataHandler {
    var items: [MockItem] = []
    
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
//        isDirty = true
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
        print("edit 1")
        guard !isDirty else {
            try await handleOutOfSync()
            print("edit 2")
            return convertMockToToDoItem(with: items)
        }
        print("edit 3")
        let newItem = convertSingleToDo(with: newVersion)
        print("edit 4")
        let newMock = try await service.editItem(with: newItem) // - вот отсюда ошибки лезут
        if let index = items.firstIndex(where: { $0.id == newMock.id }) {
            print("edit 5")
            items[index] = newMock
            return convertMockToToDoItem(with: items)
        } else {
            print("edit 6")
//            isDirty = true
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
    
    private func convertMockToToDoItem(with mockItems: [MockItem]) -> [TodoItem] {
        var items: [TodoItem] = []
        
        for mockItem in mockItems {
            var deadLineDate: Date?
            if let deadline = mockItem.deadline {
                deadLineDate = Date(timeIntervalSince1970: Double(deadline))
            }
            let item = TodoItem(
                id: mockItem.id,
                text: mockItem.text,
                priority: ImportanceTest.mapPriority(with: mockItem.importance),
                deadLineDate: deadLineDate,
                isCompleted: mockItem.done,
                creationDate: Date(timeIntervalSince1970: Double(mockItem.created_at)),
                changeDate: Date(timeIntervalSince1970: Double(mockItem.changed_at)),
                hex: mockItem.color
            )
            items.append(item)
        }
        return items
    }
    
    private func convertToDoToMock(with toDoItems: [TodoItem]) -> [MockItem] {
        var mockItems: [MockItem] = []
        for item in toDoItems {
            let newMock = MockItem(
                files: nil,
                id: item.id,
                text: item.text,
                importance: ImportanceTest.mapImportance(with: item.priority),
                deadline: item.deadLineDate?.unixTimeStamp,
                done: item.isCompleted,
                color: item.hex,
                created_at: item.creationDate.unixTimeStamp ?? Date.unixNow,
                changed_at: item.changeDate?.unixTimeStamp ?? Date.unixNow,
                last_updated_by: "qq"
                
            )
            mockItems.append(newMock)
        }
        return mockItems
    }
    
    private func convertSingleMock(with mockItem: MockItem) -> TodoItem {
        var deadLineDate: Date?
        if let deadline = mockItem.deadline {
            deadLineDate = Date(timeIntervalSince1970: Double(deadline))
        }
        
        return TodoItem(
            id: mockItem.id,
            text: mockItem.text,
            priority: ImportanceTest.mapPriority(with: mockItem.importance),
            deadLineDate: deadLineDate,
            isCompleted: mockItem.done,
            creationDate: Date(timeIntervalSince1970: Double(mockItem.created_at)),
            changeDate: Date(timeIntervalSince1970: Double(mockItem.changed_at)),
            hex: mockItem.color
        )
    }
    
    private func convertSingleToDo(with toDo: TodoItem) -> MockItem {
        return MockItem(
            files: nil,
            id: toDo.id,
            text: toDo.text,
            importance: ImportanceTest.mapImportance(with: toDo.priority),
            deadline: toDo.deadLineDate?.unixTimeStamp,
            done: toDo.isCompleted,
            color: toDo.hex,
            created_at: toDo.creationDate.unixTimeStamp ?? Date.unixNow,
            changed_at: toDo.changeDate?.unixTimeStamp ?? Date.unixNow,
            last_updated_by: "qq"
        )
    }
    
}

