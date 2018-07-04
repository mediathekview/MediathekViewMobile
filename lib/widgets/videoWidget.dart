// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE fi


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/manager/nativeVideoManager.dart';
import 'package:flutter_ws/manager/videoPreviewManager.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';

class VideoWidget extends StatefulWidget {
  String videoId;
  String videoUrl;
  String fileName;
  String filePath;
  String mimeType;
  String defaultImageAssetPath;
  Image previewImage;
  bool showLoadingIndicator;

  VideoWidget(this.previewImage, this.videoId,
      {this.videoUrl,
      this.mimeType,
      this.defaultImageAssetPath,
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

  VideoWidgetState(Image image) {
    previewImage = image;
  }

  @override
  Widget build(BuildContext context) {
    appWideState = AppSharedStateContainer.of(context);

    if (previewImage == null) {
      VideoPreviewManager previewController =
          appWideState.appState.videoPreviewManager;
      //Manager will update state of this widget!
      previewController.startPreviewGeneration(
          this, widget.videoId, widget.videoUrl, widget.fileName);
    }

    final size = MediaQuery.of(context).size;
    //Always fill full width & calc height accordingly

    double totalWidth = size.width - 36.0; //Intendation: 28 left, 8 right
    double screenAspectRatio = size.width > size.height ? size.width / size.height : size.height / size.width;
    print("Aspect ratio: " + screenAspectRatio.toString());
    double height;

    if (previewImage != null) {
      double originalWidth = previewImage.width;
      double originalHeight = previewImage.height;
      double aspectRatioVideo = originalWidth / originalHeight;

      //calc height
      double shrinkFactor = totalWidth / originalWidth;
      height = originalHeight * shrinkFactor;
      print("Aspect ratio video: "  + aspectRatioVideo.toString() + " Shrink factor: " +
          shrinkFactor.toString() +
          " Orig height: " +
          originalHeight.toString() +
          " New height: " +
          height.toString());
    } else {
//      final size = MediaQuery.of(context).size;
//      width = size.width;
      height = totalWidth / 16 * 9; //divide by aspect ratio
    }

    return new GestureDetector(
      child: new AspectRatio(
        aspectRatio:
            totalWidth > height ? totalWidth / height : height / totalWidth,
        child: new Container(
          width: totalWidth,
          child: new Stack(
            alignment: Alignment.center,
            fit: StackFit.passthrough,
            children: <Widget>[
              new AnimatedOpacity(
                opacity: previewImage == null ? 1.0 : 0.0,
                duration: new Duration(milliseconds: 750),
                curve: Curves.easeInOut,
//                  child: new Center(child: previewImage),
                child: widget.defaultImageAssetPath != null
                    ? new Image.asset(
                        'assets/img/' + widget.defaultImageAssetPath,
//                        fit: BoxFit.cover,
                        width: totalWidth,
                        height: height,
                        alignment: Alignment.center,
                        gaplessPlayback: true)
                    : new Container(color: const Color(0xffffbf00)),
              ),
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
                duration: new Duration(milliseconds: 750),
                curve: Curves.easeInOut,
//                  child: new Center(child: previewImage),
                child: previewImage,
              ),
              new Container(
                width: totalWidth,
                alignment: FractionalOffset.center,
                child: new Opacity(
                  opacity: 0.7,
                  child: new Icon(Icons.play_circle_outline,
                      size: 100.0, color: previewImage == null ? Colors.grey[500]: Colors.white),
                ),
              ),
            ],
          ),
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
