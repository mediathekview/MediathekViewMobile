import 'package:flutter/material.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/util/timestamp_calculator.dart';

import 'channel_thumbnail.dart';

class MetaInfoListTile {
  static ListTile getVideoMetaInformationListTile(
      BuildContext context,
      String duration,
      String title,
      int timestamp,
      String assetPath,
      bool isDownloaded) {
    return new ListTile(
      trailing: new Text(
        duration != null ? Calculator.calculateDuration(duration) : "",
        style: videoMetadataTextStyle.copyWith(color: Colors.white),
      ),
      leading: assetPath.isNotEmpty
          ? new ChannelThumbnail(assetPath, isDownloaded)
          : new Container(),
      title: new Text(
        title,
        style:
            Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
      ),
      subtitle: new Text(
        timestamp != null ? Calculator.calculateTimestamp(timestamp) : "",
        style: Theme.of(context).textTheme.title.copyWith(color: Colors.white),
      ),
    );
  }
}
