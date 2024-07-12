import SwiftUI
@_spi(Public) import MyPackage
struct AddNewCategoryView: View {
    @State var color: Double
    @State var name: String

    let addNewCategoryVM = AddNewCategoryViewModel()
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {

            List {
                Section {
                    HStack {
                        Text("Цвет:")
                        Spacer()
                        Text("#\(Color(hue: color, saturation: 1, brightness: 1).hex())")
                            .foregroundColor(Color(hue: color, saturation: 1, brightness: 1))

                    }
                    GradientPalette(selectedColor: $color)
                }

                Section {
                    TextField("Назовите категорию:", text: $name, axis: .vertical)
                        .lineLimit(1...2)
                        .scrollDismissesKeyboard(.immediately)
                }

                Section {
                    HStack {
                        Spacer()
                        Button(action: {
                            if  name != "" {
                                addNewCategoryVM.addNew(
                                    with: Activity(
                                        name: name,
                                        hexColor: Color(hue: color, saturation: 1, brightness: 1).hex()
                                    ))
                            }
                            presentationMode.wrappedValue.dismiss()
                        }, label: { Text("Добавить") .foregroundStyle(.primary) })
                        Spacer()

                    }
                }
            }
        }
    }
}

#Preview {
    AddNewCategoryView(color: 0.1, name: "")
}
