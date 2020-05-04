import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/video_player/flutter_video_player.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'download_card_body.dart';

class VideoWidget extends StatefulWidget {
  final Logger logger = new Logger('VideoWidget');
  String videoId;
  VideoEntity entity;
  Video video;
  VideoProgressEntity videoProgressEntity;
  String mimeType;
  String defaultImageAssetPath;
  Image previewImage;
  Size size;
  double presetAspectRatio;

  VideoWidget(
      {this.videoId,
      this.previewImage,
      this.entity,
      this.video,
      this.mimeType,
      this.defaultImageAssetPath,
      this.size,
      this.presetAspectRatio,
      this.videoProgressEntity});

  @override
  VideoWidgetState createState() => new VideoWidgetState();
}

class VideoWidgetState extends State<VideoWidget> {
  AppSharedState appWideState;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    appWideState = AppSharedStateContainer.of(context);
    widget.logger.fine("Rendering Image for " + widget.videoId);

    //Always fill full width & calc height accordingly
    double totalWidth =
        widget.size.width - 36.0; //Intendation: 28 left, 8 right
    double height;

    if (widget.previewImage != null && widget.presetAspectRatio != null) {
      height = totalWidth / widget.presetAspectRatio;
    } else if (widget.previewImage == null &&
        widget.presetAspectRatio != null) {
      height = totalWidth / widget.presetAspectRatio;
    } else if (widget.previewImage != null) {
      double originalWidth = widget.previewImage.width;
      double originalHeight = widget.previewImage.height;
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
                  opacity: widget.previewImage == null ? 1.0 : 0.0,
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
                new AnimatedOpacity(
                  opacity: widget.previewImage != null ? 1.0 : 0.0,
                  duration: new Duration(milliseconds: 750),
                  curve: Curves.easeInOut,
                  child: widget.previewImage,
                ),
                new Container(
                  width: totalWidth,
                  alignment: FractionalOffset.center,
                  child: new Opacity(
                    opacity: 0.7,
                    child: new Icon(Icons.play_circle_outline,
                        size: 100.0,
                        color: widget.previewImage == null
                            ? Colors.grey[500]
                            : Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () async {
          // only check for internet connection when video is not downloaded
          if (widget.entity == null) {
            var connectivityResult = await (Connectivity().checkConnectivity());
            if (connectivityResult == ConnectivityResult.none) {
              // I am connected to a mobile network.
              SnackbarActions.showError(context, ERROR_MSG_NO_INTERNET);
              return;
            }
          }

          //  video has been removed from the Mediathek already
          if (widget.entity == null &&
              widget.video != null &&
              widget.video.url_video != null) {
            final response = await http.head(widget.video.url_video);

            if (response.statusCode >= 300) {
              widget.logger.info("Url is not accessible: " +
                  widget.video.url_video.toString() +
                  ". Status code: " +
                  response.statusCode.toString() +
                  ". Reason: " +
                  response.reasonPhrase);

              SnackbarActions.showError(context, ERROR_MSG_NOT_AVAILABLE);
              return;
            }
          }

          // push full screen route
          await Navigator.of(context).push(new MaterialPageRoute(
              builder: (BuildContext context) {
                return new FlutterVideoPlayer(context, appWideState,
                    widget.video, widget.entity, widget.videoProgressEntity);
              },
              settings: RouteSettings(name: "VideoPlayer"),
              fullscreenDialog: false));
          return;
        });
  }
}
