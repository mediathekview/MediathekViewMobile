// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/manager/nativeVideoManager.dart';
import 'package:flutter_ws/manager/videoPreviewManager.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

class VideoWidget extends StatefulWidget {
  String videoId;
  String videoUrl;
  String fileName;
  String filePath;
  String mimeType;
  Image previewImage;
  bool showLoadingIndicator;

  VideoWidget(this.previewImage, this.videoId,
      {this.videoUrl,
      this.mimeType,
      this.fileName,
      this.filePath,
      this.showLoadingIndicator});

  @override
  VideoWidgetState createState() => new VideoWidgetState(previewImage);
}

class VideoWidgetState extends State<VideoWidget> {
  bool initialized = false;
  VoidCallback listenerImage;
  VoidCallback listenerVideo;
  AppSharedState appWideState;
  Image previewImage;

  VideoWidgetState(Image image){previewImage = image;}


  @override
  Widget build(BuildContext context) {

    appWideState = AppSharedStateContainer.of(context);

    if (previewImage == null) {
      VideoPreviewManager previewController = appWideState.appState.videoPreviewManager;
      //Manager will update state of this widget!
      previewController.startPreviewGeneration(this, widget.videoId, widget.videoUrl, widget.fileName);
    }

    double width;
    double height;

    if (previewImage != null) {
      width = previewImage.width;
      height = previewImage.height;
    } else {
      final size = MediaQuery.of(context).size;
      width = size.width;
      height = size.height;
    }

//    child = new Stack(children: <Widget>[
//      new Container(
//        width: width, //Wrong when image is loaded
//        child: new Stack(
//          fit: StackFit.passthrough,
//          children: <Widget>[
//            new Container(color: const Color(0xffffbf00)),
//            widget.showLoadingIndicator == true
//                ? new Container(
//                    constraints: BoxConstraints.tight(Size.square(25.0)),
//                    alignment: FractionalOffset.topLeft,
//                    child: widget.previewImage == null
//                        ? const CircularProgressIndicator(
//                            valueColor: const AlwaysStoppedAnimation<Color>(
//                                Colors.white),
//                            strokeWidth: 4.0,
//                          )
//                        : new Container(),
//                  )
//                : new Container(),
//          ],
//        ),
//      ),
//      new AnimatedOpacity(
//        opacity: widget.previewImage != null ? 1.0 : 0.0,
//        duration: new Duration(milliseconds: 1500),
//        child: new Center(child: widget.previewImage),
//      ),
//    ]);

    return new GestureDetector(
      child: new AspectRatio(
        aspectRatio: width > height ? width / height : height / width,
        child: new Container(
          width: width,
          child: new Stack(
              alignment: Alignment.center,
              fit: StackFit.passthrough,
              children: <Widget>[
                new Container(color: const Color(0xffffbf00)),
                widget.showLoadingIndicator == true
                    ? new Container(
                        constraints: BoxConstraints.tight(Size.square(25.0)),
                        alignment: FractionalOffset.topLeft,
                        child: widget.previewImage == null
                            ? const CircularProgressIndicator(
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                                strokeWidth: 4.0,
                              )
                            : new Container(),
                      )
                    : new Container(),
                new AnimatedOpacity(
                  opacity: previewImage != null ? 1.0 : 0.0,
                  duration: new Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  child: new Center(child: previewImage),
                ),
                new Container(
                    width: width,
                    alignment: FractionalOffset.center,
                    child: new Opacity(
                      opacity: 0.7,
                      child: new Icon(Icons.play_circle_outline,
                          size: 100.0, color: Colors.white),
                    )),
              ]),
        ),
      ),
      onTap: () {
        print("Opening video player");

        NativeVideoPlayer nativeVideoPlayer = new NativeVideoPlayer();
        widget.filePath != null
            ? nativeVideoPlayer.playVideo(widget.filePath,
                mimeType: widget.mimeType)
            : nativeVideoPlayer.playVideo(widget.videoUrl);
      },
    );
  }
}
