import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/util/timestamp_calculator.dart';
import 'package:flutter_ws/widgets/bars/download_progress_bar.dart';
import 'package:flutter_ws/widgets/bars/playback_progress_bar.dart';
import 'package:flutter_ws/widgets/videolist/channel_thumbnail.dart';
import 'package:flutter_ws/widgets/videolist/video_preview_adapter.dart';

class VideoListItemBuilder {
  // called when the user pressed on the remove button
  var onRemoveVideo;

  List<VideoEntity> videos = new List();
  Map<String, VideoProgressEntity> videosWithPlaybackProgress = new Map();

  bool showDownloadProgressBar;
  Map<String, DownloadTaskStatus> downloadStatus = new Map();
  Map<String, double> downloadProgress = new Map();

  VideoListItemBuilder.name(this.onRemoveVideo, this.videos,
      this.videosWithPlaybackProgress, this.showDownloadProgressBar,
      {this.downloadStatus, this.downloadProgress});

  Widget itemBuilder(BuildContext context, int index) {
    VideoEntity entity;
    entity = videos.elementAt(index);

    Widget downloadProgressBar = new Container();
    if (showDownloadProgressBar) {
      DownloadTaskStatus downloadTaskStatus = DownloadTaskStatus.running;
      if (downloadStatus[entity.id] != null) {
        downloadTaskStatus = downloadStatus[entity.id];
      }

      double progress = -1;
      if (downloadProgress[entity.id] != null &&
          downloadProgress[entity.id] > -1) {
        progress = downloadProgress[entity.id];
      }

      downloadProgressBar = new DownloadProgressBar(
          Video.fromMap(entity.toMap()), downloadTaskStatus, progress);
    }

    String assetPath = Channels.channelMap.entries.firstWhere((entry) {
      return entity.channel != null &&
              entity.channel.toUpperCase().contains(entry.key.toUpperCase()) ||
          entry.key.toUpperCase().contains(entity.channel.toUpperCase());
    }, orElse: () => new MapEntry("", "")).value;

    Widget listRow = new Container(
      padding: new EdgeInsets.symmetric(horizontal: 3.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          child: new Stack(
            children: <Widget>[
              new Positioned(
                child: new Container(
                    child: new VideoPreviewAdapter(
                  true,
                  false,
                  entity.id,
                  video: showDownloadProgressBar
                      ? Video.fromMap(entity.toMap())
                      : null,
                  videoEntity: showDownloadProgressBar ? null : entity,
                  videoProgressEntity: videosWithPlaybackProgress[entity.id],
                )),
              ),
              new Positioned(
                top: 12.0,
                left: 0.0,
                child: getRemoveButton(index, context, entity),
              ),
              //Overlay Banner
              new Positioned(
                bottom: 0,
                left: 0.0,
                right: 0.0,
                child: new Opacity(
                  opacity: 0.7,
                  child: getBottomBar(context, entity, assetPath),
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
      ]),
    );

    return listRow;
  }

  Container getBottomBar(
      BuildContext context, VideoEntity entity, String assetPath) {
    return new Container(
      color: Colors.grey[800],
      child: new Column(
        children: <Widget>[
          videosWithPlaybackProgress[entity.id] != null
              ? PlaybackProgressBar(
                  videosWithPlaybackProgress[entity.id].progress,
                  int.tryParse(entity.duration.toString()),
                  false)
              : new Container(),
          getVideoMetaInformationListTile(entity, assetPath, context),
        ],
      ),
    );
  }

  ListTile getVideoMetaInformationListTile(
      VideoEntity entity, String assetPath, BuildContext context) {
    return new ListTile(
      trailing: new Text(
        entity.duration != null
            ? Calculator.calculateDuration(entity.duration)
            : "",
        style: videoMetadataTextStyle.copyWith(color: Colors.white),
      ),
      leading: assetPath.isNotEmpty
          ? new ChannelThumbnail(assetPath, true)
          : new Container(),
      title: new Text(
        entity.title,
        style:
            Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
      ),
      subtitle: new Text(
        entity.topic != null ? entity.topic : "",
        style: Theme.of(context).textTheme.title.copyWith(color: Colors.white),
      ),
    );
  }

  Center getRemoveButton(int index, BuildContext context, VideoEntity entity) {
    return new Center(
      child: new FloatingActionButton(
        heroTag: null, // explicitly set to null
        mini: true,
        onPressed: () {
          onRemoveVideo(context, entity.id);
        },
        backgroundColor: Colors.red[800],
        highlightElevation: 10.0,
        isExtended: true,
        foregroundColor: Colors.black,
        elevation: 7.0,
        tooltip: "Delete",
        child: new Icon(Icons.delete_forever, color: Colors.white),
      ),
    );
  }
}
