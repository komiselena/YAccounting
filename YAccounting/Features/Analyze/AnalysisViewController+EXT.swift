//
//  AnalysisViewController+EXT.swift
//  YAccounting
//
//  Created by Mac on 11.07.2025.
//

import UIKit

extension AnalysisViewController {
    func makeRow(titleLabel: UILabel, valueView: UIView, isLast: Bool) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stack.addArrangedSubview(titleLabel)

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(spacer)

        valueView.setContentHuggingPriority(.required, for: .horizontal)
        stack.addArrangedSubview(valueView)

        if let button = valueView as? UIButton {
            button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            button.layer.cornerRadius = 8
            button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        }

        if !isLast {
            let separator = UIView()
            separator.backgroundColor = UIColor.systemGray4
            separator.translatesAutoresizingMaskIntoConstraints = false
            stack.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.heightAnchor.constraint(equalToConstant: 0.5),
                separator.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: stack.bottomAnchor)
            ])
        }

        return stack
    }
}

