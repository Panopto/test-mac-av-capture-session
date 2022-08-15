import Foundation
import AVFoundation

class Capture : NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    let reportSampleInterval = 100
    
    var audioDevice: AVCaptureDevice? = nil

    var session: AVCaptureSession? = nil
    var audioOutput: AVCaptureAudioDataOutput? = nil
    var audioQueue: DispatchQueue? = nil
    
    var startTime: NSDate? = nil
    var audioCount: Int = 0
    
    init(audioDeviceIndex: Int?) {
        if audioDeviceIndex != nil {
            self.audioDevice = Device.GetAudioDevices()[audioDeviceIndex!]
            self.audioQueue = DispatchQueue(label: "audioQueue")
            Output.info("Use Audio device \(self.audioDevice!.description)")
        }
    }
    
    /**
     Build AVCapturesSession and start.
     */
    func start() throws {
        self.session = AVCaptureSession()
        self.session!.sessionPreset = .high

        try self.setupAudio()
               
        self.startTime = nil
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
       
        if (output == self.audioOutput) {
            self.audioCount += 1
            if self.audioCount % reportSampleInterval == 10 {
                Output.info(String(format:"%7.1f sec: A %7d",
                    sinceStart, self.audioCount));
            }
        }
        else {
            Output.info("delegate call from an unknown output.")
        }
    }
    
    /**
     Delegate to be inovked when capture session drops samples.
     */
    internal func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        if (output == self.audioOutput) {
            Output.info("audio sample was dropped")
        } else {
            Output.info("unknown sample was dropped")
        }
    }
}
