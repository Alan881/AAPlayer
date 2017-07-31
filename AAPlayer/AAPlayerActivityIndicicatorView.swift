//
//  AAPlayerActivityIndicicatorView.swift
//  AAPlayer
//
//  Created by Alan on 2017/7/24.
//  Copyright © 2017年 Alan. All rights reserved.
//

import UIKit

class AAPlayerActivityIndicicatorView: UIView {
    
    fileprivate var indicicatorLayer: CALayer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initWithIndicicatorLayer()
        isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    
    }
    override func layoutSubviews() {
        
        indicicatorLayer.frame = CGRect(x: 0,y: 0,width: frame.size.width,height: frame.size.height)
        indicicatorLayer.contents = createIndicicatorImage().cgImage
    }
    
    fileprivate func initWithIndicicatorLayer() {
        
        indicicatorLayer = CALayer()
        indicicatorLayer.masksToBounds = true
        layer.addSublayer(indicicatorLayer)

    }
    
    fileprivate func createIndicicatorImage() -> UIImage {
        
        UIGraphicsBeginImageContext(CGSize(width: frame.width, height: frame.height))
        let context = UIGraphicsGetCurrentContext()
        let path:CGMutablePath = CGMutablePath()
        context!.addArc(center:CGPoint(x: frame.width / 2, y: frame.height / 2), radius: 40, startAngle: 0, endAngle: 1.5 * CGFloat(Double.pi), clockwise: true)
        context!.move(to: CGPoint(x: 50, y: 100))
        context!.addLine(to: CGPoint(x: 50, y: 150))
        context!.addLine(to: CGPoint(x: 100, y: 150))
        context!.addPath(path)
        let colors = [UIColor(red: 231/255, green: 107/255, blue: 107/255, alpha: 0.6).cgColor,UIColor(red: 231/255, green: 107/255, blue: 107/255, alpha: 0.3).cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations:[CGFloat] = [0.6, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)
        context?.drawRadialGradient(gradient!, startCenter:CGPoint(x: frame.width / 2, y: frame.height / 2), startRadius: 0, endCenter: CGPoint(x: frame.width / 2 + 5, y: frame.height / 2 + 5), endRadius: 10, options: .drawsBeforeStartLocation)
        UIColor(red: 231/255, green: 107/255, blue: 107/255, alpha: 1).setStroke()
        context?.drawPath(using: .stroke)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    fileprivate func setAnimation() -> CABasicAnimation {
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.duration = 1.0
        rotation.isRemovedOnCompletion = false
        rotation.repeatCount = Float.infinity
        rotation.fillMode = kCAFillModeForwards
        rotation.fromValue = 0.0
        rotation.toValue = Double.pi * 2;
        return rotation
    }
    
    fileprivate func pauseAnimation() {
        
        let pausedTime = indicicatorLayer.convertTime(CACurrentMediaTime(), from: nil)
        indicicatorLayer.speed = 0.0
        indicicatorLayer.timeOffset = pausedTime
    }
    
    fileprivate func resumeAnimation() {
        
        let pauseTime = indicicatorLayer.timeOffset
        indicicatorLayer.speed = 1.0
        indicicatorLayer.timeOffset = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pauseTime
        indicicatorLayer.beginTime = timeSincePause
    }
    
    
    func startAnimation() {
        
        if indicicatorLayer.animation(forKey: "rotation") == nil {
            indicicatorLayer.add(setAnimation(), forKey: "rotation")
        }
        
        isHidden = false
        resumeAnimation()
    }
    
    func stopAnimation() {
        
        isHidden = true
        pauseAnimation()
        
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
