import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/enum/channels.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/video_progress_manager.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/util/timestamp_calculator.dart';
import 'package:flutter_ws/widgets/bars/download_progress_bar.dart';
import 'package:flutter_ws/widgets/bars/playback_progress_bar.dart';
import 'package:flutter_ws/widgets/downloadSection/watch_history.dart';
import 'package:flutter_ws/widgets/overviewSection/util.dart';
import 'package:flutter_ws/widgets/videolist/channel_thumbnail.dart';
import 'package:flutter_ws/widgets/videolist/circular_progress_with_text.dart';
import 'package:flutter_ws/widgets/videolist/video_preview_adapter.dart';
import 'package:logging/logging.dart';

const ERROR_MSG = "Deletion of video failed.";
const TRY_AGAIN_MSG = "Try again.";
const recentlyWatchedVideosLimit = 5;

class DownloadSection extends StatefulWidget {
  final Logger logger = new Logger('DownloadSection');

  @override
  State<StatefulWidget> createState() {
    return new DownloadSectionState(new Set());
  }
}

class DownloadSectionState extends State<DownloadSection> {
  static const downloadManagerIdentifier = 1;

  Set<VideoEntity> downloadedVideos = new Set();
  Set<VideoEntity> currentDownloads = new Set();
  AppState appState;
  Set<String> userDeletedAppId; //used for fade out animation
  int milliseconds = 1500;
  Map<String, VideoEntity> entities = new Map();
  Map<String, DownloadTaskStatus> currentStatus = new Map();
  Map<String, double> progress = new Map();
  Map<String, VideoProgressEntity> videosWithPlaybackProgress = new Map();
  VideoProgressManager videoProgressManager;

  DownloadSectionState(this.userDeletedAppId);

  @override
  void dispose() {
    videoProgressManager = null;
  }

