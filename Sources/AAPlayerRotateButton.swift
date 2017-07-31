//
//  AAPlayerRotateButton.swift
//  AAPlayer
//
//  Created by Alan on 2017/7/25.
//  Copyright © 2017年 Alan. All rights reserved.
//

import UIKit

class AAPlayerRotateButton: UIButton {
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        
        if isSelected {
            setOriginalSizeIconImage(rect)
        } else {
            setFullSizeIconImage(rect)
        }
        
        addTarget(self, action: #selector(setDisplaySize), for: .touchUpInside)
    }
 
    fileprivate func setFullSizeIconImage(_ rect: CGRect) {
        
        let rect = rect
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: rect.origin.x + 5 + rect.width - 20, y: rect.origin.y + 5))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + rect.width - 10, y: rect.origin.y + 5))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + rect.width - 10, y: rect.origin.y + 15))
        context.move(to: CGPoint(x: rect.origin.x + 5 + rect.width - 10, y: rect.origin.y + 5))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 + 4, y: rect.origin.y + 5 + (rect.height - 10)/2 - 4))
        context.move(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 - 4, y: rect.origin.y + 5 + (rect.height - 10)/2 + 4))
        context.addLine(to: CGPoint(x: rect.origin.x + 5, y: rect.origin.y + 5 + rect.height - 10))
        context.addLine(to: CGPoint(x: rect.origin.x + 5, y: rect.origin.y + 5 + rect.height - 10 - 10))
        context.move(to: CGPoint(x: rect.origin.x + 5, y: rect.origin.y + 5 + rect.height - 10))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + 10, y: rect.origin.y + 5 + rect.height - 10))
        context.strokePath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        setImage(image, for: .normal)
    }
    
    fileprivate func setOriginalSizeIconImage(_ rect: CGRect) {
        
        let rect = rect
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: rect.origin.x + 5 + rect.width - 10, y: rect.origin.y + 5))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 + 4, y: rect.origin.y + 5 + (rect.height - 10)/2 - 4))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 + 4 + 10, y: rect.origin.y + 5 + (rect.height - 10)/2 - 4))
        context.move(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 + 4, y: rect.origin.y + 5 + (rect.height - 10)/2 - 4))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 + 4, y: rect.origin.y + 5 + (rect.height - 10)/2 - 4 - 10))
        context.move(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 - 4, y: rect.origin.y + 5 + (rect.height - 10)/2 + 4))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 - 4 - 10, y: rect.origin.y + 5 + (rect.height - 10)/2 + 4))
        context.move(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 - 4, y: rect.origin.y + 5 + (rect.height - 10)/2 + 4))
        context.addLine(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 - 4, y: rect.origin.y + 5 + (rect.height - 10)/2 + 4 + 10))
        context.move(to: CGPoint(x: rect.origin.x + 5 + (rect.width - 10)/2 - 4, y: rect.origin.y + 5 + (rect.height - 10)/2 + 4))
        context.addLine(to: CGPoint(x: rect.origin.x + 5, y: rect.origin.y + 5 + rect.height - 10))
        context.strokePath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        setImage(image, for: .selected)
    }
    
    //MARK:- setting display full size or original size
    @objc fileprivate func setDisplaySize() {
        
        if isSelected {
            
            isSelected = false
            let value =  UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            
        } else {
            
            isSelected = true
            let value =  UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()

        }
    
    }
    


}
