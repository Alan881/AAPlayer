//
//  ViewController.swift
//  AAPlayer
//
//  Created by Alan on 2017/6/28.
//  Copyright © 2017年 Alan. All rights reserved.
//

import UIKit



class ViewController: UIViewController, AAPlayerDelegate {
    @IBOutlet weak var player: AAPlayer!
    
    fileprivate var sourceArray: Array<Any>!
    fileprivate var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sourceArray = ["http://d3tz4ep8usobz3.cloudfront.net/clip/19/clip.m3u8","http://live.zzbtv.com:80/live/live123/800K/tzwj_video.m3u8","http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8","http://bos.nj.bpc.baidu.com/tieba-smallvideo/0173bbaf5acf62b815a7de0544730d6c.mp4","http://bos.nj.bpc.baidu.com/tieba-smallvideo/00a52c5e2213216ce0ce3795d40e9492.mp4","http://bos.nj.bpc.baidu.com/tieba-smallvideo/0045ab5a9e440defb2611658c0914724.mp4"]
        player.delegate = self
        player.playVideo(sourceArray[currentIndex] as! String)
        
    }
    
    @IBAction func beforeBtn(_ sender: Any) {
        
        currentIndex = currentIndex - 1
        if currentIndex < 0 {
            currentIndex = 0
            return
        }
        
        player.playVideo(sourceArray[currentIndex] as! String)
        
    }
  
    @IBAction func nextBtn(_ sender: Any) {
        
        currentIndex = currentIndex + 1
        if currentIndex > sourceArray.count - 1 {
            currentIndex = sourceArray.count - 1
            return
        }
        
        player.playVideo(sourceArray[currentIndex] as! String)
        
    }
    
    
    //optional method
    func callBackDownloadDidFinish(_ status: playerItemStatus?) {
        
        let status:playerItemStatus = status!
        switch status {
            
        case .readyToPlay:
            
            break
        case .failed:
            
            break
        default:
            break
        }
    }
    
    func startPlay() {
        //optional method
        player.startPlayback()
    }
    
    func stopPlay() {
        //optional method
        player.pausePlayback()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

