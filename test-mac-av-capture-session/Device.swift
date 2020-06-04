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
     Print out all video devices with the index, and also available formats of each device.
     */
    static func PrintVideoDevices() {
        Output.info("***** Video devices *****")
        let devices = GetVideoDevices()
        for i in 0..<devices.count {
            Output.info("Index \(i): \(devices[i].description)")
            for format in devices[i].formats {
                Output.info(" - \(format)")
            }
        }
        Output.info("")
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
    
    /**
     Find the video format and framerate which satisfy the target.
     Note: framerate handling is impefect. This verison only cares AVFrameRateRange.maxFrameRate.
     However, if the maximum of a range is beyond target, it does not work.
     e.g. range is 1.0-60.0 fps, target is 30.0 fps
     */
    static func findVideoConfiguration(
        device: AVCaptureDevice,
        width: Int,
        height: Int,
        videoFormat: FourCharCode,
        frameRate: Double
    ) -> (format: AVCaptureDevice.Format, range:AVFrameRateRange)? {
        for format in device.formats {
            // print ("Format: \(format.description)")
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let subtype:FourCharCode = CMFormatDescriptionGetMediaSubType(format.formatDescription);
            if (dimensions.width == width && dimensions.height == height && subtype == videoFormat) {
                var currentValidRange: AVFrameRateRange? = nil
                for range in format.videoSupportedFrameRateRanges {
                    // Find the frame rate which is smaller than target frame rate + 0.5.
                    // 0.5 is added as a margin becuase some cameras report the value as 30.00003
                    if (range.maxFrameRate > currentValidRange?.maxFrameRate ?? 0.0 &&
                        range.maxFrameRate <= frameRate + 0.5) {
                        currentValidRange = range
                    }
                }
                if (currentValidRange != nil) {
                    Output.info("Selected video format:")
                    Output.info("\(format.formatDescription)")
                    Output.info("Selected frame rate:")
                    Output.info("\(currentValidRange!.maxFrameRate) FPS")
                    Output.info("or \(currentValidRange!.minFrameDuration))")
                    return (format, currentValidRange!)
                }
            }
        }
        return nil
    }
}
