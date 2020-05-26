import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/video.dart';
import 'package:flutter_ws/widgets/videolist/video_widget.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

class VideoPreviewAdapter extends StatefulWidget {
  final Logger logger = new Logger('VideoPreviewAdapter');
  final Video video;
  final String defaultImageAssetPath;
  bool isVisible;
  bool openDetailPage;
  // if width not set, set to full width
  Size size;
  // force to this specific aspect ratio
  double presetAspectRatio;

  VideoPreviewAdapter(
    // always hand over video. Download section needs to convert to video.
    // Needs to made uniform to be easier
    this.video,
    this.isVisible,
    this.openDetailPage, {
    this.defaultImageAssetPath,
    this.size,
    this.presetAspectRatio,
  });

  @override
  _VideoPreviewAdapterState createState() => _VideoPreviewAdapterState();
}

class _VideoPreviewAdapterState extends State<VideoPreviewAdapter> {
  Image previewImage;
  VideoEntity videoEntity;
  VideoProgressEntity videoProgressEntity;
  AppSharedState appWideState;
  // Is used to determine whether to generate a preview or not
  // Updated as soon as the database manager determined that the video has been downloaded
  // this is to avoid to always request a preview from a web uri
  bool alreadyCheckedForVideoEntity = false;
  bool isCurrentlyDownloading = false;

  @override
  Widget build(BuildContext context) {
    Uuid uuid = new Uuid();
    appWideState = AppSharedStateContainer.of(context);

    if (!widget.isVisible) {
      return new Container();
    }

    if (appWideState.videoListState != null &&
        appWideState.videoListState.previewImages
            .containsKey(widget.video.id)) {
      widget.logger.fine("Getting preview image from memory");
      previewImage = appWideState.videoListState.previewImages[widget.video.id];
    }

    // check if video is currently downloading
    appWideState.appState.downloadManager
        .isCurrentlyDownloading(widget.video.id)
        .then((value) {
      if (value != null) {
        if (!isCurrentlyDownloading) {
          widget.logger.info("Video is downloading:  " + widget.video.title);
          isCurrentlyDownloading = true;
          if (mounted) {
            setState(() {});
          }
        }
      }
    });

    // check if the video is downloaded
    if (!alreadyCheckedForVideoEntity) {
      appWideState.appState.databaseManager
          .getDownloadedVideo(widget.video.id)
          .then((entity) {
        alreadyCheckedForVideoEntity = true;
        if (entity != null) {
          widget.logger.info("Video is downloaded:" + entity.title);
          videoEntity = entity;
        }
        if (mounted) {
          setState(() {});
        }
      });
    }

    // request preview (wait until checked if video is already downloaded)
    if (alreadyCheckedForVideoEntity && previewImage == null) {
      if (videoEntity == null && widget.video == null) {
        return new Container();
      }

      String url =
          VideoUtil.getVideoPath(appWideState, videoEntity, widget.video);

      appWideState.appState.videoPreviewManager
          .startPreviewGeneration(widget.video.id, widget.video.title, url)
          .then((Image image) {
        if (image == null) {
          return;
        }
        widget.logger.info("Preview received for video: " + widget.video.title);
        previewImage = image;
        if (mounted) {
          setState(() {});
        }
      });
    }

    if (widget.size == null) {
      widget.size = MediaQuery.of(context).size;
    }

    return new Column(
      key: new Key(uuid.v1()),
      children: <Widget>[
        new Container(
          key: new Key(uuid.v1()),
          child: new VideoWidget(
            appWideState,
            widget.video,
            isCurrentlyDownloading,
            widget.openDetailPage,
            entity: videoEntity != null ? videoEntity : null,
            previewImage: previewImage,
            defaultImageAssetPath: widget.defaultImageAssetPath,
            size: widget.size,
            presetAspectRatio: widget.presetAspectRatio,
          ),
        )
      ],
    );
  }
}
