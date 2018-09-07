//
//  AAPlayerDecode.swift
//  AAPlayer
//
//  Created by Alan on 2017/10/17.
//  Copyright © 2017年 Alan. All rights reserved.
//

import Foundation
import UIKit


public protocol ffmpegDelegate : class {
    
    func callBackImage(_ image:UIImage)
    func callBackYUVFrame(_ frame:UnsafeMutablePointer<H264YUV_Frame>)
}

class AAPlayerDecode: NSObject {
    
    public var delegate: ffmpegDelegate?
    private var currentImage: UIImage? {
        get {
            if (frame?.pointee.data.0 == nil) {
                return nil
            }
            return setImageScaler()
        }
    }
    
    private var formatCtx: UnsafeMutablePointer<AVFormatContext>?
    private var codeCtx: UnsafeMutablePointer<AVCodecContext>?
    private var videoStream: Int32?
    private var avcode: UnsafeMutablePointer<AVCodec>?
    private var stream: UnsafeMutablePointer<AVStream>?
    private var packet: AVPacket?
    private var fps: Double?
    private var frame: UnsafeMutablePointer<AVFrame>?
    var aFrame: UnsafeMutablePointer<AVFrame>?
    private var outputWidth: Int32?
    private var outputHeight: Int32?
    private var isReleaseResources: Bool?
    private var targetFrameData = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1);
    private var targetFrameLinesize: UnsafeMutablePointer<Int32>?
    private var timer: Timer?
    var isReady: Bool?
    var distFrameLuma = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
    var distFrameChromaB = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
    var distFrameChromaR = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
    var srcFrameData0 = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
    let srcFrameData1 = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
    let srcFrameData2 = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
    
    override init() {
        super.init()
        // register decoder
        avcodec_register_all()
        av_register_all()
    }

    func receiveResource(_ url: String) -> Bool {
    
        isReady = false
        stopTimer()
        avformat_network_init()
        // (打開檔案)open media file && handle AVFormatContext struct
        formatCtx = avformat_alloc_context()
        if avformat_open_input(&formatCtx, url, nil, nil) != 0 {
           print("fail to open file")
           return false
        }
        // （從檔案中提取串流）check media stream
        if avformat_find_stream_info(formatCtx, nil) < 0 {
            print("fail to find stream")
            return false
        }
        // (找到第一個視頻串流)find first media stream
        videoStream = av_find_best_stream(formatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &avcode, 0)
        if videoStream == nil {
            print("fail to find first stream")
            return false
        }
        // (獲取視頻串流上下文的指針)find the next point and code of stream
        stream = formatCtx?.pointee.streams[Int(videoStream!)]
    
        codeCtx = avcodec_alloc_context3(avcode)
        avcodec_parameters_to_context(codeCtx, stream?.pointee.codecpar)
        
       // av_codec_set_pkt_timebase(codeCtx, (stream?.pointee.time_base)!)
        // debug
        print(av_dump_format(formatCtx, videoStream!, url, 0))
        
        if ((stream?.pointee.avg_frame_rate.den) != nil) && ((stream?.pointee.avg_frame_rate.num) != nil) {
            fps = av_q2d((stream?.pointee.avg_frame_rate)!)
        } else {
            fps = 30
        }
        // 找解碼器
        if (codeCtx?.pointee.codec_id != nil) {
            avcode = avcodec_find_decoder((codeCtx?.pointee.codec_id)!)
        }
        if avcode == nil {
            print("fail to find decoder")
            return false
        }
        if (avcodec_open2(codeCtx, avcode, nil) < 0) {
            print("fail to open decoder")
            return false
        }
        // 分配視頻帧
        frame = av_frame_alloc()
        
        let targetFrame = av_frame_alloc()
        if frame == nil || targetFrame == nil {
            return false
        }
        packet = AVPacket.init()
        outputWidth = codeCtx?.pointee.width
        outputHeight = codeCtx?.pointee.height
        
        let size = av_image_get_buffer_size(AV_PIX_FMT_RGB24, outputWidth! * 3, outputHeight! * 3, 1)
        let buffer = av_malloc(Int(size))
        av_new_packet(&packet!, size)
     
        withUnsafeMutablePointer(to: &(targetFrame!.pointee)) { point in
            point.withMemoryRebound(to: UInt8.self, capacity: 1, { data in
                targetFrameData.pointee = data
            })
        }
        withUnsafeMutablePointer(to: &(targetFrame!.pointee)) { point  in
            point.withMemoryRebound(to: Int32.self, capacity: 1, { data in
                targetFrameLinesize = data
            })
        }
        let sizeBuffer = buffer?.assumingMemoryBound(to: UInt8.self)
  
        av_image_fill_arrays(targetFrameData, targetFrameLinesize, sizeBuffer, codeCtx!.pointee.pix_fmt, outputWidth! * 3, outputHeight! * 3, 1)
        isReady = true
        
//        DispatchQueue.global(qos: .default).async {
//
//            
        // _ =  self.stepFrame()
//            
//            
//        }
        
        
        return true
    }
    
    func seekTime(to: Double) {
        
        if videoStream == nil {
            print("fail to seek stream")
            return
        }
        let timeBase = formatCtx?.pointee.streams[Int(videoStream!)]?.pointee.time_base
        if (timeBase == nil) {
            print("fail to seek time base")
            return
        }
        let targetFrame = Int64(Double(timeBase!.den) / Double(timeBase!.num) * to)
        avformat_seek_file(formatCtx, videoStream!, 0, targetFrame, targetFrame, AVSEEK_FLAG_FRAME)
        avcodec_flush_buffers(codeCtx)
    }
    
    func stepFrame() -> Bool {
          //DispatchQueue.global().async {
    
        while av_read_frame(formatCtx, &packet!) >= 0 {
            
                if (packet?.stream_index == videoStream) {
                    var frameFinished = avcodec_send_packet(codeCtx, &packet!)
                   
                if (frameFinished < 0 || frameFinished == EAGAIN || frameFinished == EOF) {
                    print("有問題")
                    break
                }
                    while frameFinished >= 0 {
                    frameFinished = avcodec_receive_frame(codeCtx, frame)
                    if (frameFinished == EAGAIN || frameFinished == EOF) {
                       print("有問題\(frameFinished)")
                       break
                    }
                    print("packet->data==%d",packet?.size as Any)
                    print("Frame decoded PTS:")
                    print(frameFinished)
            
                  //  makeYUVToRGBFrame()
                    return true
                }
            }
            print("釋放")
            av_packet_unref(&packet!)
        }
      // releaseResources()
       // }
       return false
    }
    
    func setImageScaler() -> UIImage? {
    
        let imgConvertCtx = sws_getContext((frame?.pointee.width)!, (frame?.pointee.height)!, (codeCtx?.pointee.pix_fmt)!, outputWidth!, outputHeight!, AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, nil, nil, nil)
        if (imgConvertCtx == nil) {
            return nil
        }
        let result = swsScale(option: imgConvertCtx!, source: frame!, height: (frame?.pointee.height)!)
        print(result)
        if (result == 0) {
            return nil
        }
        sws_freeContext(imgConvertCtx)
        let bitmapInfo = CGBitmapInfo(rawValue: 0)
        let data = CFDataCreate(kCFAllocatorDefault, targetFrameData.pointee, CFIndex(targetFrameLinesize!.pointee * outputHeight! ))
        let provider = CGDataProvider.init(data: data!)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgImage = CGImage.init(width: Int(outputWidth!), height: Int(outputHeight!), bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow:  Int(targetFrameLinesize!.pointee), space: colorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)
        if (cgImage == nil) {
            return nil
        }
        let image = UIImage.init(cgImage: cgImage!)
        return image
    }
    
    func swsScale(option: OpaquePointer, source: UnsafePointer<AVFrame>, height: Int32) -> Int {
        
        let sourceData = [
            UnsafePointer<UInt8>(source.pointee.data.0),
            UnsafePointer<UInt8>(source.pointee.data.1),
            UnsafePointer<UInt8>(source.pointee.data.2),
            UnsafePointer<UInt8>(source.pointee.data.3),
            UnsafePointer<UInt8>(source.pointee.data.4),
            UnsafePointer<UInt8>(source.pointee.data.5),
            UnsafePointer<UInt8>(source.pointee.data.6),
            UnsafePointer<UInt8>(source.pointee.data.7),
            ]
        let sourceLineSize = [
            source.pointee.linesize.0,
            source.pointee.linesize.1,
            source.pointee.linesize.2,
            source.pointee.linesize.3,
            source.pointee.linesize.4,
            source.pointee.linesize.5,
            source.pointee.linesize.6,
            source.pointee.linesize.7
        ]
        
        let result = sws_scale(
            option,
            sourceData,
            sourceLineSize,
            0,
            height,
            targetFrameData,
            targetFrameLinesize
        )
        return Int(result)
    }
    
    func makeYUVToRGBFrame() {
        
        let lumaLength = (codeCtx?.pointee.height)! * min((frame?.pointee.linesize.0)!, (codeCtx?.pointee.width)!)
        let chromBLength = ((codeCtx?.pointee.height)! / 2 ) * min((frame?.pointee.linesize.1)!, (codeCtx?.pointee.width)! / 2)
        let chromRLength = ((codeCtx?.pointee.height)! / 2 ) * min((frame?.pointee.linesize.1)!, (codeCtx?.pointee.width)! / 2)
    
        var yuvFrame = H264YUV_Frame()
    
        memset(&yuvFrame, 0, MemoryLayout.size(ofValue: H264YUV_Frame.self))
        yuvFrame.luma.length = UInt32(lumaLength)
        yuvFrame.chromaB.length = UInt32(chromBLength)
        yuvFrame.chromaR.length = UInt32(chromRLength)
        
        
        yuvFrame.luma.dataBuffer = malloc(MemoryLayout.size(ofValue: lumaLength)).assumingMemoryBound(to: __uint32_t.self)
        yuvFrame.chromaB.dataBuffer = malloc(MemoryLayout.size(ofValue: chromBLength)).assumingMemoryBound(to: __uint32_t.self)
        yuvFrame.chromaR.dataBuffer = malloc(MemoryLayout.size(ofValue: chromRLength)).assumingMemoryBound(to: __uint32_t.self)
        
//        withUnsafeMutablePointer(to: &yuvFrame.luma.dataBuffer.pointee) { point in
//            point.withMemoryRebound(to: UInt32.self, capacity: 1, { data in
//                distFrameLuma.pointee = data.pointee
//            })
//        }
        //distFrameLuma = yuvFrame.luma.dataBuffer

//        withUnsafeMutablePointer(to: &yuvFrame.chromaB.dataBuffer) { point in
//            point.withMemoryRebound(to: UInt32.self, capacity: 1, { data in
//                distFrameChromaB.pointee = data.pointee
//            })
//        }
       // distFrameChromaB = yuvFrame.chromaB.dataBuffer
        
//        withUnsafeMutablePointer(to: &yuvFrame.chromaR.dataBuffer) { point in
//            point.withMemoryRebound(to: UInt32.self, capacity: 1, { data in
//                distFrameChromaR.pointee = data.pointee
//            })
//        }
       // distFrameChromaR = yuvFrame.chromaR.dataBuffer
        
//        withUnsafeMutablePointer(to: &frame!.pointee.data.0) { point in
//            point.withMemoryRebound(to: __uint32_t.self, capacity: 1, { data in
//                srcFrameData0.pointee = data.pointee
//            })
//        }
        srcFrameData0.pointee = __uint32_t(frame!.pointee.data.0!.pointee)
        
//        withUnsafeMutablePointer(to: &frame!.pointee.data.1!.pointee) { point in
//            point.withMemoryRebound(to: UInt32.self, capacity: 1, { data in
//                srcFrameData1.pointee = data.pointee
//            })
//        }
        srcFrameData1.pointee = __uint32_t(frame!.pointee.data.1!.pointee)
        
//        withUnsafeMutablePointer(to: &frame!.pointee.data.2!.pointee) { point in
//            point.withMemoryRebound(to: UInt32.self, capacity: 1, { data in
//                srcFrameData2.pointee = data.pointee
//            })
//        }
        srcFrameData2.pointee = __uint32_t(frame!.pointee.data.2!.pointee)
        
        copyDecodedFrame((srcFrameData0) , yuvFrame.luma.dataBuffer, UInt32((frame?.pointee.linesize.0)!), UInt32((codeCtx?.pointee.width)!), height: UInt32((codeCtx?.pointee.height)!))
        copyDecodedFrame((srcFrameData1), yuvFrame.chromaB.dataBuffer, UInt32((frame?.pointee.linesize.1)!), UInt32((codeCtx?.pointee.width)!/2), height: UInt32((codeCtx?.pointee.height)!/2))
        copyDecodedFrame((srcFrameData2), yuvFrame.chromaR.dataBuffer, UInt32((frame?.pointee.linesize.2)!), UInt32((codeCtx?.pointee.width)!/2), height: UInt32((codeCtx?.pointee.height)!/2))
        
//        withUnsafeMutablePointer(to: &distFrameLuma.pointee) { point in
//            point.withMemoryRebound(to: UInt8.self, capacity: 1, { data in
               // yuvFrame.luma.dataBuffer = distFrameLuma
//            })
//        }
//
//        withUnsafeMutablePointer(to: &distFrameChromaB.pointee) { point in
//            point.withMemoryRebound(to: UInt8.self, capacity: 1, { data in
               // yuvFrame.chromaB.dataBuffer = distFrameChromaB
//            })
//        }
//
//        withUnsafeMutablePointer(to: &distFrameChromaR.pointee) { point in
//            point.withMemoryRebound(to: UInt8.self, capacity: 1, { data in
                //yuvFrame.chromaR.dataBuffer = distFrameChromaR
//            })
//        }
    
        yuvFrame.width = UInt32(codeCtx!.pointee.width)
        yuvFrame.height = UInt32(codeCtx!.pointee.height)
        DispatchQueue.main.async {
            self.delegate?.callBackYUVFrame(&yuvFrame)
        }
        //free(yuvFrame.luma.dataBuffer)
        //free(yuvFrame.chromaB.dataBuffer)
       // free(yuvFrame.chromaR.dataBuffer)
        
       // free(srcFrameData0)
       // free(srcFrameData1)
       // free(srcFrameData2)
        
    }
    
    func copyDecodedFrame(_ src:UnsafeMutablePointer<UInt32>, _ dist:UnsafeMutablePointer<UInt32>, _ lineszie: UInt32, _ width: UInt32, height:UInt32) {
        
        var newWidth = width
        newWidth = min(lineszie, newWidth)
        for _ in 0..<height {
            memcpy(dist, src, Int(newWidth))
            dist.pointee += newWidth
            src.pointee += lineszie
        }
    }
    
    
    func play() {
        
        seekTime(to: 0.0)
        startTimer()
    }
    
    func stop() {
        
        stopTimer()

    }
    
    fileprivate func stopTimer() {
        
        timer?.invalidate()
    }
    
    fileprivate func startTimer() {
        
        timer = Timer.scheduledTimer(timeInterval: 1 / fps!, target: self, selector: #selector(displayNextFrame(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func displayNextFrame(_ timer:Timer) {
      //  let startTime = Date.timeIntervalSinceReferenceDate
      DispatchQueue.global(qos: .userInitiated).sync {
        
        if self.stepFrame() == false {
            timer.invalidate()
            av_packet_unref(&self.packet!)
            return
        }
        
           // makeYUVToRGBFrame()
        
         DispatchQueue.main.async {
        let currentImage = self.currentImage
        if (currentImage != nil) {
           // Thread.sleep(forTimeInterval: 1.0/80.0)
            self.delegate?.callBackImage(currentImage!)
        }
        }
       // }
           // av_packet_unref(&self.packet!)
        }
    }
    
    func releaseResources() {
        
        isReleaseResources = true
        av_packet_unref(&packet!)
        targetFrameLinesize = nil
        targetFrameData.pointee = nil
        av_free(frame)
        if (codeCtx != nil) {
            avcodec_close(codeCtx)
        }
        if (formatCtx != nil) {
            avformat_close_input(&formatCtx)
        }
        avformat_network_deinit()
    }
    
   
}
