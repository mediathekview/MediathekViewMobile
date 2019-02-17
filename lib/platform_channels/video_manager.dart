import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/section/live_tv_section.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

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
      path = entity.filePath + "/" + entity.fileName;
    } else {
      path = video.url_video;
    }

    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => path);
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
}
