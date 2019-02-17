import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/download_manager_flutter.dart';
import 'package:flutter_ws/platform_channels/video_manager.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/widgets/videolist/channel_thumbnail.dart';
import 'package:flutter_ws/widgets/videolist/download_card_body.dart';
import 'package:flutter_ws/widgets/videolist/video_description.dart';
import 'package:flutter_ws/widgets/videolist/video_preview_adapter.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

class ListCard extends StatefulWidget {
  final Logger logger = new Logger('VideoWidget');
  final String channelPictureImagePath;
  final Video video;

  ListCard(
      {Key key, @required this.channelPictureImagePath, @required this.video})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _ListCardState();
  }
}

class _ListCardState extends State<ListCard> {
  BuildContext context;
  AppSharedState stateContainer;
  bool modalBottomScreenIsShown = false;
  bool isDownloadedAlready = false;
  bool isCurrentlyDownloading = false;
  DownloadTaskStatus currentStatus;
  double progress;
  DownloadManager downloadManager;
  DatabaseManager databaseManager;
  GlobalKey _keyListRow;

  @override
  void dispose() {
    super.dispose();
    widget.logger.fine("Disposing list-card for video with title " +
        widget.video.title +
        " and id " +
        widget.video.id);
    downloadManager.cancelSubscription(widget.video.id);
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    stateContainer = AppSharedStateContainer.of(context);
    downloadManager = stateContainer.appState.downloadManager;
    databaseManager = stateContainer.appState.databaseManager;
    VideoListState videoListState = stateContainer.videoListState;
    //TODO into state
    NativeVideoPlayer nativeVideoPlayer = new NativeVideoPlayer();

    subscribeToProgressChannel();
    loadCurrentStatus(widget.video.id);

    bool isExtendet = false;
    if (videoListState != null) {
      Set<String> extendetTiles = videoListState.extendetListTiles;
      isExtendet = extendetTiles.contains(widget.video.id);
    }
    Uuid uuid = new Uuid();

    final cardContent = new Container(
      margin: new EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: new Column(
        key: new Key(uuid.v1()),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(key: new Key(uuid.v1()), height: 4.0),
          new Flexible(
            key: new Key(uuid.v1()),
            child: new Container(
              key: new Key(uuid.v1()),
              margin: new EdgeInsets.only(left: 40.0, right: 12.0),
              child: new Text(
                widget.video.topic,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(color: Colors.black),
              ),
            ),
          ),
          new Container(key: new Key(uuid.v1()), height: 10.0),
          new Flexible(
            key: new Key(uuid.v1()),
            child: new Container(
              key: new Key(uuid.v1()),
              margin: new EdgeInsets.only(left: 40.0, right: 12.0),
//              padding: new EdgeInsets.only(right: 13.0),
              child: new Text(
                widget.video.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: Theme.of(context)
                    .textTheme
                    .subhead
                    .copyWith(color: Colors.black),
              ),
            ),
          ),
          isExtendet == true
              ? new Container(
                  key: new Key(uuid.v1()),
                  margin:
                      new EdgeInsets.symmetric(vertical: 8.0, horizontal: 40.0),
                  height: 2.0,
                  color: Colors.grey)
              : new Container(
                  key: new Key(uuid.v1()),
                  padding: new EdgeInsets.only(left: 40.0, right: 12.0)),
          new Column(key: new Key(uuid.v1()), children: <Widget>[
            isExtendet == true
                ? new VideoPreviewAdapter(widget.video.id,
                    video: widget.video,
                    defaultImageAssetPath: widget.channelPictureImagePath,
                    showLoadingIndicator: false)
                : new Container(),
            //ContentRow is always visible but like a sandwich in the middle of the download switch and the progress bar
            new DownloadCardBody(
                widget.video,
                downloadManager,
                databaseManager,
                nativeVideoPlayer,
                isExtendet,
                isDownloadedAlready,
                isCurrentlyDownloading,
                currentStatus,
                progress,
                onDownloadRequested,
                onDeleteRequested),
          ]),
        ],
      ),
    );

