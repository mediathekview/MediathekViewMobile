import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/video_manager.dart';
import 'package:flutter_ws/platform_channels/video_preview_manager.dart';
import 'package:logging/logging.dart';

class VideoWidget extends StatefulWidget {
  final Logger logger = new Logger('VideoWidget');
  String videoId;
  VideoEntity entity;
  Video video;
  VideoProgressEntity videoProgressEntity;
  String mimeType;
  String defaultImageAssetPath;
  Image previewImage;
  bool showLoadingIndicator;
  Size size;
  double presetAspectRatio;

  VideoWidget(
      {this.videoId,
      this.previewImage,
      this.entity,
      this.video,
      this.mimeType,
      this.defaultImageAssetPath,
      this.showLoadingIndicator,
      this.size,
      this.presetAspectRatio,
      this.videoProgressEntity});

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
    widget.logger.fine("Rendering Image for " + widget.videoId);

    if (previewImage == null) {
      widget.logger.info("Image for video " + widget.videoId + " is null");
      VideoPreviewManager previewController =
          appWideState.appState.videoPreviewManager;
      //Manager will update state of this widget!
      if (widget.entity == null && widget.video == null) {
        return new Container();
      }
      if (widget.entity == null) {
        previewController.startPreviewGeneration(this, widget.videoId,
            url: widget.video.url_video);
      } else {
        previewController.startPreviewGeneration(this, widget.videoId,
            fileName: widget.entity.fileName);
      }
    }

    //Always fill full width & calc height accordingly
    double totalWidth =
        widget.size.width - 36.0; //Intendation: 28 left, 8 right
    double height;

    if (previewImage != null && widget.presetAspectRatio != null) {
      height = totalWidth / widget.presetAspectRatio;
    } else if (previewImage == null && widget.presetAspectRatio != null) {
      height = totalWidth / widget.presetAspectRatio;
    } else if (previewImage != null) {
      double originalWidth = previewImage.width;
      double originalHeight = previewImage.height;
      double aspectRatioVideo = originalWidth / originalHeight;

      //calc height
      double shrinkFactor = totalWidth / originalWidth;
      height = originalHeight * shrinkFactor;

      widget.logger.fine("Aspect ratio video: " +
          aspectRatioVideo.toString() +
          " Shrink factor: " +
          shrinkFactor.toString() +
          " Orig height: " +
          originalHeight.toString() +
          " New height: " +
          height.toString());
    } else {
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
                child: widget.defaultImageAssetPath != null
                    ? new Image.asset(
                        'assets/img/' + widget.defaultImageAssetPath,
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
                child: previewImage,
              ),
              new Container(
                width: totalWidth,
                alignment: FractionalOffset.center,
                child: new Opacity(
                  opacity: 0.7,
                  child: new Icon(Icons.play_circle_outline,
                      size: 100.0,
                      color: previewImage == null
                          ? Colors.grey[500]
                          : Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        widget.logger.fine("Opening video player");

        NativeVideoPlayer nativeVideoPlayer =
            new NativeVideoPlayer(appWideState.appState.databaseManager);
        widget.entity != null
            ? nativeVideoPlayer.playVideo(
                videoEntity: widget.entity,
                playbackProgress: widget.videoProgressEntity)
            : nativeVideoPlayer.playVideo(
                video: widget.video,
                playbackProgress: widget.videoProgressEntity);
      },
    );
  }
}
