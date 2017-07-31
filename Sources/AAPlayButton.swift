//
//  AAPlayButton.swift
//  AAPlayer
//
//  Created by Alan on 2017/7/1.
//  Copyright © 2017年 Alan. All rights reserved.
//

import UIKit

class AAPlayButton: UIButton {

    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if isSelected {
            setPauseIconImage(rect)
            
        } else {
            setPlayIconImage(rect)
            
        }
        
    }
    
    fileprivate func setPauseIconImage(_ rect: CGRect) {
        
        let rect = rect
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor(red: 66/255, green: 114/255, blue: 155/255, alpha: 1).cgColor)
        context.setLineWidth(8.0)
        context.move(to: CGPoint(x: 8, y: 0))
        context.addLine(to: CGPoint(x: 8, y: 25))
        context.move(to: CGPoint(x: 20, y: 0))
        context.addLine(to: CGPoint(x: 20, y: 25))
        context.strokePath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setImage(image, for: .selected)
    }

    fileprivate func setPlayIconImage(_ rect: CGRect) {
        
        let rect = rect
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor(red: 66/255, green: 114/255, blue: 155/255, alpha: 1).cgColor)
        context.move(to: CGPoint(x: 3, y: 0))
        context.addLine(to: CGPoint(x: 3, y: rect.size.height))
        context.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height / 2))
        context.closePath()
        context.fillPath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setImage(image, for: .normal)
        
    }
}
