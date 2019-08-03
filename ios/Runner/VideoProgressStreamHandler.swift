//
//  VideoProgressStreamHandler.swift
//  Runner
//
//  Created by Foehr, Daniel on 18.07.19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Foundation

class VideoProgressStreamHandler : FlutterAppDelegate, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
    
        NSLog("iOs progress event not implemented - using flutter plugin")
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
    
}
