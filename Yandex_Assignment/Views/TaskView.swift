import SwiftUI
import UIKit

struct TaskView: View {
    //  вью-модель эерана
    @State var vm: TaskViewModelManageable
    
    // вводимые данные
    @State var text: String
    @State var priority: TodoItem.Priority
    @State var deadLine: Date?
    @State var hexColor: String
    
    // данные логики отображение
    @State var isDeadlineSet: Bool
    @State var isEditing: Bool
    @State var isCalendarShowed: Bool
    
    @State var slider: Double // позиция слайдер
    @State var color: Double // значение hue для hsv
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // вычисляемое свойство для определения ориентации
    var isPortrait: Bool {
        if let verticalSizeClass, let horizontalSizeClass {
            switch (verticalSizeClass, horizontalSizeClass) {
            case (.compact, .compact):
                // обычный айфон в ландскейпе
                return false
            case (.compact, .regular):
                // макс в ландсекйпе
                return false
            case (.regular, .compact):
                // обычный айфон в портретной
                return true
            case (.regular, .regular):
                // айпад в портрете
                return true
            default:
                print("Ошибка выбора ориентации")
            }
        }
        return false
    }
    
    // заполняем данные, инжектим зависимость и режим использования вью
    init(
        item: TodoItem,
        vm: ListViewManageable,
        viewState: ViewState
        
    ) {
        self.text = item.text
        self.priority = item.priority
        self.deadLine = item.deadLineDate
        self.isDeadlineSet = item.deadLineDate != nil
        self.isEditing = false
        self.isCalendarShowed = false
        self.vm = TaskViewModel(item: item, itemListViewModel: vm, viewState: viewState)
        self.hexColor = item.hex ?? "000000"
        self.slider = 0.5
        self.color = 0.5
    }
    

    
    //
    func constructSegments(priority: TodoItem.Priority) -> some View {
        switch priority {
        case .unimportant:
            return AnyView(Image(systemName: "arrow.down"))
        case .usual:
            return AnyView(Text("нет"))
        case .important:
            return AnyView(Image(systemName: "exclamationmark.2").symbolRenderingMode(.palette).foregroundStyle(.red))
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Отменить")
                })
                .padding(10)
                .padding(.leading, 10)
                Spacer()
                Text("Дело")
                    .padding(10)
                Spacer()
                Button(action: {
                    // конструируем тудушку из данных и передаем ее во вьюмодель
                    let inputedItem = TodoItem(
                        text: text,
                        priority: priority,
                        deadLineDate: deadLine,
                        isCompleted: false,
                        creationDate: .now,
                        hex: hexColor
                    )
                    vm.add(newItem: inputedItem)
                    presentationMode.wrappedValue.dismiss()
                },
                       label: {
                    Text("Сохранить")
                })
                .padding(10)
                .padding(.trailing, 10)
            }
            if isPortrait {
                List {
                    Section {
                        TextField("Что нужно сделать?", text: $text, axis:.vertical)
                            .lineLimit(4...15)
                            .scrollDismissesKeyboard(.immediately)
                    }
                    Section {
                        HStack {
                            Text("Важность")
                            Spacer()
                            Picker("", selection: $priority) {
                                constructSegments(priority: .unimportant).tag(TodoItem.Priority.unimportant)
                                constructSegments(priority: .usual).tag(TodoItem.Priority.usual)
                                constructSegments(priority: .important).tag(TodoItem.Priority.important)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(maxWidth: 150)
                        }
                        VStack {
                            HStack {
                                Text("Цвет: ")
                                Text("#\(Color(hue: color, saturation: 1, brightness: slider).hex())")
                                    .foregroundColor(Color(hue: color, saturation: 1, brightness: slider))
                                    .onChange(of: color) {
                                        self.hexColor = Color(hue: color, saturation: 1, brightness: slider).hex()
                                    }
                                    .onChange(of: slider) {
                                        self.hexColor = Color(hue: color, saturation: 1, brightness: slider).hex()
                                    }
                                Spacer()
                            }
                            
                            GradientPalette(selectedColor: $color)
                                .padding(5)
                            Slider(value: $slider, in: 0.0001...1.0,  label: {Text("")})
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                            return viewDimensions[.leading]
                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Сделать до")
                                if isDeadlineSet {
                                    Button(deadLine?.getFormattedDateString() ?? "") {
                                        isCalendarShowed = true
                                    }
                                }
                            }
                            Toggle(isOn: $isDeadlineSet) {EmptyView()}
                                .onChange(of: isDeadlineSet) { oldValue, newValue in
                                    if newValue {
                                        deadLine = Date().addingTimeInterval(24 * 60 * 60)
                                    } else {
                                        deadLine = nil
                                    }
                                }
                        }
                        if isCalendarShowed {
                            DatePicker(selection: Binding(get: {deadLine ?? .now}, set: {deadLine = $0}), in: .now..., displayedComponents: .date, label: {})
                                .datePickerStyle(.graphical)
                        }
                    }
                    
                    Section {
                        HStack {
                            Spacer()
                            Button(action: {
                                vm.delete()
                                presentationMode.wrappedValue.dismiss()
                            }, label: {
                                Text("Удалить")
                                    .foregroundStyle(.red)
                            })
                            Spacer()
                            
                        }
                    }
                    
                }
                .transition(.move(edge: .bottom))
                .animation(.bouncy, value: isCalendarShowed)
                Spacer()
            } else {
                
                HStack {
                    List {
                        Section {
                            TextField("Что нужно сделать?", text: $text, axis: .vertical)
                                .onTapGesture {
                                    isEditing = true
                                }
                                .onSubmit {
                                    isEditing = false
                                }
                                .lineLimit(4...10)
                        }
                    }
                    if !isEditing {
                        List {
                            Section {
                                HStack {
                                    Text("Важность")
                                    Spacer()
                                    Picker("", selection: $priority) {
                                        constructSegments(priority: .unimportant).tag(TodoItem.Priority.unimportant)
                                        constructSegments(priority: .usual).tag(TodoItem.Priority.usual)
                                        constructSegments(priority: .important).tag(TodoItem.Priority.important)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .frame(maxWidth: 150)
                                    
                                    
                                    
                                }
                                VStack {
                                    HStack {
                                        Text("Цвет: ")
                                        Text("#\(Color(hue: color, saturation: 1, brightness: slider).hex())")
                                            .foregroundColor(Color(hue: color, saturation: 1, brightness: slider))
                                            .onChange(of: color) {
                                                self.hexColor = Color(hue: color, saturation: 1, brightness: slider).hex()
                                            }
                                        Spacer()
                                    }
                                    
                                    GradientPalette(selectedColor: $color)
                                        .padding(5)
                                    Slider(value: $slider, in: 0.0001...1.0,  label: {Text("")})
                                }                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Сделать до")
                                        if let date = deadLine {
                                            if isDeadlineSet {
                                                Button(date.getFormattedDateString()) {
                                                    
                                                }
                                            }
                                        }
                                    }
                                    Toggle(isOn: $isDeadlineSet) {EmptyView()}
                                        .onChange(of: isDeadlineSet) { oldValue, newValue in
                                            if newValue {
                                                deadLine = Date().addingTimeInterval(24 * 60 * 60)
                                                isDeadlineSet = newValue
                                            } else {
                                                deadLine = nil
                                                isDeadlineSet = newValue
                                            }
                                        }
                                }
                                if isDeadlineSet {
                                    DatePicker(selection: .constant(deadLine ?? .now), in: .now..., displayedComponents: .date, label: { })
                                        .datePickerStyle(.graphical)
                                }
                            }
                            Section {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        vm.delete()
                                        presentationMode.wrappedValue.dismiss()
                                    }, label: {
                                        Text("Удалить")
                                            .foregroundStyle(.red)
                                    })
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .animation(.bouncy, value: 1)
            }
        }
    }
}
