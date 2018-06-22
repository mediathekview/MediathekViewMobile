import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/manager/nativeVideoManager.dart';
import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/model/VideoEntity.dart';
import 'package:flutter_ws/util/calculator.dart';
import 'package:flutter_ws/util/textStyles.dart';
import 'package:flutter_ws/widgets/filterMenu/downloadProgressBar.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:flutter_ws/widgets/list/channelThumbnail.dart';
import 'package:flutter_ws/widgets/list/videoPreviewAdapter.dart';

class DownloadSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new DownloadSectionState(new Set());
  }
}

class DownloadSectionState extends State<DownloadSection> {
  List<MapEntry<String, VideoEntity>> downloadedVideos;
  List<MapEntry<String, Video>> currentDownloads;
  AppState appState;
  Set<String> userDeletedAppId; //used for fade out animation
  int milliseconds = 1500;

  DownloadSectionState(this.userDeletedAppId);

  @override
  void initState() {
    //Todo  I want to be informed about running downloads  - that are not in the active list right now! -> for instance after kill of app or fll restart!
    //need a method in the downloader manager to get all the currently running downloads
  }

  @override
  Widget build(BuildContext context) {
    appState = AppSharedStateContainer.of(context).appState;

    downloadedVideos = appState.downloadedVideos.entries.toList();
    currentDownloads = appState.currentDownloads.entries.toList();

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: new AppBar(
        title: new Center(
          child: const Text('Downloads'),
        ),
        elevation: 6.0,
        backgroundColor: Colors.grey[800],
      ),
      body: new ListView.builder(
          itemBuilder: itemBuilder,
          itemCount: currentDownloads.length + downloadedVideos.length),
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    VideoEntity entity;
    Video video;
    downloadedVideos = appState.downloadedVideos.entries.toList();
    int length = appState.currentDownloads.length;

    if (index <= length - 1 && length > 0) {
      video = currentDownloads[index].value;
      entity = VideoEntity.fromVideo(video);
    } else {
      //index already in downloaded videos
      int downloadedVideoIndex = index - length;
      entity = downloadedVideos[downloadedVideoIndex].value;
    }

    String assetPath = Channels.channelMap.entries.firstWhere((entry) {
      return entity.channel != null &&
              entity.channel.toUpperCase().contains(entry.key.toUpperCase()) ||
          entry.key.toUpperCase().contains(entity.channel.toUpperCase());
    }, orElse: () => new MapEntry("", "")).value;

    Widget listRow = new Container(
      padding: new EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        new Stack(
          children: <Widget>[
            new Positioned(
              child: new VideoPreviewAdapter(entity.id,
                  video: video, showLoadingIndicator: false),
            ),
            new Positioned(
              top: 12.0,
              left: 0.0,
              child: new Center(
                child: new FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    if (appState.currentDownloads[entity.id] != null)
                      cancelActiveDownload(entity.id);
                    else
                      deleteDownloadedVideo(entity.id, entity.fileName);
                  },
                  backgroundColor: Colors.red[800],
                  highlightElevation: 10.0,
                  isExtended: true,
                  foregroundColor: Colors.black,
                  elevation: 7.0,
                  tooltip: "Delete",
                  child: new Icon(Icons.delete_forever, color: Colors.white),
                ),
              ),
            ),
            //Overlay Banner
            new Positioned(
              bottom: 11.0,
              left: 0.0,
              right: 0.0,
              child: new Opacity(
                opacity: 0.7,
                child: new Container(
                  color: Colors.grey[700],
                  child: new ListTile(
                    trailing: new Text(
                      entity.duration != null
                          ? Calculator.calculateDuration(entity.duration)
                          : "",
                      style:
                          videoMetadataTextStyle.copyWith(color: Colors.white),
                    ),
                    leading: assetPath.isNotEmpty
                        ? new ChannelThumbnail(assetPath)
                        : new Container(),
                    title: new Text(
                      entity.title,
                      style: Theme
                          .of(context)
                          .textTheme
                          .subhead
                          .copyWith(color: Colors.white),
                    ),
                    subtitle: new Text(
                      entity.topic != null ? entity.topic : "",
                      style: Theme
                          .of(context)
                          .textTheme
                          .title
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            new Positioned(
              bottom: 6.0,
              left: 0.0,
              right: 0.0,
              child:
                  new DownloadProgressBar(entity.id, appState.downloadManager),
            ),
          ],
        ),
      ]),
    );

    return new AnimatedOpacity(
        opacity:
            userDeletedAppId != null && userDeletedAppId.contains(entity.id)
                ? 0.0
                : 1.0,
        // Fade out when user just deleted the app
        curve: Curves.easeOut,
        duration: new Duration(milliseconds: milliseconds),
        child: listRow);
  }

  deleteDownloadedVideo(String id, String fileName) {
    print("Deleting download for video with id " + id);

    new Timer(new Duration(milliseconds: milliseconds), () {
      setState(() {
        appState.downloadedVideos.remove(id);
        userDeletedAppId.remove(id);
      });
    });

    setState(() {
      userDeletedAppId.add(id);
    });

    appState.databaseManager.delete(id).then((id) {
      print("Deleted from Database");

      new NativeVideoPlayer().deleteVideo(fileName).then((bool) {
        if (bool) {
          print("Deleted video also from local storage");
        } else {
          print("Failed to Delete video also from local storage");
        }
      },
          onError: (e) => print(
              "Deleting video from file system failed. However it is deleted from the Database already. Reason " +
                  e.toString()));
    }, onError: (e) => print("Error when deleting videos from Db"));
  }

  void cancelActiveDownload(String id) {
    setState(() {
      userDeletedAppId.add(id);
    });

    new Timer(new Duration(milliseconds: milliseconds), () {
      appState.downloadManager.cancelDownload(id).then(
        (Void) {
          print("Chanceled download with id " + id);
          //Download managers internally removes active download from state - so state changed already here
          setState(() {
            userDeletedAppId.remove(id);
          });
        },
        onError: (e) {
          Scaffold.of(context).showSnackBar(
                new SnackBar(
                  backgroundColor: Colors.red,
                  content: new Text(
                      "Abbruch des aktiven Downloads ist fehlgeschlagen."),
                  action: new SnackBarAction(
                    label: "Erneut versuchen",
                    onPressed: () {
                      Scaffold.of(context).hideCurrentSnackBar();
                      cancelActiveDownload(id);
                    },
                  ),
                ),
              );
        },
      );
    });
  }
}
