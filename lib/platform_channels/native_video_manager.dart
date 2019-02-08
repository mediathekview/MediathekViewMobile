import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/model/video_entity.dart';
import 'package:flutter_ws/section/live_tv_section.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

class NativeVideoPlayer {
  final Logger logger = new Logger('NativeVideoPlayer');
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
      logger.severe("Platform exception accoured : " + e.toString());
    }
  }

  Future<void> playLiveStream(Channel channel) async {
    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => channel.url);
      await _methodChannel.invokeMethod('playVideo', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Platform exception accoured : " + e.toString());
    }
  }

  Future<bool> deleteVideo(String fileName) async {
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("fileName", () => fileName);
    logger.fine("Deleting video with name " + fileName + " from local storage");

    try {
      await _methodChannel.invokeMethod('deleteVideo', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Platform exception accoured : " + e.toString());
      return false;
    }
    return true;
  }
}
