import Foundation

actor CancellationManager {
    var task: URLSessionDataTask?
    var isRunning = true
    
    func cancel() {
        isRunning = false
        task?.cancel()
    }
    
    func setTask(with dataTask: URLSessionDataTask) {
        task = dataTask
    }
}

extension URLSession {
    func dataTask(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        let manager = CancellationManager()
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    let task = self.dataTask(with: urlRequest) { data, response, error in
                        
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let data = data, let response = response {
                            print("Запрос прошел, возвращаем данные")
                            continuation.resume(returning: (data, response))
                        } else {
                            continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: nil))
                        }
                    }
                    await manager.setTask(with: task)
                    if await manager.isRunning {
                        task.resume()
                    } else {
                        print("Запрос отменен, кидаем ошибку")
                        continuation.resume(throwing: CancellationError())
                    }
                }
            }
        } onCancel: {
            Task { await manager.cancel() }
        }
    }
}
