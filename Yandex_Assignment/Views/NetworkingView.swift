//import SwiftUI
//
//struct NetworkingView: View {
//    @State var joke: String = "Пока шутка не пришла"
//    let service = DefaultNetworkingService()
//    var body: some View {
//        VStack {
//            Button {
//                delete()
//            } label: {
//                Text("delete")
//            }
//
//            
//            Button {
//                addNew()
//            } label: {
//                Text("new")
//            }
//
//            
//            Button(action: {
//               Task {
//                   joke = await getJoke()
////                    try? await service.getList()
//                }
//            }, label: {
//                Text("Нажми для шутки")
//                    .padding()
//            })
//            Text(joke)
//                .padding()
//        }
//    }
//    
//    @MainActor
//    private func delete() {
//        let id = "25364276-0791-4198-9F6F-B9974E8FEB73"
//        Task {
//            do {
//                try await service.deleteItem(with: id)
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
//    
//    @MainActor
//    private func addNew()  {
//        
//        Task {
//            do {
////                try await service.addItem()
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//        
//    }
//    
//
//    @MainActor // гарантируем что метод будет вызван из главного потока, чтобы не было race condition
//    private func getJoke() async -> String {
////        let url = URL(string: "https://v2.jokeapi.dev/joke/Any?blacklistFlags=nsfw,religious,political,racist,sexist,explicit&format=txt")!
////        let request = URLRequest(url: url)
//        let fetchTask = Task {
//            do {
//                let a = try await service.getList()
//                return ""
////                let a = try await URLSession.shared.dataTask(for: request)
////                print(String(decoding: a.0, as: UTF8.self))
////                return String(decoding: a.0, as: UTF8.self)
//            } catch {
//                return error.localizedDescription
//            }
//        }
//        // раскомментируй для отмены
////        fetchTask.cancel()
//        return await fetchTask.value
//    }
//}
//
//#Preview {
//    NetworkingView()
//}
