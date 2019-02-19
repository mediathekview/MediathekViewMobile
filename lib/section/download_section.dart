import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/util/timestamp_calculator.dart';
import 'package:flutter_ws/widgets/bars/download_progress_bar_stateful.dart';
import 'package:flutter_ws/widgets/videolist/channel_thumbnail.dart';
import 'package:flutter_ws/widgets/videolist/circular_progress_with_text.dart';
import 'package:flutter_ws/widgets/videolist/video_preview_adapter.dart';
import 'package:logging/logging.dart';

const ERROR_MSG = "Delete of video failed.";
const TRY_AGAIN_MSG = "Try again.";

class DownloadSection extends StatefulWidget {
  final Logger logger = new Logger('DownloadSection');

  @override
  State<StatefulWidget> createState() {
    return new DownloadSectionState(new Set());
  }
}

class DownloadSectionState extends State<DownloadSection> {
  Set<VideoEntity> downloadedVideos = new Set();
  Set<VideoEntity> currentDownloads = new Set();
  AppState appState;
  Set<String> userDeletedAppId; //used for fade out animation
  int milliseconds = 1500;

  DownloadSectionState(this.userDeletedAppId);

  @override
  Widget build(BuildContext context) {
    appState = AppSharedStateContainer.of(context).appState;

    loadAlreadyDownloadedVideosFromDb();
    loadCurrentDownloads();

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: new AppBar(
        title: new Center(
          child: const Text('Downloads'),
        ),
        elevation: 6.0,
        backgroundColor: Colors.green,
      ),
      body: currentDownloads.length == 0
          ? new ListView.builder(
              itemBuilder: itemBuilder,
              itemCount: currentDownloads.length + downloadedVideos.length)
          : new Column(children: <Widget>[
              CircularProgressWithText(
                  currentDownloads.length == 1
                      ? new Text(
                          "Downloading: '" +
                              currentDownloads.elementAt(0).title +
                              "'",
                          style: connectionLostTextStyle)
                      : new Text(
                          currentDownloads.length.toString() +
                              " downloads running",
                          style: connectionLostTextStyle),
                  Colors.green,
                  Colors.white),
              new Flexible(
                child: new ListView.builder(
                    itemBuilder: itemBuilder,
                    itemCount:
                        currentDownloads.length + downloadedVideos.length),
              )
            ]),
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    VideoEntity entity;
    int length = currentDownloads.length;
    bool isDownloadedAlready = true;

    if (index <= length - 1 && length > 0) {
      entity = currentDownloads.elementAt(index);
    } else {
      //index already in downloaded videos
      int downloadedVideoIndex = index - length;
      entity = downloadedVideos.elementAt(downloadedVideoIndex);
      isDownloadedAlready = false;
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
              child: (index <= length - 1 && length > 0)
                  ? new VideoPreviewAdapter(entity.id,
                      video: Video.fromMap(entity.toMap()),
                      showLoadingIndicator: false)
                  : new VideoPreviewAdapter(entity.id,
                      showLoadingIndicator: false),
            ),
            new Positioned(
              top: 12.0,
              left: 0.0,
              child: new Center(
                child: new FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    deleteDownload(context, entity.id);
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
                        ? new ChannelThumbnail(assetPath, true)
                        : new Container(),
                    title: new Text(
                      entity.title,
                      style: Theme.of(context)
                          .textTheme
                          .subhead
                          .copyWith(color: Colors.white),
                    ),
                    subtitle: new Text(
                      entity.topic != null ? entity.topic : "",
                      style: Theme.of(context)
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
              child: new DownloadProgressbarStateful(
                  Video.fromMap(entity.toMap()),
                  appState.downloadManager,
                  OnDownloadFinished),
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

  //Cancels active download (remove from task schema), removes the file from local storage & deletes the entry in VideoEntity schema
  void deleteDownload(BuildContext context, String id) {
    setState(() {
      userDeletedAppId.add(id);
    });

    new Timer(new Duration(milliseconds: milliseconds), () {
      appState.downloadManager.deleteVideo(id).then((bool deletedSuccessfully) {
        if (deletedSuccessfully) {
          setState(() {
            userDeletedAppId.remove(id);
          });
          return;
        }
        SnackbarActions.showErrorWithTryAgain(context, ERROR_MSG, TRY_AGAIN_MSG,
            appState.downloadManager.deleteVideo, id);
      });
    });
  }

  void loadAlreadyDownloadedVideosFromDb() async {
    Set<VideoEntity> downloads =
        await appState.databaseManager.getAllDownloadedVideos();
    if (downloadedVideos.length != downloads.length) {
      downloadedVideos = downloads;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void loadCurrentDownloads() async {
    Set<VideoEntity> downloads =
        await appState.downloadManager.getCurrentDownloads();

    if (currentDownloads.length != downloads.length) {
      currentDownloads = downloads;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void OnDownloadFinished() {
    if (mounted) {
      setState(() {});
    }
  }
}
