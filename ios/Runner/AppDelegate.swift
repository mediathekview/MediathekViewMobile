import UIKit
import Flutter
import AVFoundation
import flutter_downloader


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
        
        let controller : FlutterBinaryMessenger = window?.rootViewController as! FlutterBinaryMessenger
        let videoMethodChannel = FlutterMethodChannel(name: "com.mediathekview.mobile/video", binaryMessenger: controller)
        
        let videoEventChannel = FlutterEventChannel(name: "com.mediathekview.mobile/videoEvent", binaryMessenger: controller)
        
        let videoProgressEvent = FlutterEventChannel(name: "com.mediathekview.mobile/videoProgressEvent", binaryMessenger: controller)
        
        let videoEventStreamHandler = VideoStreamHandler()
        videoEventChannel.setStreamHandler(videoEventStreamHandler)
        
        let videoProgressEventStreamHandler = VideoProgressStreamHandler()
        videoProgressEvent.setStreamHandler(videoProgressEventStreamHandler)

        videoMethodChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: FlutterResult) -> Void in
            guard let args = call.arguments else {
                return
            }
            
            guard let myArgs = args as? [String: Any] else {
                result("iOS could not extract flutter arguments in method: (sendParams)")
                return
            }
            
            if call.method == "videoPreviewPicture" {
                guard let videoId = myArgs["videoId"] as? String else {
                    NSLog("Video id has to be set")
                    result("Video id has to be set")
                    return
                }
                
                // either url or filename is set
                if let url = myArgs["url"] as? String {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let url = URL(string: url)
                        if url != nil {
                            self.createThumbnailOfVideoFromRemoteUrl(url: url!, videoId: videoId as String, videoEventStreamHandler: videoEventStreamHandler)
                        } else {
                            NSLog("URL to create thumbnail form is nil")
                        }
                                     }
                } else if let fileName = myArgs["fileName"] as? String {
                    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                    let documentsDirectory = paths[0]
                    
                    let localFilePath = documentsDirectory + "/MediathekView/" + fileName
                    NSLog("IOS filename for preview is " + localFilePath)
                    let url = URL(fileURLWithPath: localFilePath)
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.createThumbnailOfVideoFromRemoteUrl(url: url, videoId: videoId as String, videoEventStreamHandler: videoEventStreamHandler)
                    }
                    }
                return
            }
        })
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func createThumbnailOfVideoFromRemoteUrl(url: URL, videoId: String, videoEventStreamHandler: VideoStreamHandler) {
        var resultMap: [String: Any] = [:]
        resultMap["videoId"] =  videoId
        
        
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            // PNG Image
            if let previewBytes = thumbnail.pngData() as NSData? {
                resultMap["image"] = FlutterStandardTypedData(bytes: previewBytes as Data)
                videoEventStreamHandler.onPreviewReceived(returnArgs: resultMap)
                
            } else {
                print("Downcast to NSDATA failed")
                /* [FlutterError errorWithCode:@"UNAVAILABLE"
                    message:@"Charging status unavailable"
                    details:nil] */
            }
        } catch {
            print(error.localizedDescription)
            return
        }
    }
}

private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
        FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin") as! FlutterPluginRegistrar)
    }
}
