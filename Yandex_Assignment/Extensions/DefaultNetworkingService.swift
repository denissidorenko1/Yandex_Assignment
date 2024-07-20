import Foundation

// MARK: - конвертеры сетевого представления данных и обычной тудушки
extension DefaultNetworkingService {
    func convertNetworkingList(with networkingItems: [NetworkingItem]) -> [TodoItem] {
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
    
    func convertToDoList(with toDoItems: [TodoItem]) -> [NetworkingItem] {
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
                last_updated_by: "inavailable"
                
            )
            networkingItems.append(newMock)
        }
        return networkingItems
    }
    
    func convertNetworkingItem(with networkingItem: NetworkingItem) -> TodoItem {
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
    
    func convertToDoItem(with toDo: TodoItem) -> NetworkingItem {
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
            last_updated_by: "inavailable"
        )
    }
}
