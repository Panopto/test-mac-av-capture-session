import Foundation
import AVFoundation

class Capture : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    let targetVideoWidth = 1280
    let targetVideoHeight = 720
    let targetVideoFrameRate: Double = 30.0
    let targetVideoFormat: FourCharCode = kCMPixelFormat_422YpCbCr8
    let videoOutputFormat: FourCharCode = kCMPixelFormat_422YpCbCr8
    
    let reportSampleInterval = 500
    
    var audioDevice: AVCaptureDevice? = nil
    var videoDevice: AVCaptureDevice? = nil

    var session: AVCaptureSession? = nil
    var videoOutput: AVCaptureVideoDataOutput? = nil
    var audioOutput: AVCaptureAudioDataOutput? = nil
    var videoQueue: DispatchQueue? = nil
    var audioQueue: DispatchQueue? = nil
    
    var startTime: NSDate? = nil
    var videoCount: Int = 0
    var audioCount: Int = 0
    
    init(audioDeviceIndex: Int?, videoDeviceIndex: Int?) {
        if audioDeviceIndex != nil {
            self.audioDevice = Device.GetAudioDevices()[audioDeviceIndex!]
            self.audioQueue = DispatchQueue(label: "audioQueue")
            Output.info("Use Audio device \(self.audioDevice!.description)")
        }

        if videoDeviceIndex != nil {
            self.videoDevice = Device.GetVideoDevices()[videoDeviceIndex!]
            self.videoQueue = DispatchQueue(label: "videoQueue")
            Output.info("Use Video device \(self.videoDevice!.description)")
        }
    }
    
    /**
     Build AVCapturesSession and start.
     */
    func start() throws {
        self.session = AVCaptureSession()
        self.session!.sessionPreset = .high

        try self.setupAudio()
        try self.setupVideo()
               
        self.startTime = nil
        self.videoCount = 0
        self.audioCount = 0
        self.session!.startRunning()
    }
    
    /**
     Configure audio input and also output
     */
    private func setupAudio() throws {
        if self.audioDevice == nil {
            return
        }
        
        // Create audio input and add to the session.
        guard let audioInput = try? AVCaptureDeviceInput(device: self.audioDevice!) else {
            throw RuntimeError("Failed to create AVCaptureDeviceInput")
        }
        if !(self.session!.canAddInput(audioInput)) {
            throw RuntimeError("failed to add input")
        }
        self.session!.addInputWithNoConnections(audioInput)
        
        // Configure audio output. 44.1kHz, 16-bit PCM stereo.
        self.audioOutput = AVCaptureAudioDataOutput()
        self.audioOutput!.setSampleBufferDelegate(self, queue: self.audioQueue)
        self.audioOutput!.audioSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2 ]
        if !(self.session!.canAddOutput(self.audioOutput!)) {
            throw RuntimeError("failed to add output")
        }
        self.session!.addOutputWithNoConnections(self.audioOutput!)
        
        let audioConnection = AVCaptureConnection(inputPorts:audioInput.ports, output:self.audioOutput!)
        if !(self.session!.canAddConnection(audioConnection)) {
            throw RuntimeError("failed to add connection")
        }
        self.session!.addConnection(audioConnection)
    }
    
    /**
     Configure video input and also output
     */
    private func setupVideo() throws {
        if self.videoDevice == nil {
            return
        }
        
        // Create video input and add to the session.
        guard let videoInput = try? AVCaptureDeviceInput(device: self.videoDevice!) else {
            throw RuntimeError("Failed to create AVCaptureDeviceInput")
        }
        if !(self.session!.canAddInput(videoInput)) {
            throw RuntimeError("failed to add input")
        }
        self.session!.addInput(videoInput)
        
        // Configure video device with the selected format and frame rate
        guard let config = Device.findVideoConfiguration(
            device: self.videoDevice!,
            width: targetVideoWidth,
            height: targetVideoHeight,
            videoFormat: targetVideoFormat,
            frameRate: targetVideoFrameRate
        ) else {
            throw RuntimeError("Target video configuraiton was not found.")
        }
        
        try! self.videoDevice!.lockForConfiguration()
        self.videoDevice!.activeFormat = config.format
        self.videoDevice!.activeVideoMinFrameDuration = config.range.minFrameDuration
        //self.videoDevice!.activeVideoMaxFrameDuration = config.range.minFrameDuration
        self.videoDevice!.unlockForConfiguration()
        
        // Configure video output.
        // The setting should be indentical to device input, except potentially color space conversion.
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput!.alwaysDiscardsLateVideoFrames = true
        self.videoOutput!.setSampleBufferDelegate(self, queue: self.videoQueue)
        self.videoOutput!.videoSettings = [
            kCVPixelBufferWidthKey as String: targetVideoWidth,
            kCVPixelBufferHeightKey as String: targetVideoHeight,
            kCVPixelBufferPixelFormatTypeKey as String: videoOutputFormat,
            AVVideoScalingModeKey as String:AVVideoScalingModeFit ]
        if !(self.session!.canAddOutput(self.videoOutput!)) {
            throw RuntimeError("failed to add output")
        }
        self.session!.addOutput(self.videoOutput!)
    }
    
    /**
     Stop the capture session. Not yet implemented.
     */
    func stop() {
        Output.info("Stop is not yet implemented")
    }

    /**
     Delegate to be invoked when video and audio samples are delivered.
     This does not process incoming samples at all.
     Just count the number of samples and done.
     */
    internal func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        
        if (self.startTime == nil) {
            // This is initial sample. Record start time here.
            self.startTime = NSDate()
        }
        let sinceStart = -self.startTime!.timeIntervalSinceNow
       
        if (output == self.videoOutput) {
            self.videoCount += 1
            if self.videoCount % reportSampleInterval == 10 {
                Output.info(String(format:"%7.1f sec: V %7d ( %2.1f FPS)",
                    sinceStart, self.videoCount, Double(self.videoCount - 1) / sinceStart));
            }
        }
        
        if (output == self.audioOutput) {
            self.audioCount += 1
            if self.audioCount % reportSampleInterval == 10 {
                Output.info(String(format:"%7.1f sec: A %7d",
                    sinceStart, self.audioCount));
            }
        }
    }
    
    /**
     Delegate to be inovked when capture session drops samples.
     */
    internal func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        if (output == self.videoOutput) {
            Output.info("video sample was dropped")
        } else if (output == self.audioOutput) {
            Output.info("audio sample was dropped")
        } else {
            Output.info("unknown sample was dropped")
        }
    }
}
