//
//  TransactionCell.swift
//  YAccounting
//
//  Created by Mac on 11.07.2025.
//

import UIKit

class TransactionCell: UITableViewCell {
    private let emojiContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(.operationImageBG)
        view.layer.cornerRadius = 16
        return view
    }()
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    private let percentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .none
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(emojiContainer)
        emojiContainer.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(percentLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            emojiContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiContainer.widthAnchor.constraint(equalToConstant: 32),
            emojiContainer.heightAnchor.constraint(equalToConstant: 32),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            percentLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            percentLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -4),

            amountLabel.topAnchor.constraint(equalTo: percentLabel.bottomAnchor, constant: 2),
            amountLabel.trailingAnchor.constraint(equalTo: percentLabel.trailingAnchor)
        ])
    }

    func configure(with transaction: Transaction, category: Category?, totalAmount: Decimal) {
        if let cat = category {
            emojiLabel.text = String(cat.emoji)
            titleLabel.text = cat.name
        } else {
            emojiLabel.text = "💸"
            titleLabel.text = transaction.comment ?? "Операция"
        }

        subtitleLabel.text = transaction.comment ?? "Без описания"

        let percent: Double
        if totalAmount != 0 {
            let ratio = (Decimal(string: transaction.amount) ?? 0 / totalAmount) as NSDecimalNumber
            percent = ratio.doubleValue * 100
        } else {
            percent = 0
        }
        percentLabel.text = String(format: "%.0f%%", percent)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        let amountString = "\(transaction.amount)"
        amountLabel.text = "\(amountString) ₽"
    }
}
