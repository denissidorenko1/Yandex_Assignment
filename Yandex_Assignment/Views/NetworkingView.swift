import SwiftUI

struct NetworkingView: View {
    @State var joke: String = "Пока шутка не пришла"
    
    var body: some View {
        VStack {
            Button(action: {
                Task {
                   joke = await getJoke()
                }
            }, label: {
                Text("Нажми для шутки")
                    .padding()
            })
            Text(joke)
                .padding()
        }
    }
    

    @MainActor // гарантируем что метод будет вызван из главного потока, чтобы не было race condition
    private func getJoke() async -> String {
        let url = URL(string: "https://v2.jokeapi.dev/joke/Any?blacklistFlags=nsfw,religious,political,racist,sexist,explicit&format=txt")!
        let request = URLRequest(url: url)
        let fetchTask = Task {
            do {
                let a = try await URLSession.shared.dataTask(for: request)
                print(String(decoding: a.0, as: UTF8.self))
                return String(decoding: a.0, as: UTF8.self)
            } catch {
                return error.localizedDescription
            }
        }
        // раскомментируй для отмены
//        fetchTask.cancel()
        return await fetchTask.value
    }
}

#Preview {
    NetworkingView()
}
