# test-mac-av-capture-session
This command line application is a test tool of AVCaptureSession.

This app builds an AVCaptureSession with a specified video device and/or a specified audio device.

The video input is configured as 1280x720, 30FPS, YUVS format.
The video output is configured as same as input, therefore I expect no translation happens from input to output.

The audio oupput is configured as 44.1kHz, 16bit PCM, stereo.

Audio and video samples are delivered to the delegate in this application. The delegate counts the incoming samples and shows the status every 500 samples. The delegates does not do anything further, like encoding the samples or saving the samples to somewhere. Therefore, this is considered the minimum operaiton of AVCaptureSession.

This is created for a troubleshooting of with Apple technical support. Panpto or the authors may not answer any questions if you are not actively working on this topic with us at this time.

## Usage
```
OVERVIEW: Command line tool to configure AVCpatureSession with an audio device and a video device.

USAGE: test-mac-av-capture-session [--list-devices] [--video-device-index <video-device-index>] [--audio-device-index <audio-device-index>]

OPTIONS:
  -l, --list-devices      List connected devices. 
  -v, --video-device-index <video-device-index>
                          Index of target video device. 
  -a, --audio-device-index <audio-device-index>
                          Index of target sudio device. 
  -h, --help              Show help information.
```

Example to build and start AVCaptureSession with the default camera and micrphone (most likely Facetime camera and built-in microhpone).
```
./test-mac-av-capture-session -a 0 -v 0
```

## License
Copyright 2020 Panopto

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
