import 'dart:async';
import 'package:flutter/services.dart';
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

  Future<void> playVideo(String filePath, {String mimeType}) async {
    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => filePath);
      requestArguments.putIfAbsent("mimeType", () => mimeType);

      await _methodChannel.invokeMethod('playVideo', requestArguments);
    } on PlatformException catch (e) {
      print("Playing video with path " +
          filePath +
          " failed. Reason " +
          e.toString());
    }
  }

  Future<bool> deleteVideo(String fileName) async {
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("fileName", () => fileName);
    print("Deleting video with name " + fileName + " from local storage");

    await _methodChannel.invokeMethod('deleteVideo', requestArguments);

    return true;
  }
}
