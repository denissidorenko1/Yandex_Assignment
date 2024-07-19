import SwiftUI
import CocoaLumberjackSwift

struct ItemListScreenView: View {
    @State var showingSheet = false
    @State var showingCalendar = false

    @State var itemListVM = ItemListViewModel(cacher: FileCache())

    @State var selectedItemForEditing: TodoItem?

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ZStack {

                List {
                    Section {
                        ForEach(itemListVM.itemList) { item in
                            ToDoCell(item: item)
                                .swipeActions(edge: .trailing) {
                                    Button(action: {
                                        itemListVM.delete(with: item.id) }) {
                                            Label("Delete", systemImage: "trash").tint(.red)
                                        }
                                    Button(action: {
                                        selectedItemForEditing = item
                                    }, label: {
                                        Label("Edit", systemImage: "info.circle").tint(.gray)
                                    })
                                }
                                .swipeActions(edge: .leading) {
                                    Button(action: {
                                            print("toggle done?")
                                            itemListVM.toggleDone(with: item.id)
                                    }) {
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
                    VStack(alignment: .leading) {
                            NavigationLink {
                                let calendarVM = CalendarViewModel(
                                    model: FileCache(),
                                    itemListViewModel: itemListVM
                                )
                                let calendarWrapper = CalendarWrapper(calendarVM: calendarVM)
                                calendarWrapper
                                    .navigationTitle("Мои дела")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .ignoresSafeArea()
                            } label: {
                                Image(systemName: "calendar")
                            }
                        HStack {
                            Text("Выполнено — \(itemListVM.doneItemsCount)")
                            Spacer()
                            Button(action: {
                                itemListVM.isDoneShown.toggle()
                            }, label: {
                                Text(itemListVM.isDoneShown == false ? "Показать": "Скрыть").font(.subheadline)
                            })
                        }
                    }
                }
                .textCase(.none)
                }
                .navigationTitle("Мои дела")
                VStack {
                    Spacer()
                    
//                    Button {
//                        itemListVM.fetch()
//                    } label: {
//                        Image(systemName: "screwdriver")
//                            .resizable()
//                            .frame(width: 44, height: 44)
//                    }

                    
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
                            viewModel: itemListVM,
                            viewState: .adding
                        )
                    }
                    .sheet(item: $selectedItemForEditing,
                           content: {smth  in
                            TaskView(
                                item: smth,
                                viewModel: itemListVM,
                                viewState: .editing
                            )
                    })
                }
            }
        }
        .onAppear {
            DDLogInfo("Обновляем данные в списке \(Self.self)")
            itemListVM.fetch()
        }
        
    }
}

extension TodoItem: Identifiable {}

#Preview {
    ItemListScreenView()
}
