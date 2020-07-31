//
//  KScanDrawView.swift
//  KScanCamera
//
//  Created by WHB on 6/12/15.
//  Copyright (c) 2015 WHB. All rights reserved.
//

import UIKit

// 有扫描边框的view
class KScanDrawView: UIView {
    
    //绘制颜色
    private var drawColor = UIColor(red: 0, green: 116.0 / 255.0, blue: 222.0 / 255.0, alpha: 1.0).cgColor
    //线粗细
    private let drawLineWidth: CGFloat = 4
    //扫描边框宽度
    private let conerWidth: CGFloat = 24

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let width = self.frame.width
        let height = self.frame.height
        
        // Drawing code
        if let context: CGContext = UIGraphicsGetCurrentContext() {
            context.setLineWidth(drawLineWidth)
            context.setStrokeColor(drawColor)
            
            context.move(to: CGPoint(x: 0, y: conerWidth))
            context.addLine(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: conerWidth, y: 0))
            
            context.move(to: CGPoint(x: width - conerWidth, y: 0))
            context.addLine(to: CGPoint(x: width, y: 0))
            context.addLine(to: CGPoint(x: width, y: conerWidth))
            
            context.move(to: CGPoint(x: width, y: height - conerWidth))
            context.addLine(to: CGPoint(x: width, y: height))
            context.addLine(to: CGPoint(x: width - conerWidth, y: height))
            
            context.move(to: CGPoint(x: conerWidth, y: height))
            context.addLine(to: CGPoint(x: 0, y: height))
            context.addLine(to: CGPoint(x: 0, y: height - conerWidth))
            
            context.strokePath()
        }
    }

}
