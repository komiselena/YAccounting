//
//  PieChartView.swift
//  Utilities
//
//  Created by Mac on 25.07.2025.
//


import UIKit

public final class PieChartView: UIView {
    private let segmentColors: [UIColor] = [
        .systemBlue, .systemGreen, .systemOrange,
        .systemPurple, .systemRed, .systemGray
    ]
    
    public var entities: [PieChartEntity] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var normalizedEntities: [(value: CGFloat, label: String)] = []
    private var totalValue: CGFloat = 0
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        prepareData()
        
        drawPieChart(in: rect, context: context)
        
        drawLegend(in: rect, context: context)
    }
    
    private func prepareData() {
        let mainEntities = entities.prefix(5)
        let otherEntities = entities.dropFirst(5)
        
        let mainValues = mainEntities.map { $0.value }
        let otherValue = otherEntities.reduce(0) { $0 + $1.value }
        
        var normalized: [(value: CGFloat, label: String)] = mainEntities.map {
            (value: CGFloat($0.value.doubleValue), label: $0.label)
        }
        
        if !otherEntities.isEmpty {
            normalized.append((value: CGFloat(otherValue.doubleValue), label: "Остальные"))
        }
        
        self.normalizedEntities = normalized
        self.totalValue = normalized.reduce(0) { $0 + $1.value }
    }
    
    private func drawPieChart(in rect: CGRect, context: CGContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.4
        var startAngle: CGFloat = -.pi / 2
        
        for (index, entity) in normalizedEntities.enumerated() {
            let endAngle = startAngle + 2 * .pi * (entity.value / totalValue)
            
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius,
                       startAngle: startAngle, endAngle: endAngle,
                       clockwise: true)
            path.close()
            
            let color = segmentColors[index % segmentColors.count]
            color.setFill()
            path.fill()
            
            startAngle = endAngle
        }
    }
    
    private func drawLegend(in rect: CGRect, context: CGContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let legendRadius = min(rect.width, rect.height) * 0.25
        
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            return formatter
        }()
        
        for (index, entity) in normalizedEntities.enumerated() {
            let angle = calculateMidAngle(for: index)
            let point = pointOnCircle(center: center, radius: legendRadius, angle: angle)
            
            let color = segmentColors[index % segmentColors.count]
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ]
            
            let formattedValue = numberFormatter.string(from: NSDecimalNumber(decimal: Decimal(entity.value))) ?? "\(entity.value)"
            let text = "\(entity.label): \(formattedValue)"
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: point.x - textSize.width / 2,
                y: point.y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    private func calculateMidAngle(for index: Int) -> CGFloat {
        guard !normalizedEntities.isEmpty else { return 0 }
        
        var startAngle: CGFloat = -.pi / 2
        for i in 0..<index {
            let entity = normalizedEntities[i]
            startAngle += 2 * .pi * (entity.value / totalValue)
        }
        
        let entity = normalizedEntities[index]
        let endAngle = startAngle + 2 * .pi * (entity.value / totalValue)
        
        return (startAngle + endAngle) / 2
    }
    
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}
