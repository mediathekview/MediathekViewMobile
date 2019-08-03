import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/widgets/videolist/video_widget.dart';
import 'package:logging/logging.dart';
import 'package:quiver/collection.dart';

class VideoPreviewManager {
  final Logger logger = new Logger('VideoPreviewManager');
  EventChannel _eventChannel;
  MethodChannel _methodChannel;
  AppSharedState _appWideState;
  Stream<dynamic> _updateStream;
  StreamSubscription<dynamic> streamSubscription;

  //management inside of Manager, that it can update the correct widgets! -> simple solution
  //videoId -> VideoWidgetState
  Multimap<String, VideoWidgetState> _widgetsWaitingForPreview;
  Map<String, bool> requestedVideoPreview = new Map();

  VideoPreviewManager(BuildContext context) {
    _eventChannel = const EventChannel('com.mediathekview.mobile/videoEvent');
    _methodChannel = const MethodChannel('com.mediathekview.mobile/video');
    _appWideState = AppSharedStateContainer.of(context);
    _widgetsWaitingForPreview = new Multimap();

    var stream;
    try {
      stream = _getBroadcastStream();
      streamSubscription =
          stream.listen((raw) => _onPreviewReceived(raw), onError: (e) {
        logger.severe("Preview generation failed. Reason " + e.toString());
      }, onDone: () {
        logger.info("Preview event channel is done.");
      }, cancelOnError: false);

      if (streamSubscription.isPaused) {
        logger.info("IS PAUSED.");
      }
    } catch (MissingPluginException) {
      logger.info("Cannot generate preview. Missing Plugin Exception.");
      return;
    }
  }

  _onPreviewReceived(raw) {
    String videoId = raw['videoId'];

    Uint8List bytes = raw['image'];

    _createImage(bytes).then((image) {
      logger.fine("Flutter received preview for video: " + videoId);
      //add to global state
      _appWideState.addImagePreview(videoId, image);

      List<VideoWidgetState> widgetToUpdate =
          _widgetsWaitingForPreview[videoId];
      widgetToUpdate.forEach((widget) {
        if (widget.previewImage == null) {
          widget.previewImage = image;
          if (widget.mounted) widget.setState(() {});
        }
      });
    });
  }

  Stream<dynamic> _getBroadcastStream() {
    if (_updateStream == null) {
      _updateStream = _eventChannel.receiveBroadcastStream();
    }
    return _updateStream;
  }

  Future startPreviewGeneration(VideoWidgetState state, String videoId,
      {String url, String fileName}) async {
    _widgetsWaitingForPreview.add(videoId, state);
    generatePreview(videoId, url: url, fileName: fileName);
  }

  Future generatePreview(String videoId, {String url, String fileName}) async {
    if (_appWideState.videoListState.previewImages.containsKey(videoId)) {
      return;
    }

    if (requestedVideoPreview.containsKey(videoId)) {
      return;
    }

    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("videoId", () => videoId);

    if (url != null && url.isNotEmpty) {
      requestArguments.putIfAbsent("url", () => url);
    } else if (fileName != null && fileName.isNotEmpty) {
      requestArguments.putIfAbsent("fileName", () => fileName);
    } else {
      return;
    }

    requestedVideoPreview.putIfAbsent(videoId, () {
      return true;
    });

    try {
      await _methodChannel.invokeMethod(
          'videoPreviewPicture', requestArguments);
    } on PlatformException catch (e) {
      logger
          .severe("Starting Preview generation failed. Reason " + e.toString());
    } on MissingPluginException catch (e) {
      logger.severe("Video Preview cannot be generated. Missing Plugin.");
    }
  }

  Future<Image> _createImage(Uint8List pictureRaw) async {
    final Codec codec = await instantiateImageCodec(pictureRaw);
    final FrameInfo frameInfo = await codec.getNextFrame();
    int height = frameInfo.image.height;
    int width = frameInfo.image.width;

    return new Image.memory(pictureRaw,
        fit: BoxFit.cover, height: height.toDouble(), width: width.toDouble());
  }

  void disableListeningForPreview() {
    if (streamSubscription != null) {
      streamSubscription.cancel();
      streamSubscription = null;
    }
  }
}