    final card = new Container(
      child: cardContent,
      margin: new EdgeInsets.only(left: 20.0),
      decoration: new BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        boxShadow: <BoxShadow>[
          new BoxShadow(
            color: Colors.black12,
            blurRadius: 10.0,
            offset: new Offset(0.0, 10.0),
          ),
        ],
      ),
    );

    //used to determine position on screen to place description popup correctly
    _keyListRow = GlobalKey();

    return new Container(
      key: _keyListRow,
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ),
      child: new Stack(
        children: <Widget>[
          new GestureDetector(onTap: _handleTap, child: card),
          isExtendet
              ? new Container()
              : new Positioned.fill(
                  left: 20.0,
                  child: new Material(
                      color: Colors.transparent,
                      child: new InkWell(
                          onTap: _handleTap, onLongPress: showDescription)),
                ),
          widget.channelPictureImagePath.isNotEmpty
              ? new ChannelThumbnail(
                  widget.channelPictureImagePath, isDownloadedAlready)
              : new Container(),
        ],
      ),
    );
  }

  void _handleTap() {
    widget.logger.fine("handle tab on tile");
    stateContainer.updateExtendetListTile(widget.video.id);
    //only rerender this tile, not the whole app state!
    setState(() {});
  }

  showDescription() {
    double distanceOfRowToStart = determineDistanceOfRowToStart();
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new VideoDescription(
            widget.video, widget.channelPictureImagePath, distanceOfRowToStart);
      },
    );
  }

  double determineDistanceOfRowToStart() {
    final RenderBox renderBox = _keyListRow.currentContext.findRenderObject();
    final position = renderBox.localToGlobal(Offset.zero);
    return position.distance;
  }

  void onDownloadStateChanged(String videoId, DownloadTaskStatus updatedStatus,
      double updatedProgress) {
    widget.logger.fine("Download: " +
        widget.video.title +
        " status: " +
        updatedStatus.toString() +
        " progress: " +
        updatedProgress.toString());

    progress = updatedProgress;

    updateStatus(updatedStatus, videoId);
  }

  void updateStatus(DownloadTaskStatus updatedStatus, String videoId) {
    if (mounted) {
      setState(() {
        currentStatus = updatedStatus;
      });
    } else {
      widget.logger.severe("Not updating status for Video  " +
          videoId +
          " - downloadCardBody not mounted");
    }
  }

  void subscribeToProgressChannel() {
    downloadManager.subscribe(widget.video, onDownloadStateChanged,
        onDownloaderComplete, onDownloaderFailed, onSubscriptionCanceled);
  }

  void onDownloaderFailed(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'failed' signal");
    SnackbarActions.showError(context, ERROR_MSG_DOWNLOAD);
    updateStatus(DownloadTaskStatus.failed, videoId);
  }

  void onDownloaderComplete(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'complete' signal");
    updateStatus(DownloadTaskStatus.complete, videoId);
  }

  void onSubscriptionCanceled(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'concaled' signal");
    updateStatus(DownloadTaskStatus.canceled, videoId);
  }

  void loadCurrentStatus(String videoId) async {
    if (await downloadManager.isAlreadyDownloaded(videoId)) {
      widget.logger.fine("Video with name  " +
          widget.video.title +
          " and id " +
          videoId +
          " is downloaded already");
      if (!isDownloadedAlready) {
        isDownloadedAlready = true;
        isCurrentlyDownloading = false;
        currentStatus = null;
        if (mounted) {
          setState(() {});
        }
      }
      return;
    }

    if (await downloadManager.isCurrentlyDownloading(videoId)) {
      widget.logger.fine("Video with name  " +
          widget.video.title +
          " and id " +
          videoId +
          " is currently downloading");
      if (!isCurrentlyDownloading) {
        isDownloadedAlready = false;
        isCurrentlyDownloading = true;
        currentStatus = DownloadTaskStatus.running;

        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void onDownloadRequested() {
    subscribeToProgressChannel();
    downloadManager
        .downloadFile(widget.video)
        .then((video) => widget.logger.info("Downloaded request successfull"),
            onError: (e) {
      widget.logger.info("Error starting download: " +
          widget.video.title +
          ". Error:  " +
          e.toString());
    });
  }

  void onDeleteRequested() {
    downloadManager
        .deleteVideo(widget.video.id)
        .then((bool deletedSuccessfully) {
      if (!deletedSuccessfully) {
        SnackbarActions.showError(context, ERROR_MSG);
        return;
      }
      isDownloadedAlready = false;
      isCurrentlyDownloading = false;
      currentStatus = null;
      progress = null;
      if (mounted) {
        widget.logger
            .info("Successfully deleted video with id " + widget.video.id);
        setState(() {});
      }
    });
  }
}
