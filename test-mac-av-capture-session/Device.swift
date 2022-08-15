import Foundation
import AVFoundation

/**
 Static class to hold various device related functions.
 */
class Device {
    /**
     Get the array of available video devices.
     */
    static func GetVideoDevices() -> [AVCaptureDevice] {
        let session = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified)
        
        return session.devices
    }
    
    /**
     Get the array of available audio devices.
     */
    static func GetAudioDevices() -> [AVCaptureDevice] {
        let session = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified)
        
        return session.devices
    }
       
    /**
     Print out all audio devices with the index.
     */
    static func PrintAudioDevices() {
        Output.info("***** Audio devices *****")
        let devices = GetAudioDevices()
        for i in 0..<devices.count {
            Output.info("Index \(i): \(devices[i].description)")
        }
        Output.info("")
    }
}
