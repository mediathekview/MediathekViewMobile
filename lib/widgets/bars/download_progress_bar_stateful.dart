import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/download_manager_flutter.dart';
import 'package:logging/logging.dart';

typedef void OnDownloadStateChange(DownloadTaskStatus state);
typedef void OnDownloadError(var e);
typedef void OnSubscriptionDone();

class DownloadProgressbarStateful extends StatefulWidget {
  final Logger logger = new Logger('DownloadProgressBar');
  Video video;
  DownloadManager downloadManager;
  var onDownloadFinished;

  DownloadProgressbarStateful(
      this.video, this.downloadManager, this.onDownloadFinished);

  @override
  _DownloadProgressbarStatefulState createState() =>
      _DownloadProgressbarStatefulState();
}

class _DownloadProgressbarStatefulState
    extends State<DownloadProgressbarStateful> {
  DownloadTaskStatus currentStatus;
  double progress;

  @override
  void dispose() {
    widget.logger.fine("Cancle subscription in dowlnload section");
    widget.downloadManager.cancelSubscription(widget.video.id);
  }

  @override
  Widget build(BuildContext context) {
    subscribeToProgressChannel();

    if (progress != null && currentStatus != null) {
      widget.logger.fine("Progressbar: Progress: " +
          progress.toString() +
          " and current status " +
          currentStatus.toString());
    }
    return currentStatus != null &&
            (currentStatus == DownloadTaskStatus.running ||
                currentStatus == DownloadTaskStatus.paused ||
                currentStatus == DownloadTaskStatus.enqueued)
        ? getProgressIndicator()
        : new Container();
  }

  Widget getProgressIndicator() {
    return new Container(
        constraints: BoxConstraints.expand(height: 5.0),
        child: progress == null || progress == -1
            ? new LinearProgressIndicator(
                valueColor:
                    new AlwaysStoppedAnimation<Color>(Colors.green[700]),
                backgroundColor: Colors.green[100])
            : new LinearProgressIndicator(
                value: (progress / 100),
                valueColor:
                    new AlwaysStoppedAnimation<Color>(Colors.green[700]),
                backgroundColor: Colors.green[100]));
  }

  void subscribeToProgressChannel() {
    widget.downloadManager.subscribe(widget.video, onDownloadStateChanged,
        onDownloaderComplete, onDownloaderFailed, onSubscriptionCanceled);
  }

  void onDownloaderFailed(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'failed' signal");
    updateStatus(DownloadTaskStatus.failed, videoId);
    widget.onDownloadFinished();
  }

  void onDownloaderComplete(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'complete' signal");
    updateStatus(DownloadTaskStatus.complete, videoId);
    widget.onDownloadFinished();
  }

  void onSubscriptionCanceled(String videoId) {
    widget.logger
        .info("Download video: " + videoId + " received 'concaled' signal");
    widget.onDownloadFinished();
    updateStatus(DownloadTaskStatus.canceled, videoId);
    widget.onDownloadFinished();
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
}
