import SwiftUI

/*  гиперкостыль: найти png с hsv шкалой, запихать ее в ассеты, передать как изображение во вью,
 считывать geometryReader-ом положение касания, вычислять отношение к экрану и считать это за hue! */
struct GradientPalette: View {
    @Binding var selectedColor: Double

    var body: some View {
        GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    Image("hsvPalette", label: Text(""))
                        .resizable()
                        .edgesIgnoringSafeArea(.all)
                        .gesture(DragGesture().onChanged { value in
                            var hue: Double = value.location.x / geometry.size.width
                            if hue < 0.0 { hue = 0.0}
                            if hue > 1.0 { hue = 1.0}
                            selectedColor = hue
                        })
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

}