  @override
  Widget build(BuildContext context) {
    appState = AppSharedStateContainer.of(context).appState;
    Size size = MediaQuery.of(context).size;
    var orientation = MediaQuery.of(context).orientation;
    appState.downloadManager.syncCompletedDownloads();
    loadAlreadyDownloadedVideosFromDb();
    loadCurrentDownloads();
    loadVideosWithPlaybackProgress();
    // video progress manager needs to have correct context to display error messages
    videoProgressManager =
        new VideoProgressManager(context, appState.databaseManager);

    Widget loadingIndicator;
    if (currentDownloads.length == 1) {
      loadingIndicator = CircularProgressWithText(
          new Text("Downloading: '" + currentDownloads.elementAt(0).title + "'",
              style: connectionLostTextStyle),
          Colors.green,
          Colors.green,
          height: 50.0);
    } else if (currentDownloads.length > 1) {
      loadingIndicator = CircularProgressWithText(
        new Text(
            "Downloading " + currentDownloads.length.toString() + " videos",
            style: connectionLostTextStyle),
        Colors.green,
        Colors.green,
        height: 50.0,
      );
    } else {
      loadingIndicator = new Container();
    }

    List<Widget> watchHistoryItems =
        Util.getWatchHistoryItems(videosWithPlaybackProgress, size.width / 2);

    return new Scaffold(
      backgroundColor: Colors.grey[800],
      body: new SafeArea(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            loadingIndicator,
            videosWithPlaybackProgress.isNotEmpty
                ? Padding(
                    padding:
                        EdgeInsets.only(left: 20.0, top: 5.0, bottom: 16.0),
                    child: new Text(
                      "Kürzlich angesehen",
                      style: new TextStyle(
                          fontSize: 25.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w800),
                    ),
                  )
                : new Container(),
            new Container(
              height: size.width / 2 / 16 * 9,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: watchHistoryItems,
              ),
            ),
            videosWithPlaybackProgress.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.only(top: 5.0, bottom: 4.0),
                    child: new ListTile(
                      leading: new Icon(
                        Icons.history,
                        size: 30.0,
                      ),
                      title: new Text(
                        "Komplette History",
                        style: new TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(new MaterialPageRoute(
                            builder: (BuildContext context) {
                              return new WatchHistory();
                            },
                            settings: RouteSettings(name: "WatchHistory"),
                            fullscreenDialog: true));
                      },
                    ),
                  )
                : new Container(),
            videosWithPlaybackProgress.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.only(left: 20.0, top: 20.0),
                    child: new Text(
                      "Meine Downloads",
                      style: new TextStyle(
                          fontSize: 25.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w800),
                    ),
                  )
                : new Container(),
            new Flexible(
              child: new GridView.builder(
                  gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 5.0,
                      childAspectRatio: 16 / 9,
                      crossAxisCount:
                          (orientation == Orientation.portrait) ? 2 : 3),
                  // Create a grid with 2 columns. If you change the scrollDirection to
                  // horizontal, this produces 2 rows.
                  padding: const EdgeInsets.all(5.0),
                  shrinkWrap: true,
                  // Generate 100 widgets that display their index in the List.
                  itemBuilder: itemBuilder,
                  itemCount: currentDownloads.length + downloadedVideos.length),
            ),
          ],
        ),
      ),
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    int currentDownloadsLength = currentDownloads.length;
    bool isCurrentlyDownloading = false;
    VideoEntity entity;

    if (index <= currentDownloadsLength - 1 && currentDownloadsLength > 0) {
      entity = currentDownloads.elementAt(index);
      isCurrentlyDownloading = true;
      widget.logger.info("The video is currently downloading: " + entity.title);
    } else {
      //index already in downloaded videos
      int downloadedVideoIndex = index - currentDownloadsLength;
      entity = downloadedVideos.elementAt(downloadedVideoIndex);
    }

    subscribeToProgressChannel(entity);

    entities.putIfAbsent(entity.id, () => entity);

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
              child: new Container(
                child: (index <= currentDownloadsLength - 1 &&
                        currentDownloadsLength > 0)
                    ? new VideoPreviewAdapter(
                        true,
                        entity.id,
                        video: Video.fromMap(entity.toMap()),
                        showLoadingIndicator: false,
                        videoProgressEntity:
                            videosWithPlaybackProgress[entity.id],
                      )
                    : new VideoPreviewAdapter(
                        true,
                        entity.id,
                        showLoadingIndicator: false,
                        videoProgressEntity:
                            videosWithPlaybackProgress[entity.id],
                      ),
              ),
            ),
            new Positioned(
              top: 12.0,
              left: 0.0,
              child: new Center(
                child: new FloatingActionButton(
                  heroTag: index.toString(),
                  mini: true,
                  onPressed: () {
                    deleteOrStopDownload(context, entity.id);
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
              bottom: 0,
              left: 0.0,
              right: 0.0,
              child: new Opacity(
                opacity: 0.7,
                child: new Container(
                    color: Colors.grey[700],
                    child: new Column(
                      children: <Widget>[
                        videosWithPlaybackProgress[entity.id] != null
                            ? PlaybackProgressBar(
                                videosWithPlaybackProgress[entity.id].progress,
                                int.parse(entity.duration.toString()),
                                false)
                            : new Container(),
                        new ListTile(
                          trailing: new Text(
                            entity.duration != null
                                ? Calculator.calculateDuration(entity.duration)
                                : "",
                            style: videoMetadataTextStyle.copyWith(
                                color: Colors.white),
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
                      ],
                    )),
              ),
            ),
            isCurrentlyDownloading == true
                ? new Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: new DownloadProgressBar(
                        Video.fromMap(entity.toMap()),
                        currentStatus[entity.id] != null
                            ? currentStatus[entity.id]
                            : DownloadTaskStatus.running,
                        progress[entity.id] != null && progress[entity.id] > -1
                            ? progress[entity.id]
                            : -1),
                  )
                : new Container(),
          ],
        ),
      ]),
    );

    return listRow;
  }

  //Cancels active download (remove from task schema), removes the file from local storage & deletes the entry in VideoEntity schema
  void deleteOrStopDownload(BuildContext context, String id) {
    widget.logger.info("Deleting video with title: " +
        entities[id].title +
        " id: " +
        id +
        " id: " +
        entities[id].id);
    appState.downloadManager.deleteVideo(id).then((bool deletedSuccessfully) {
      if (deletedSuccessfully && mounted) {
        setState(() {
          SnackbarActions.showSuccess(context, "Successfully deleted ");
        });
        return;
      }
      SnackbarActions.showErrorWithTryAgain(context, ERROR_MSG, TRY_AGAIN_MSG,
          appState.downloadManager.deleteVideo, id);
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

  void OnDownloadFinished(String videoId) {
    widget.logger.info("Download Successfull");
    if (mounted) {
      widget.logger.info("Successfull and mounted");
      setState(() {});
    }
  }

  void subscribeToProgressChannel(VideoEntity entity) {
    appState.downloadManager.subscribe(
        Video.fromMap(entity.toMap()),
        onDownloadStateChanged,
        onDownloaderComplete,
        onDownloaderFailed,
        onSubscriptionCanceled,
        downloadManagerIdentifier);
  }

  void onDownloaderFailed(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'failed' signal");
    _updateStatus(DownloadTaskStatus.failed, videoId);
    OnDownloadFinished(videoId);
  }

  void onDownloaderComplete(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'complete' signal");
    _updateStatus(DownloadTaskStatus.complete, videoId);
    OnDownloadFinished(videoId);
  }

  void onSubscriptionCanceled(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'concaled' signal");
    _updateStatus(DownloadTaskStatus.canceled, videoId);
    OnDownloadFinished(videoId);
  }

  void onDownloadStateChanged(String videoId, DownloadTaskStatus updatedStatus,
      double updatedProgress) {
    widget.logger.info("Download: " +
        entities[videoId].title +
        " status: " +
        updatedStatus.toString() +
        " progress: " +
        updatedProgress.toString());

    progress.putIfAbsent(videoId, () => updatedProgress);
    progress.update(videoId, (oldProgress) => updatedProgress);

    _updateStatus(updatedStatus, videoId);
  }

  void _updateStatus(DownloadTaskStatus updatedStatus, String videoId) {
    currentStatus.putIfAbsent(videoId, () => updatedStatus);
    currentStatus.update(videoId, (status) => updatedStatus);
    if (mounted) {
      setState(() {});
    } else {
      widget.logger.severe("Not updating status for Video  " +
          videoId +
          " - downloadCardBody not mounted");
    }
  }

  Future loadVideosWithPlaybackProgress() async {
    //check for playback progress
    if (videosWithPlaybackProgress.isEmpty) {
      return appState.databaseManager
          .getLastViewedVideos(recentlyWatchedVideosLimit)
          .then((all) {
        if (all != null && all.isNotEmpty) {
          all.forEach((entity) =>
              videosWithPlaybackProgress.putIfAbsent(entity.id, () => entity));
          setState(() {});
        }
        return;
      });
    }
  }

  Padding getHeading(String message) {
    return new Padding(
      padding: EdgeInsets.only(left: 20.0, top: 20.0, bottom: 16.0),
      child: new Text(
        message,
        style: new TextStyle(
            fontSize: 25.0, color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}
