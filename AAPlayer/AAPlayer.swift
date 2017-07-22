//
//  AAPlayer.swift
//  AAPlayer
//
//  Created by Alan on 2017/6/28.
//  Copyright © 2017年 Alan. All rights reserved.
//

import UIKit
import AVFoundation

class AAPlayer: UIView {
    
    fileprivate var player:AVPlayer?
    fileprivate var playerLayer:AVPlayerLayer?
    fileprivate var playerItem:AVPlayerItem?
    fileprivate var playUrl:String!
    fileprivate var playButton:AAPlayButton!
    fileprivate var smallPlayButton:AAPlayButton!
    fileprivate var playProgressView:AAPlayProgressView!
    fileprivate var playerSlider:AAPlayerSlider!
    fileprivate var playerBottomView:UIView!
    fileprivate var timeLabel:UILabel!
    fileprivate var timer:Timer?
    fileprivate var playbackObserver:Any?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initWithPlayBottomView()
        initWithPlayButton()
        initWithPlayProgressView()
        initWithSlider()
        initWithTimeLabel()
    }
    
    //MARK:- Interface Builder(Xib,StoryBoard)
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initWithPlayBottomView()
        initWithPlayButton()
        initWithPlayProgressView()
        initWithSlider()
        initWithTimeLabel()
        
    }

    deinit {
        
        removeAllObserver()
        resettingObject()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setPlayerSubviewsFrame()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
    }

    //MARK:- initialize method
    fileprivate func initWithPlayBottomView() {
        
        layer.backgroundColor = UIColor(red: 31/255, green: 37/255, blue: 61/255, alpha: 1).cgColor
        playerBottomView = UIView()
        playerBottomView.backgroundColor = UIColor.black
        playerBottomView.alpha = 0
        addSubview(playerBottomView)
    }
    
    
    fileprivate func initWithPlayButton() {
    
        playButton = AAPlayButton()
        playButton.addTarget(self, action: #selector(startPlay), for: .touchUpInside)
        addSubview(playButton)
        smallPlayButton = AAPlayButton()
        smallPlayButton.addTarget(self, action: #selector(startPlay), for: .touchUpInside)
        playerBottomView.addSubview(smallPlayButton)
    }
    
    fileprivate func initWithPlayProgressView() {
        
        playProgressView = AAPlayProgressView(progressViewStyle: .bar)
        playProgressView.progressTintColor = UIColor(red: 102/255, green: 178/255, blue: 255/255, alpha: 0.5)
        playProgressView.trackTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
        playProgressView.setProgress(0.0, animated: true)
        playerBottomView.addSubview(playProgressView)
        
    }
    
    fileprivate func initWithSlider() {
        
        playerSlider = AAPlayerSlider()
        playerSlider.tintColor = UIColor.clear
        playerSlider.backgroundColor = UIColor.clear
        playerSlider.maximumTrackTintColor = UIColor.clear
        playerSlider.minimumTrackTintColor = UIColor(red: 231/255, green: 107/255, blue: 107/255, alpha: 1)
        playerSlider.minimumValue = 0
        playerSlider.isContinuous = false
        playerSlider.addTarget(self, action: #selector(touchPlayerProgress), for: [.touchDown, .touchUpInside])
        playerBottomView.addSubview(playerSlider)
    }
    
    fileprivate func initWithTimeLabel() {
        
        timeLabel = UILabel()
        timeLabel.textColor = UIColor.white
        timeLabel.font = UIFont.boldSystemFont(ofSize: 9)
        playerBottomView.addSubview(timeLabel)
    }
    
    //MARK:- frame method
    fileprivate func setPlayerSubviewsFrame() {
        
        playerBottomView.frame = CGRect(x: 0, y: frame.height - 50, width: frame.width, height: 50)
        playerLayer?.frame = bounds
        playButton.frame = CGRect(x: frame.width / 2 - 25, y: frame.height / 2 - 25, width: 50, height: 50)
        playButton.center = CGPoint(x: frame.width / 2 , y: frame.height / 2)
        playProgressView.frame = CGRect(x: 50, y: playerBottomView.frame.height / 2, width: playerBottomView.frame.width - 165, height: 2)
        playerSlider.frame = CGRect(x: 45, y: playerBottomView.frame.height / 2 - 9, width: playerBottomView.frame.width - 140, height: 20)
        smallPlayButton.frame = CGRect(x: 10, y: playerBottomView.frame.height / 2 - 11, width: 30, height: 25)
        timeLabel.frame = CGRect(x: playerBottomView.frame.width - 95, y: playerBottomView.frame.height / 2 - 9, width: 100, height: 20)
    }
    
    
    //MARK:- setting player
    fileprivate func setPlayRemoteUrl() {
        
        if playUrl == nil || playUrl == "" {
            return
        }
        removeAllObserver()
        resettingObject()
        let asset = AVAsset(url: URL(string: playUrl)!)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        playerLayer?.contentsScale = UIScreen.main.scale
        layer.insertSublayer(playerLayer!, at: 0)
        setAllObserver()
    }
    
    //MARK:- setting observer
    fileprivate func setAllObserver() {
        
        player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

    }
    
    fileprivate func removeAllObserver() {
        
        player?.removeObserver(self, forKeyPath: "rate")
        playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        playerItem?.removeObserver(self, forKeyPath: "status")
        
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "status" {
            
            observePlayerStatus()
            
        } else if keyPath == "loadedTimeRanges" {
            
            let currentTime = getBufferTimeDuration()
            let totalTime = CMTimeGetSeconds((playerItem?.duration)!)
            let percent = currentTime / totalTime
            playProgressView.progress = Float(percent)
            
        } else if keyPath == "rate" {
            
            if (object as! AVPlayer).rate == 0 && Int(playerSlider.value) == Int(playerSlider.maximumValue)  {
                smallPlayButton.isSelected = false
                setPlayBottomViewAnimation()
            }
            
        }
    }
    
    
    //MARK:- check player status
    fileprivate func observePlayerStatus() {
        
        let status:AVPlayerItemStatus = (player?.currentItem?.status)!
        switch status {
        case .readyToPlay:
            
            if Float(CMTimeGetSeconds((playerItem?.duration)!)).isNaN  == true { return }
            playerSlider.addTarget(self, action: #selector(changePlayerProgress), for: .valueChanged)
            playerSlider.maximumValue = Float(CMTimeGetSeconds((playerItem?.duration)!))
            let allTimeString = timeFotmatter(Float(CMTimeGetSeconds((playerItem?.duration)!)))
            playbackObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: nil, using: { (time) in
                let during = self.playerItem!.currentTime()
                let time = during.value / Int64(during.timescale)
                self.timeLabel.text = "\(self.timeFotmatter(Float(time)))/\(allTimeString)"
                if !self.playerSlider.isHighlighted {
                    self.playerSlider.value = Float(time)
                } 
            })
            
            break
        case .failed:
            
            break
        default:
            
            break
        }
        
    }
    
 
   //MARK:- get buffer time duration
    fileprivate func getBufferTimeDuration() -> TimeInterval {
    
        let loadedTimeRanges =  player!.currentItem!.loadedTimeRanges
        guard let timeRange = loadedTimeRanges.first?.timeRangeValue else { return 0.0 }
        let start = CMTimeGetSeconds(timeRange.start)
        let duration = CMTimeGetSeconds(timeRange.duration)
        let currentTimeDuration = (start + duration)
        return currentTimeDuration

    }
    
    //MARK:- calculate time formatter
    fileprivate func timeFotmatter(_ time:Float) -> String {
        
        var hr:Int!
        var min:Int!
        var sec:Int!
        var timeString:String!
        
        if time >= 3600 {
            hr = Int(time / 3600)
            min = Int(time.truncatingRemainder(dividingBy: 3600))
            sec = Int(min % 60)
            timeString = String(format: "%02d:%02d:%02d", hr, min, sec)
        } else if time >= 60 && time < 3600 {
            min = Int(time / 60)
            sec = Int(time.truncatingRemainder(dividingBy: 60))
            timeString = String(format: "00:%02d:%02d", min, sec)
        } else if time < 60 {
            sec = Int(time)
            timeString = String(format: "00:00:%02d", sec)
        }
        
        return timeString
    }
    
    //MARK:- setting player display
    @objc fileprivate func startPlay() {
        
        if playButton.isHidden == false {
            setPlayRemoteUrl()
            setPlayBottomViewAnimation()
        }
        
        if player?.rate == 0 {
            player?.play()
            playButton.isSelected = true
            playButton.isHidden = true
            smallPlayButton.isSelected = true
            stopTimer()
            startTimer()
            
        } else {
            player?.pause()
            playButton.isSelected = false
            smallPlayButton.isSelected = false
            stopTimer()
        }

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        setPlayBottomViewAnimation()
        stopTimer()
        if player?.rate == 1 && playerBottomView.alpha == 1 {
            startTimer()
        }
    }
    
    @objc fileprivate func setPlayBottomViewAnimation() {
        
        UIView.animate(withDuration: 0.5) {
            if self.playerBottomView.alpha == 0 {
                self.playerBottomView.alpha = 1
            } else {
                self.playerBottomView.alpha = 0
            }
        }

    }
    
    
    //MARK:- timer
    fileprivate func startTimer() {
        
        timer = Timer()
        timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(setPlayBottomViewAnimation), userInfo: nil, repeats: false)
    }
    
    fileprivate func stopTimer() {
        
        if timer == nil {
            return
        }
        timer?.invalidate()
        timer = nil
    }
    
    //MARK:- change player progress
    @objc fileprivate func changePlayerProgress() {
        
        let seekDuration = playerSlider.value
        player?.seek(to: CMTimeMake(Int64(seekDuration), 1), completionHandler: { (BOOL) in
            
        })

    }

    @objc fileprivate func touchPlayerProgress() {
        
        if playerSlider.isHighlighted {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    //MARK: - resetting display view
    fileprivate func resettingObject() {
        
        player = nil
        playerLayer = nil
        playbackObserver = nil
        playerItem = nil
        
    }
    
    //MARK: - public control method
    func playVideo(_ url:String) {
        
        playUrl = url
        playButton.isHidden = false
        playButton.isSelected = false
        smallPlayButton.isSelected = false
        if playbackObserver != nil {
            player?.removeTimeObserver(playbackObserver!)
            playbackObserver = nil
            player?.pause()
        }
        playerLayer?.removeFromSuperlayer()
        playerSlider.removeTarget(self, action: #selector(changePlayerProgress), for: .valueChanged)
        playerSlider.value = 0.0
        timeLabel.text = "00:00:00/00:00:00"
    }
   
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
