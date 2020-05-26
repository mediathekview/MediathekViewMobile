import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/util/timestamp_calculator.dart';
import 'package:flutter_ws/widgets/bars/playback_progress_bar.dart';
import 'package:flutter_ws/widgets/videolist/download/download_progress_bar.dart';
import 'package:flutter_ws/widgets/videolist/util/util.dart';
import 'package:flutter_ws/widgets/videolist/video_detail_screen.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'channel_thumbnail.dart';

class VideoWidget extends StatefulWidget {
  final Logger logger = new Logger('VideoWidget');
  AppSharedState appWideState;
  VideoEntity entity;
  Video video;
  String mimeType;
  String defaultImageAssetPath;
  Image previewImage;
  Size size;
  double presetAspectRatio;

  bool isDownloading;
  bool openDetailPage;

  VideoWidget(
    this.appWideState,
    this.video,
    this.isDownloading,
    this.openDetailPage, {
    this.previewImage,
    this.entity,
    this.mimeType,
    this.defaultImageAssetPath,
    this.size,
    this.presetAspectRatio,
  });

  @override
  VideoWidgetState createState() => new VideoWidgetState();
}

class VideoWidgetState extends State<VideoWidget> {
  String heroUuid;
  VideoProgressEntity videoProgressEntity;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    heroUuid = new Uuid().v1().toString();
    checkPlaybackProgress();
  }

  @override
  Widget build(BuildContext context) {
    widget.logger.fine("Rendering Image for " + widget.video.id);

    //Always fill full width & calc height accordingly
    double totalWidth =
        widget.size.width - 36.0; //Intendation: 28 left, 8 right
    double height = calculateImageHeight(
        widget.previewImage, totalWidth, widget.presetAspectRatio);

    Widget downloadProgressBar = new DownloadProgressBar(
        widget.video.id,
        widget.video.title,
        widget.appWideState.appState.downloadManager,
        false);

    Image placeholderImage = new Image.asset(
        'assets/img/' + widget.defaultImageAssetPath,
        width: totalWidth,
        height: height,
        alignment: Alignment.center,
        gaplessPlayback: true);

    Hero previewImage;
    if (widget.previewImage != null) {
      previewImage = Hero(tag: heroUuid, child: widget.previewImage);
    } else {
      previewImage = Hero(tag: heroUuid, child: placeholderImage);
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
                child: previewImage,
              ),
              new AnimatedOpacity(
                opacity: widget.previewImage != null ? 1.0 : 0.0,
                duration: new Duration(milliseconds: 750),
                curve: Curves.easeInOut,
                child: widget.previewImage,
              ),
              //Overlay Banner
              new Positioned(
                bottom: 0,
                left: 0.0,
                right: 0.0,
                child: new Opacity(
                  opacity: 0.7,
                  child: getBottomBar(
                      context,
                      videoProgressEntity,
                      widget.video.id,
                      widget.video.duration.toString(),
                      widget.video.title,
                      widget.video.topic,
                      widget.defaultImageAssetPath),
                ),
              ),
              new Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  child: downloadProgressBar)
            ],
          ),
        ),
      ),
      onTap: () async {
        if (widget.openDetailPage) {
          widget.logger.info("Open detail page");
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) {
                    return VideoDetailScreen(
                      widget.appWideState,
                      widget.previewImage != null
                          ? widget.previewImage
                          : placeholderImage,
                      widget.video,
                      widget.entity,
                      widget.isDownloading,
                      widget.entity != null,
                      heroUuid,
                    );
                  },
                  fullscreenDialog: true));
        } else {
          // play video
          if (mounted) {
            Util.playVideoHandler(context, widget.appWideState, widget.entity,
                    widget.video, videoProgressEntity)
                .then((value) {
              // setting state after the video player popped the Navigator context
              // this reloads the video progress entity to show the playback progress
              checkPlaybackProgress();
            });
          }
        }
      },
    );
  }

  static double calculateImageHeight(
      Image image, double totalWidth, double presetAspectRatio) {
    if (image != null && presetAspectRatio != null) {
      return totalWidth / presetAspectRatio;
    } else if (image == null && presetAspectRatio != null) {
      return totalWidth / presetAspectRatio;
    } else if (image != null) {
      double originalWidth = image.width;
      double originalHeight = image.height;
      double aspectRatioVideo = originalWidth / originalHeight;

      //calc height
      double shrinkFactor = totalWidth / originalWidth;
      double height = originalHeight * shrinkFactor;
      return height;
    } else {
      return totalWidth / 16 * 9; //divide by aspect ratio
    }
  }

  Container getBottomBar(
      BuildContext context,
      VideoProgressEntity playbackProgress,
      String id,
      String duration,
      String title,
      String topic,
      String assetPath) {
    return new Container(
      color: Colors.grey[800],
      child: new Column(
        children: <Widget>[
          playbackProgress != null
              ? PlaybackProgressBar(
                  playbackProgress.progress, int.tryParse(duration), false)
              : new Container(),
          getVideoMetaInformationListTile(
              context, duration, title, topic, assetPath),
        ],
      ),
    );
  }

  ListTile getVideoMetaInformationListTile(BuildContext context,
      String duration, String title, String topic, String assetPath) {
    return new ListTile(
      trailing: new Text(
        duration != null ? Calculator.calculateDuration(duration) : "",
        style: videoMetadataTextStyle.copyWith(color: Colors.white),
      ),
      leading: assetPath.isNotEmpty
          ? new ChannelThumbnail(assetPath, true)
          : new Container(),
      title: new Text(
        title,
        style:
            Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
      ),
      subtitle: new Text(
        topic != null ? topic : "",
        style: Theme.of(context).textTheme.title.copyWith(color: Colors.white),
      ),
    );
  }

  void checkPlaybackProgress() async {
    widget.appWideState.appState.databaseManager
        .getVideoProgressEntity(widget.video.id)
        .then((entity) {
      widget.logger.info("Video has playback progress: " + widget.video.title);
      videoProgressEntity = entity;
      if (mounted) {
        setState(() {});
      }
    });
  }
}
