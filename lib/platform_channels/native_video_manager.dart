import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/model/video_entity.dart';
import 'package:flutter_ws/section/live_tv_section.dart';
import 'package:meta/meta.dart';

class NativeVideoPlayer {
  static NativeVideoPlayer _instance;
  MethodChannel _methodChannel;

  factory NativeVideoPlayer() {
    if (_instance == null) {
      final MethodChannel channel =
          const MethodChannel('samples.flutter.io/video');

      _instance = new NativeVideoPlayer.private(channel);
    }
    return _instance;
  }

  @visibleForTesting
  NativeVideoPlayer.private(this._methodChannel);

  Future<void> playVideo(
      {Video video, VideoEntity entity, String mimeType}) async {
    String path;
    if (entity != null) {
      path = entity.filePath;
    } else {
      path = video.url_video;
    }

    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => path);
//      requestArguments.putIfAbsent("mimeType", () => mimeType);

      await _methodChannel.invokeMethod('playVideo', requestArguments);
    } on PlatformException catch (e) {
      //TODO add exception handling
    }
  }

  Future<void> playLiveStream(Channel channel) async {
    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => channel.url);
      await _methodChannel.invokeMethod('playVideo', requestArguments);
//      Firebase.logStreamChannel(channel);
    } on PlatformException catch (e) {
      //TODO add exception handling
      print("Platform exception accoured : " + e.toString());
    }
  }

  Future<bool> deleteVideo(String fileName) async {
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("fileName", () => fileName);
    print("Deleting video with name " + fileName + " from local storage");

    try {
      await _methodChannel.invokeMethod('deleteVideo', requestArguments);
    } on PlatformException catch (e) {
      //TODO add exception handling

      return false;
    }
    return true;
  }
}
