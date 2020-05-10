import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/section/download_section.dart';
import 'package:flutter_ws/util/cross_axis_count.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/widgets/downloadSection/video_list_item_builder.dart';
import 'package:logging/logging.dart';

class CurrentDownloads extends StatefulWidget {
  final Logger logger = new Logger('CurrentDownloads');
  final AppSharedState appWideState;
  var setStateNecessary;
  int downloadManagerIdentifier = 1;

  Map<String, VideoProgressEntity> videosWithPlaybackProgress = new Map();

  CurrentDownloads(this.appWideState, this.videosWithPlaybackProgress,
      this.setStateNecessary);

  @override
  _CurrentDownloadsState createState() => _CurrentDownloadsState();
}

class _CurrentDownloadsState extends State<CurrentDownloads> {
  Map<String, VideoEntity> currentDownloads = new Map();
  Map<String, DownloadTaskStatus> downloadStatus = new Map();
  Map<String, double> downloadProgress = new Map();

  @override
  void initState() {
    loadCurrentDownloads();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (currentDownloads.isEmpty) {
      return new SliverToBoxAdapter(child: new Container());
    }

    var videoListItemBuilder = new VideoListItemBuilder.name(
        cancelCurrentDownload,
        currentDownloads.values.toList(),
        widget.videosWithPlaybackProgress,
        true,
        downloadProgress: downloadProgress,
        downloadStatus: downloadStatus);

    int crossAxisCount = CrossAxisCount.getCrossAxisCount(context);

    SliverGrid downloadList = SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 9,
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 5.0,
      ),
      delegate: SliverChildBuilderDelegate(videoListItemBuilder.itemBuilder,
          childCount: currentDownloads.length),
    );

    return downloadList;
  }

  void loadCurrentDownloads() async {
    Set<VideoEntity> downloads = await widget
        .appWideState.appState.downloadManager
        .getCurrentDownloads();

    if (currentDownloads.length == downloads.length) {
      return;
    }

    downloads.forEach((entity) {
      currentDownloads.putIfAbsent(entity.id, () => entity);
      widget.logger
          .info("Current download: " + entity.id + ". Title: " + entity.title);
      subscribeToProgressChannel(entity);
    });

    widget.setStateNecessary(currentDownloads.values.toList());

    if (mounted) {
      setState(() {});
    }
  }

  void subscribeToProgressChannel(VideoEntity entity) {
    widget.logger
        .info("Subscribing to download progress for video: " + entity.title);
    widget.appWideState.appState.downloadManager.subscribe(
        Video.fromMap(entity.toMap()),
        onDownloadStateChanged,
        onDownloaderComplete,
        onDownloaderFailed,
        onSubscriptionCanceled,
        widget.downloadManagerIdentifier);
  }

  void OnDownloadFinished(String videoId) {
    if (currentDownloads.isEmpty) {
      return;
    }

    widget.logger.info("Download Successfull");

    currentDownloads.remove(videoId);
    if (mounted) {
      setState(() {});
    }
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

    // notify about new downloaded video
    widget.setStateNecessary(currentDownloads.values.toList());
  }

  void onSubscriptionCanceled(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'concaled' signal");
    _updateStatus(DownloadTaskStatus.canceled, videoId);
    OnDownloadFinished(videoId);
  }

  void onDownloadStateChanged(String videoId, DownloadTaskStatus updatedStatus,
      double updatedProgress) {
    if (currentDownloads[videoId] == null) {
      return;
    }

    widget.logger.info("Download: " +
        currentDownloads[videoId].title +
        " status: " +
        updatedStatus.toString() +
        " progress: " +
        updatedProgress.toString());

    downloadProgress.putIfAbsent(videoId, () => updatedProgress);
    downloadProgress.update(videoId, (oldProgress) => updatedProgress);

    _updateStatus(updatedStatus, videoId);
  }

  void _updateStatus(DownloadTaskStatus updatedStatus, String videoId) {
    downloadStatus.update(videoId, (status) => updatedStatus,
        ifAbsent: () => updatedStatus);
    if (mounted) {
      setState(() {});
    } else {
      widget.logger.fine("Not updating status for Video  " +
          videoId +
          " - downloadCardBody not mounted");
    }
  }

  //Cancels active download (remove from task schema), removes the file from local storage & deletes the entry in VideoEntity schema
  void cancelCurrentDownload(BuildContext context, String id) {
    widget.logger.info("Canceling download for: " + id);
    widget.appWideState.appState.downloadManager
        .deleteVideo(id)
        .then((bool deletedSuccessfully) {
      if (deletedSuccessfully && mounted) {
        currentDownloads.remove(id);
        setState(() {
          SnackbarActions.showSuccess(context, "Löschen erfolgreich");
        });
        widget.setStateNecessary(currentDownloads.values.toList());
        return;
      }
      SnackbarActions.showErrorWithTryAgain(context, ERROR_MSG, TRY_AGAIN_MSG,
          widget.appWideState.appState.downloadManager.deleteVideo, id);
    });
  }
}
