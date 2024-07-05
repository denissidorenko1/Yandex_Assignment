import UIKit
import SwiftUI

final class CalendarViewDateCell: UICollectionViewCell {
    
    static let ReuseId = "ReuseId"
    private let dayLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(dayLabel)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        setupConstraintsForDate()
        contentView.backgroundColor = UIColor(red: 245/255, green: 244/255, blue: 240/255, alpha: 1)
        setupFonts()
        dayLabel.textAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func makeSelected() {
        contentView.backgroundColor = UIColor(red: 207/255, green: 207/255, blue: 191/255, alpha: 1)
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = UIColor(red: 142/255, green: 142/255, blue: 142/255, alpha: 1).cgColor
        contentView.layer.borderWidth = 2
    }
    
    func deselect() {
        contentView.backgroundColor = UIColor(red: 245/255, green: 244/255, blue: 240/255, alpha: 1)
        contentView.layer.cornerRadius = 0
        contentView.layer.borderColor = UIColor(red: 142/255, green: 142/255, blue: 142/255, alpha: 1).cgColor
        contentView.layer.borderWidth = 0
    }
    
    func setupFonts() {
        dayLabel.textColor = UIColor(red: 142/255, green: 142/255, blue: 142/255, alpha: 1)
        dayLabel.numberOfLines = 5
        dayLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
    }
    
    
    
    private func setupConstraintsForDate() {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: dayLabel.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: dayLabel.topAnchor),
        ])
    }



    func setContent(with date: Date?) {
        if let date = date {
            let components = date.getFormattedDateString().split(separator: " ")
            let formattedComponents = "\(components[0])\n\n\(components[1])" 
            dayLabel.text = formattedComponents
        } else {
            dayLabel.text = "Другое"
        }
    }
}



