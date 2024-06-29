import SwiftUI

struct ToDoCell: View {
    enum CircleState {
        case blank
        case red
        case green
    }
    
    var item: TodoItem
    
    var body: some View {
        ZStack {
            HStack(spacing: 3) {
                if item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    
                        .padding(.trailing, 10)
                } else if item.priority == .important {
                    ZStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.init(hue: 0.0, saturation: 0.1, brightness: 1.0))
                        Image(systemName: "circle")
                            .foregroundColor(.red)
                    }
                    .padding(.trailing, 10)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.gray)
                        .padding(.trailing, 10)
                }
                if item.priority != .usual && item.isCompleted != true {
                    Image(systemName: item.priority == .important ? "exclamationmark.2" : "arrow.down" )
                        .foregroundColor(item.priority == .important ? .red : .gray)
                        .frame(width: 16, height: 20)
                }
                VStack(alignment: .leading, spacing: .zero) {
                    Text(item.text)
                        .lineLimit(3)
                        .strikethrough(item.isCompleted, color: .gray)
                        .foregroundColor(item.isCompleted == true ? .gray : .primary)
                    if let deadline =  item.deadLineDate  {
                        HStack(spacing: .zero) {
                            Image(systemName: "calendar")
                            Text(deadline.getFormattedDateString())
                        }
                        .font(Font.subheadline)
                        .foregroundStyle(.gray)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            VStack { Spacer()
                Path { path in
                    path.move(to: CGPoint(x: UIScreen.main.bounds.size.width - 100 , y: 0))
                    path.addLine(to: CGPoint(x: UIScreen.main.bounds.size.width - 100, y: 30))
                }
                .stroke(Color.colorFromHex(hex: item.hex ?? "000000"), lineWidth: 5)
                Spacer()
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
            return viewDimensions[.leading] + 35
        }
    }
}


#Preview {
    ToDoCell(
        item: TodoItem(
            text: "smth",
            priority: .important,
            isCompleted: .random(),
            hex: "00FF00"
        )
    )
}
