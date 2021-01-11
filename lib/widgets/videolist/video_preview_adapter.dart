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
  bool previewNotDownloadedVideos;
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
    this.previewNotDownloadedVideos,
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
      widget.logger
          .fine("Getting preview image from memory for: " + widget.video.title);
      previewImage = appWideState.videoListState.previewImages[widget.video.id];
    }

    if (previewImage != null) {
      widget.logger.info("Preview for video is set: " + widget.video.title);
    } else {
      widget.logger.info("Preview for video is NOT set: " + widget.video.title);
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

    if (previewImage == null) {
      appWideState.appState.videoPreviewManager
          .getImagePreview(widget.video.id)
          .then((image) {
        if (image != null) {
          widget.logger
              .info("Thumbnail found  for video: " + widget.video.title);
          previewImage = image;
          if (mounted) {
            setState(() {});
          }
          return;
        }
        // request preview
        requestPreview(context);
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
            previewImage: previewImage,
            defaultImageAssetPath: widget.defaultImageAssetPath,
            size: widget.size,
            presetAspectRatio: widget.presetAspectRatio,
          ),
        )
      ],
    );
  }

  void requestPreview(BuildContext context) {
    appWideState.appState.databaseManager
        .getDownloadedVideo(widget.video.id)
        .then((entity) {
      if (entity == null && !widget.previewNotDownloadedVideos) {
        return;
      }
      requestThumbnailPicture(context, entity, widget.video);
    });
  }

  void requestThumbnailPicture(
      BuildContext context, VideoEntity entity, Video video) {
    String url = VideoUtil.getVideoPath(appWideState, entity, video);

    appWideState.appState.videoPreviewManager.startPreviewGeneration(
        context,
        widget.video.id,
        widget.video.title,
        url,
        triggerStateReloadOnPreviewReceived);
  }

  void triggerStateReloadOnPreviewReceived(String filepath) {
    if (filepath == null) {
      return;
    }
    widget.logger.info("Preview received for video: " + widget.video.title);
    // get preview from file
    appWideState.appState.videoPreviewManager
        .getImagePreview(widget.video.id)
        .then((image) {
      previewImage = image;
      if (mounted) {
        setState(() {});
      }
    });
  }
}
