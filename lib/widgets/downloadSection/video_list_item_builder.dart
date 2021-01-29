import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/widgets/videolist/video_preview_adapter.dart';
import 'package:logging/logging.dart';

class VideoListItemBuilder {
  final Logger logger = new Logger('VideoListView');

  // called when the user pressed on the remove button
  var onRemoveVideo;

  List<Video> videos = new List();

  bool previewNotDownloadedVideos;
  bool showDeleteButton;
  bool openDetailPage;

  var queryEntries;

  // for mean video list
  int amountOfVideosFetched;
  int totalResultSize;
  int currentQuerySkip;
  final int pageThreshold = 25;

  VideoListItemBuilder.name(this.videos, this.previewNotDownloadedVideos,
      this.showDeleteButton, this.openDetailPage,
      {this.queryEntries,
      this.amountOfVideosFetched,
      this.totalResultSize,
      this.currentQuerySkip,
      this.onRemoveVideo});

  Widget itemBuilder(BuildContext context, int index) {
    // only required for the main video list to request more entries when reaching end of list
    if (queryEntries != null) {
      if (index + pageThreshold > videos.length) {
        queryEntries();
      }

      if (currentQuerySkip + pageThreshold >= totalResultSize &&
          videos.length == index + 1) {
        logger.info("ResultList - reached last position of result list.");
      } else if (videos.length == index + 1) {
        logger.info("Reached last position in list for query");
        return new Container(
            alignment: Alignment.center,
            width: 20.0,
            child: new CircularProgressIndicator(
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3.0));
      }
    }

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
        left: 5.0,
        child: getRemoveButton(index, context, video.id, filesize(video.size)),
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
                      previewNotDownloadedVideos,
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

  ActionChip getRemoveButton(
      int index, BuildContext context, String id, String filesize) {
    return new ActionChip(
      avatar: new Icon(Icons.delete_forever, color: Colors.white),
      label: new Text(
        filesize != null && filesize.length > 0
            ? "Löschen (" + filesize + ")"
            : "Löschen",
        style: TextStyle(fontSize: 20.0),
      ),
      labelStyle: TextStyle(color: Colors.white),
      onPressed: () {
        if (showDeleteButton) {
          onRemoveVideo(context, id);
        }
      },
      backgroundColor: Colors.green,
      elevation: 20,
      padding: EdgeInsets.all(10),
    );

    new Center(
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
