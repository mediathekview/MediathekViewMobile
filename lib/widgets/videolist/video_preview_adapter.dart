import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/widgets/videolist/video_widget.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

class VideoPreviewAdapter extends StatefulWidget {
  final Logger logger = new Logger('VideoWidget');
  final String videoId;
  final Video video;
  final VideoProgressEntity videoProgressEntity;
  final String defaultImageAssetPath;
  final bool showLoadingIndicator;
  bool isVisible;
  // if width not set, set to full width
  Size size;
  // force to this specific aspect ratio
  double presetAspectRatio;

  VideoPreviewAdapter(this.isVisible, this.videoId,
      {this.video,
      this.showLoadingIndicator,
      this.defaultImageAssetPath,
      this.size,
      this.presetAspectRatio,
      this.videoProgressEntity});

  @override
  _VideoPreviewAdapterState createState() => _VideoPreviewAdapterState();
}

class _VideoPreviewAdapterState extends State<VideoPreviewAdapter> {
  // fetch from db if downloaded and update state
  VideoEntity videoEntity;

  @override
  Widget build(BuildContext context) {
    Uuid uuid = new Uuid();
    AppSharedState stateContainer = AppSharedStateContainer.of(context);

    if (!widget.isVisible) {
      return new Container();
    }

    Image previewImage;
    if (stateContainer.videoListState != null &&
        stateContainer.videoListState.previewImages
            .containsKey(widget.videoId)) {
      widget.logger.fine("Getting preview image from memory");
      previewImage =
          stateContainer.videoListState.previewImages[widget.videoId];
    }

    if (videoEntity == null)
      stateContainer.appState.databaseManager
          .getDownloadedVideo(widget.videoId)
          .then((entity) {
        if (entity != null) {
          widget.logger.fine("Retrieved Downloaded Video with name " +
              entity.title +
              " and filename: " +
              entity.fileName);
          if (mounted) {
            setState(() {
              videoEntity = entity;
            });
          }
        }
      });

    if (widget.size == null) {
      widget.size = MediaQuery.of(context).size;
    }

    return new Column(
      key: new Key(uuid.v1()),
      children: <Widget>[
        new Container(
          key: new Key(uuid.v1()),
          //padding: new EdgeInsets.only(top: 12.0, bottom: 12.0),
          child: videoEntity == null
              ? new VideoWidget(
                  videoId: widget.videoId,
                  previewImage: previewImage,
                  video: widget.video,
                  videoProgressEntity: widget.videoProgressEntity,
                  defaultImageAssetPath: widget.defaultImageAssetPath,
                  size: widget.size,
                  presetAspectRatio: widget.presetAspectRatio,
                  showLoadingIndicator: widget.showLoadingIndicator == null
                      ? true
                      : widget.showLoadingIndicator)
              : new VideoWidget(
                  videoId: widget.videoId,
                  previewImage: previewImage,
                  entity: videoEntity,
                  videoProgressEntity: widget.videoProgressEntity,
                  defaultImageAssetPath: widget.defaultImageAssetPath,
                  size: widget.size,
                  presetAspectRatio: widget.presetAspectRatio,
                  showLoadingIndicator: widget.showLoadingIndicator == null
                      ? true
                      : widget.showLoadingIndicator,
                ),
        )
      ],
    );
  }
}
