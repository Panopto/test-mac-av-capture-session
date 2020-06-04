import Foundation
import ArgumentParser
import os

/**
 Command line options, pased by Swift Argument Parser package..
 Refer: https://github.com/apple/swift-argument-parser
 */
struct Options: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: (CommandLine.arguments[0] as NSString).lastPathComponent,
        abstract: "Command line tool to configure AVCpatureSession with an audio device and a video device.")

    @Flag(name: .shortAndLong, help: "List connected devices.")
    var listDevices: Bool

    @Option(name: .shortAndLong, help: "Index of target video device.")
    var videoDeviceIndex: Int?

    @Option(name: .shortAndLong, help: "Index of target sudio device.")
    var audioDeviceIndex: Int?
}

let options = Options.parseOrExit();

if options.listDevices {
    Device.PrintVideoDevices()
    Device.PrintAudioDevices()
} else if (options.videoDeviceIndex != nil || options.audioDeviceIndex != nil) {
    let capture = Capture(
        audioDeviceIndex: options.audioDeviceIndex,
        videoDeviceIndex: options.videoDeviceIndex)
    try! capture.start()
    
    print("Running. Stop to type any key.")
    let _ = readLine()
    
    capture.stop()
} else {
    print(Options.helpMessage())
}


