//
//  PieChartView.swift
//  Utilities
//
//  Created by Mac on 25.07.2025.
//


import UIKit

public final class PieChartView: UIView {
    private let segmentColors: [UIColor] = [
        UIColor(red: 0.35, green: 0.71, blue: 0.92, alpha: 1.0),
        UIColor(red: 0.47, green: 0.84, blue: 0.47, alpha: 1.0),
        UIColor(red: 0.99, green: 0.73, blue: 0.52, alpha: 1.0),
        UIColor(red: 0.81, green: 0.62, blue: 0.85, alpha: 1.0),
        UIColor(red: 0.94, green: 0.56, blue: 0.56, alpha: 1.0),
        UIColor(red: 0.78, green: 0.78, blue: 0.78, alpha: 1.0)  
    ]
    
    private let ringWidth: CGFloat = 12.0
    
    public var entities: [PieChartEntity] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var normalizedEntities: [(value: CGFloat, label: String)] = []
    private var totalValue: CGFloat = 0
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !entities.isEmpty else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        prepareData()
        drawRingChart(in: rect, context: context)
        drawLegendList(in: rect)
    }
    
    private func prepareData() {
        let mainEntities = entities.prefix(5)
        let otherEntities = entities.dropFirst(5)
        
        let otherValue = otherEntities.reduce(Decimal(0)) { $0 + $1.value }
        
        var normalized: [(value: CGFloat, label: String)] = mainEntities.map {
            (value: CGFloat($0.value.doubleValue), label: $0.label)
        }
        
        if !otherEntities.isEmpty {
            normalized.append((value: CGFloat(otherValue.doubleValue), label: "Другие"))
        }
        
        self.normalizedEntities = normalized
        self.totalValue = normalized.reduce(0) { $0 + $1.value }
    }
    
    private func drawRingChart(in rect: CGRect, context: CGContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.35
        var startAngle: CGFloat = -.pi / 2
        
        for (index, entity) in normalizedEntities.enumerated() {
            let endAngle = startAngle + 2 * .pi * (entity.value / totalValue)
            
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            
            let color = segmentColors[index % segmentColors.count]
            color.setStroke()
            path.lineWidth = ringWidth
            path.stroke()
            
            startAngle = endAngle
        }
    }
    
    private func drawLegendList(in rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let legendStartY = center.y - CGFloat(normalizedEntities.count) * 20 / 2
        
        for (index, entity) in normalizedEntities.enumerated() {
            let yPosition = legendStartY + CGFloat(index) * 24
            let color = segmentColors[index % segmentColors.count]
            
            let circlePath = UIBezierPath(
                ovalIn: CGRect(
                    x: center.x - 60,
                    y: yPosition - 6,
                    width: 12,
                    height: 12
                )
            )
            color.setFill()
            circlePath.fill()
            
            let percentage = (entity.value / totalValue) * 100
            let text = "\(entity.label): \(String(format: "%.1f", percentage))%"
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: center.x - 40,
                y: yPosition - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}
extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}
