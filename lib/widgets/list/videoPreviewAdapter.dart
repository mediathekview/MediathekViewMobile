import 'package:flutter/material.dart';
import 'package:flutter_ws/manager/databaseManager.dart';
import 'package:flutter_ws/manager/downloadManager.dart';
import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/model/VideoEntity.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:flutter_ws/widgets/list/DownloadCardBody.dart';
import 'package:flutter_ws/widgets/videoWidget.dart';
import 'package:uuid/uuid.dart';

class VideoPreviewAdapter extends StatelessWidget {
  final Video video;
  final String videoId;
  final bool showLoadingIndicator;

  VideoPreviewAdapter(this.videoId, {this.video, this.showLoadingIndicator});

  @override
  Widget build(BuildContext context) {
    Uuid uuid = new Uuid();
    AppSharedState stateContainer = AppSharedStateContainer.of(context);

    Image previewImage;
    if (stateContainer.videoListState != null &&
        stateContainer.videoListState.previewImages
            .containsKey(videoId)) {
      print("Getting preview image from memory");
      previewImage =
      stateContainer.videoListState.previewImages[videoId];
    }

    VideoEntity videoEntity =
    stateContainer.appState.downloadedVideos[videoId];

    return new Column(key: new Key(uuid.v1()), children: <Widget>[

      new Container(
        key: new Key(uuid.v1()),
        padding: new EdgeInsets.only(top: 12.0, bottom: 12.0),
        child: videoEntity == null
            ? new VideoWidget(previewImage, videoId,
            videoUrl: video.url_video,showLoadingIndicator: showLoadingIndicator == null? true: showLoadingIndicator)
            : new VideoWidget(previewImage, videoId,
            mimeType: videoEntity.mimeType,
            fileName: videoEntity.fileName,
            filePath: videoEntity.filePath,
          showLoadingIndicator: showLoadingIndicator == null? true: showLoadingIndicator,
        ),
      )
    ]);
  }
}
