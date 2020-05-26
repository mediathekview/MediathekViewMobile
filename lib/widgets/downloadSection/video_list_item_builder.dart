import 'package:flutter/material.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/widgets/videolist/video_preview_adapter.dart';

class VideoListItemBuilder {
  // called when the user pressed on the remove button
  var onRemoveVideo;

  List<Video> videos = new List();

  bool showDeleteButton;
  bool openDetailPage;

  VideoListItemBuilder.name(
      this.videos, this.showDeleteButton, this.openDetailPage,
      {this.onRemoveVideo});

  Widget itemBuilder(BuildContext context, int index) {
    Video video = videos.elementAt(index);

    String assetPath = Channels.channelMap.entries.firstWhere((entry) {
      return video.channel != null &&
              video.channel.toUpperCase().contains(entry.key.toUpperCase()) ||
          entry.key.toUpperCase().contains(video.channel.toUpperCase());
    }, orElse: () => new MapEntry("", "")).value;

    Widget deleteButton = new Container();
    if (showDeleteButton) {
      deleteButton = new Positioned(
        top: 12.0,
        left: 0.0,
        child: getRemoveButton(index, context, video.id),
      );
    }

    Widget listRow = new Container(
      padding: new EdgeInsets.symmetric(horizontal: 3.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          child: new Stack(
            children: <Widget>[
              new Positioned(
                child: new Container(
                    color: Colors.white,
                    child: new VideoPreviewAdapter(
                      video,
                      true,
                      openDetailPage,
                      defaultImageAssetPath: assetPath,
                      presetAspectRatio: 16 / 9,
                    )),
              ),
              deleteButton,
            ],
          ),
        ),
      ]),
    );

    return listRow;
  }

  Center getRemoveButton(int index, BuildContext context, String id) {
    return new Center(
      child: new FloatingActionButton(
        heroTag: null, // explicitly set to null
        mini: true,
        onPressed: () {
          if (showDeleteButton) {
            onRemoveVideo(context, id);
          }
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
