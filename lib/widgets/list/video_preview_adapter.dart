import 'package:flutter/material.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/model/video_entity.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:flutter_ws/widgets/video_widget.dart';
import 'package:uuid/uuid.dart';

class VideoPreviewAdapter extends StatelessWidget {
  final String videoId;
  final Video video;
  final String defaultImageAssetPath;
  final bool showLoadingIndicator;

  VideoPreviewAdapter(this.videoId,
      {this.video, this.showLoadingIndicator, this.defaultImageAssetPath});

  @override
  Widget build(BuildContext context) {
    Uuid uuid = new Uuid();
    AppSharedState stateContainer = AppSharedStateContainer.of(context);

    Image previewImage;
    if (stateContainer.videoListState != null &&
        stateContainer.videoListState.previewImages.containsKey(videoId)) {
      print("Getting preview image from memory");
      previewImage = stateContainer.videoListState.previewImages[videoId];
    }

    VideoEntity videoEntity = stateContainer.appState.downloadedVideos[videoId];

    return new Column(key: new Key(uuid.v1()), children: <Widget>[
      new Container(
        key: new Key(uuid.v1()),
        padding: new EdgeInsets.only(top: 12.0, bottom: 12.0),
        child: videoEntity == null
            ? new VideoWidget(
                videoId: videoId,
                previewImage: previewImage,
                video: video,
                defaultImageAssetPath: defaultImageAssetPath,
                showLoadingIndicator:
                    showLoadingIndicator == null ? true : showLoadingIndicator)
            : new VideoWidget(
                videoId: videoId,
                previewImage: previewImage,
                entity: videoEntity,
                defaultImageAssetPath: defaultImageAssetPath,
                showLoadingIndicator:
                    showLoadingIndicator == null ? true : showLoadingIndicator,
              ),
      )
    ]);
  }
}
