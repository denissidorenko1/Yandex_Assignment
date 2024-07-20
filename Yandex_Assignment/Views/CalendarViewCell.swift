import UIKit
import SwiftUI
@_spi(Public) import MyPackage
final class CalendarViewItemCell: UITableViewCell {
    var sectionIndex: Int?
    let label = UILabel()
    let categoryMark = UIImageView(image: UIImage(systemName: "circle.fill"))
    static let ReuseId = "ReuseId"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        contentView.addSubview(categoryMark)
        categoryMark.contentMode = .scaleAspectFill
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(with item: TodoItem) {
        label.attributedText = NSAttributedString(string: item.text, attributes: item.isCompleted == true ? [.strikethroughStyle: NSUnderlineStyle.single.rawValue] : [:])
        label.textColor = item.isCompleted == true ? .gray : .label
        if item.category?.hexColor != "FFFFFF" {
            categoryMark.layer.shadowColor = UIColor.black.cgColor
            categoryMark.layer.shadowRadius = 3
            categoryMark.layer.shadowOpacity = 0.5
            categoryMark.layer.shadowOffset = CGSize(width: 0, height: 5)
            categoryMark.tintColor = UIColor(Color.colorFromHex(hex: item.category?.hexColor ?? "FFFFFF"))
            categoryMark.layer.backgroundColor = UIColor.clear.cgColor
        } else {
            categoryMark.tintColor = .clear
        }

        label.contentMode = .scaleToFill
    }

    private func setupConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        categoryMark.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            label.trailingAnchor.constraint(equalTo: categoryMark.leadingAnchor, constant: 10),

            categoryMark.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),
            categoryMark.widthAnchor.constraint(equalToConstant: 20),
            categoryMark.heightAnchor.constraint(equalToConstant: 20),
            categoryMark.centerYAnchor.constraint(equalTo: label.centerYAnchor),

            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
}
