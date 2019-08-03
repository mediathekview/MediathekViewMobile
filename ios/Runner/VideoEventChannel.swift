//
//  VideoEventChannel.swift
//  Runner
//
//  Created by Foehr, Daniel on 18.07.19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Foundation


class VideoStreamHandler : FlutterAppDelegate, FlutterStreamHandler{
    private var eventSink: FlutterEventSink?
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink

        NSLog("iOs listening to video event channel")
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        NSLog("iOs cancle listening to video event channel")
        eventSink = nil
        return nil
    }
    
    public func onPreviewReceived(returnArgs: [String : Any]){
        if (eventSink == nil) {
            NSLog("iOs cannot send video preview because event sink is nil")
            return;
        }
        eventSink!(returnArgs)
    }
    
}
