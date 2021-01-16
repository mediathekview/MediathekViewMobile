import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/widgets/videolist/video_preview_adapter.dart';

class Util {
  static List<Widget> getWatchHistoryItems(
      Map<String, VideoProgressEntity> videos, double width) {
    List<Widget> result = [];
    var videoProgressEntities = videos.values.toList();
    for (var i = 0; i < videos.length; i++) {
      Widget rect = getWatchHistoryItem(videoProgressEntities[i], width);
      result.add(rect);
    }
    return result;
  }

  static Widget getWatchHistoryItem(
      VideoProgressEntity videoProgress, double width) {
    String assetPath = getAssetPath(videoProgress.channel.toUpperCase());
    Widget rect =
        getWatchHistoryWidget(assetPath, videoProgress, width, 13, 11);
    return rect;
  }

  static String getAssetPath(String channel) {
    String assetPath = Channels.channelMap.entries
        .firstWhere(
            (entry) =>
                channel.contains(entry.key.toUpperCase()) ||
                entry.key.toUpperCase().contains(channel),
            orElse: () => new MapEntry("", ""))
        .value;
    return assetPath;
  }

  static Widget getWatchHistoryWidget(
      String channelPictureImagePath,
      VideoProgressEntity playbackProgress,
      double width,
      double headingFontSize,
      double metaFontSize) {
    return new Padding(
      padding: EdgeInsets.only(right: 5.0, left: 2.0),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        child: new Container(
          color: Colors.grey[100],
          width: width,
          child: Stack(
            children: <Widget>[
              new VideoPreviewAdapter(
                Video.fromMap(playbackProgress.toMap()),
                // always show previews for already watched videos
                // should be already generated
                true,
                true,
                false,
                defaultImageAssetPath: channelPictureImagePath,
                presetAspectRatio: 16 / 9,
                //size: new Size.fromWidth(1000),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
