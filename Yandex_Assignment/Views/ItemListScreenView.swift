import SwiftUI

struct ItemListScreenView: View {
    @State var showingSheet = false
    @State var showingSheetEdit = false
    @State var vm = ItemListViewModel(cacher: FileCache())
    
    @State var selectedItemForEditing: TodoItem?
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section{
                        ForEach(vm.itemList) { item in
                            ToDoCell(item: item)
                                .swipeActions(edge: .trailing) {
                                    Button(action: {
                                        vm.delete(with: item.id) }) {
                                            Label("Delete", systemImage: "trash").tint(.red)
                                        }
                                    Button(action: {
                                        // странная бага: первый презент отрабатывет с пустым вью, последующие - штатно
                                        presentationMode.wrappedValue.dismiss()
                                        selectedItemForEditing = item
                                        showingSheetEdit = true
                                    }, label: {
                                        Label("Edit", systemImage: "info.circle").tint(.gray)
                                    })
                                }
                                .swipeActions(edge: .leading) {
                                    Button(action: { vm.markDone(with: item.id) }) {
                                        Label("Done", systemImage: "checkmark.circle.fill").tint(.blue)
                                    }
                                }
                        }
                        Button(action: {
                            showingSheet.toggle()
                        }, label: {
                            NewCell()
                        })
                    }
                header: {
                    HStack {
                        Text("Выполнено — \(vm.doneItemsCount)")
                        Spacer()
                        Button(action: {
                            vm.isDoneShown.toggle()
                        }, label: {
                            Text(vm.isDoneShown == false ? "Показать": "Скрыть").font(.subheadline)
                        })
                    }
                }
                .textCase(.none)
                }
                .navigationTitle("Мои дела")
                VStack {
                    Spacer()
                    Button(action: {
                        showingSheet.toggle()
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                    })
                    .sheet(isPresented: $showingSheet) {
                        TaskView(
                            item: TodoItem(
                                text: "",
                                priority: .usual,
                                isCompleted: false,
                                hex: "00FF00"
                            ),
                            vm: vm,
                            viewState: .adding
                        )
                    }
                    .sheet(isPresented: $showingSheetEdit) {
                        if let selectedItem = selectedItemForEditing {
                            TaskView(item: selectedItem, vm: vm, viewState:.editing)
                        }
                    }
                }
            }
        }
        .onAppear {
            vm.fetch()
        }
    }
}



extension TodoItem: Identifiable {}

#Preview {
    ItemListScreenView()
}
