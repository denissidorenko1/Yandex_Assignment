//
//  NewCell.swift
//  Yandex_Assignment
//
//  Created by Denis on 28.06.2024.
//

import SwiftUI

struct NewCell: View {
    var body: some View {
        Text("Новое")
            .font(.custom("Subhead", size: 15))
            .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.68, opacity: 1.0))
            .padding(.leading, 35)
    }
}

#Preview {
    NewCell()
}
