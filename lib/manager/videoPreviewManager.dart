import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:flutter_ws/widgets/videoWidget.dart';

class VideoPreviewManager {
  EventChannel _eventChannel;
  MethodChannel _methodChannel;
  AppSharedState _appWideState;
  Stream<dynamic> _updateStream;
  StreamSubscription<dynamic> streamSubscription;

  //management inside of Manager, that it can update the correct widgets! -> simple solution
  Map<String, VideoWidgetState> _widgetsWaitingForPreview;

  VideoPreviewManager(BuildContext context){
    _eventChannel = const EventChannel('samples.flutter.io/videoEvent');
    _methodChannel = const MethodChannel('samples.flutter.io/video');
    _appWideState = AppSharedStateContainer.of(context);
    _widgetsWaitingForPreview = new Map();
    _getBroadcastStream().listen((raw) => _onPreviewReceived(raw), onError: (e) {
      print("Preview generation failed. Reason " + e.toString());
    },);
  }

  _onPreviewReceived(raw) {

    String videoId = raw['videoId'];

    Uint8List bytes = raw['image'];


    _createImage(bytes).then((image) {

      //add to global state
      _appWideState.addImagePreview(videoId, image);

      VideoWidgetState widgetToUpdate = _widgetsWaitingForPreview[videoId];

      if (widgetToUpdate != null) {
        print("Updating image preview for video: " + videoId);
        widgetToUpdate.previewImage = image;

        if (widgetToUpdate.mounted)
          widgetToUpdate.setState(() {
          });

        _widgetsWaitingForPreview.remove(videoId);
      }
      }
    );
  }



  Stream<dynamic> _getBroadcastStream() {
    if (_updateStream == null) {
      _updateStream = _eventChannel
          .receiveBroadcastStream();
    }
    return _updateStream;
  }


  Future startPreviewGeneration(VideoWidgetState state, String videoId, String url, String fileName) async {

    _widgetsWaitingForPreview.putIfAbsent(videoId, () => state);

    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("videoId", () => videoId);

    if (url != null)
      requestArguments.putIfAbsent("url", () => url);
    if (fileName != null)
      requestArguments.putIfAbsent("fileName", () => fileName);

    try {

       await _methodChannel.invokeMethod(
          'videoPreviewPicture', requestArguments);
    } on PlatformException catch (e) {
      print("Starting Preview generation failed. Reason " + e.toString());
      return;
    }
  }

  Future<Image> _createImage(Uint8List pictureRaw) async{
    final Codec codec = await instantiateImageCodec(pictureRaw);
    final FrameInfo frameInfo = await codec.getNextFrame();
    int height = frameInfo.image.height;
    int width = frameInfo.image.width;

    return new Image.memory(pictureRaw,
        height: height.toDouble(), width: width.toDouble());
  }

}