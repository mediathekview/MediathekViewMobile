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
  final String videoId;
  final Video video;
  final VideoProgressEntity videoProgressEntity;
  final String defaultImageAssetPath;
  bool isVisible;
  bool generatePreview;
  VideoEntity videoEntity;
  // if width not set, set to full width
  Size size;
  // force to this specific aspect ratio
  double presetAspectRatio;

  VideoPreviewAdapter(
    this.isVisible,
    this.generatePreview,
    this.videoId, {
    this.video,
    this.videoEntity,
    this.defaultImageAssetPath,
    this.size,
    this.presetAspectRatio,
    this.videoProgressEntity,
  });

  @override
  _VideoPreviewAdapterState createState() => _VideoPreviewAdapterState();
}

class _VideoPreviewAdapterState extends State<VideoPreviewAdapter> {
  Image previewImage;
  // Is used to determine whether to generate a preview or not
  // Updated as soon as the database manager determined that the video has been downloaded
  // this is to avoid to always request a preview from a web uri
  bool alreadyCheckedForVideoEntity = false;

  @override
  Widget build(BuildContext context) {
    Uuid uuid = new Uuid();
    AppSharedState appWideState = AppSharedStateContainer.of(context);

    if (!widget.isVisible) {
      return new Container();
    }

    if (appWideState.videoListState != null &&
        appWideState.videoListState.previewImages.containsKey(widget.videoId)) {
      widget.logger.fine("Getting preview image from memory");
      previewImage = appWideState.videoListState.previewImages[widget.videoId];
    }

    // check if the video is downloaded
    if (widget.videoEntity == null && !alreadyCheckedForVideoEntity) {
      appWideState.appState.databaseManager
          .getDownloadedVideo(widget.videoId)
          .then((entity) {
        alreadyCheckedForVideoEntity = true;
        if (entity != null) {
          widget.logger.fine("Retrieved Downloaded Video with name " +
              entity.title +
              " and filename: " +
              entity.fileName);
          widget.videoEntity = entity;
        }
        if (mounted) {
          setState(() {});
        }
      });
    }

    // request preview (wait until checked if video is already downloaded)
    if (widget.generatePreview &&
        alreadyCheckedForVideoEntity &&
        previewImage == null) {
      if (widget.videoEntity == null && widget.video == null) {
        return new Container();
      }

      String url = VideoUtil.getVideoPath(
          appWideState, widget.videoEntity, widget.video);

      appWideState.appState.videoPreviewManager
          .startPreviewGeneration(widget.videoId, url)
          .then((Image image) {
        if (image == null) {
          return;
        }
        widget.logger.info("Preview received");
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
            videoId: widget.videoId,
            previewImage: previewImage,
            entity: widget.videoEntity != null ? widget.videoEntity : null,
            video: widget.video != null ? widget.video : null,
            videoProgressEntity: widget.videoProgressEntity,
            defaultImageAssetPath: widget.defaultImageAssetPath,
            size: widget.size,
            presetAspectRatio: widget.presetAspectRatio,
          ),
        )
      ],
    );
  }
}
