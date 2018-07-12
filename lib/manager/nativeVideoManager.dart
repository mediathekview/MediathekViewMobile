import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ws/analytics/firebaseAnalytics.dart';
import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/model/VideoEntity.dart';
import 'package:flutter_ws/section/liveTVSection.dart';
import 'package:flutter_ws/util/osChecker.dart';
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
      Firebase.logStreamDownloadedVideo(entity);
    } else {
      path = video.url_video;
      Firebase.logStreamVideo(video);
    }

    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => path);
//      requestArguments.putIfAbsent("mimeType", () => mimeType);

      await _methodChannel.invokeMethod('playVideo', requestArguments);
    } on PlatformException catch (e) {
      OsChecker.getTargetPlatform().then((platform) {
        Firebase.logPlatformChannelException(
            'playVideo', e.toString(), platform.toString());
      });
    }
  }

  Future<void> playLiveStream(Channel channel) async {
    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => channel.url);
      await _methodChannel.invokeMethod('playVideo', requestArguments);
      Firebase.logStreamChannel(channel);
    } on PlatformException catch (e) {
      OsChecker.getTargetPlatform().then((platform) {
        Firebase.logPlatformChannelException(
            'playLivestreamChannel', e.toString(), platform.toString());
      });
    }
  }

  Future<bool> deleteVideo(String fileName) async {
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("fileName", () => fileName);
    print("Deleting video with name " + fileName + " from local storage");

    try {
      await _methodChannel.invokeMethod('deleteVideo', requestArguments);
    } on PlatformException catch (e) {
      OsChecker.getTargetPlatform().then((platform) {
        Firebase.logPlatformChannelException(
            'deleteVideo', e.toString(), platform.toString());
      });

      return false;
    }
    return true;
  }
}
