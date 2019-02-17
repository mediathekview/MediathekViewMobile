import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:logging/logging.dart';

typedef void OnDownloadStateChange(DownloadTaskStatus state);
typedef void OnDownloadError(var e);
typedef void OnSubscriptionDone();

class DownloadProgressBar extends StatelessWidget {
  final Logger logger = new Logger('DownloadProgressBar');
  Video video;
  DownloadTaskStatus currentStatus;
  double downloadProgress;

  DownloadProgressBar(this.video, this.currentStatus, this.downloadProgress);

  @override
  Widget build(BuildContext context) {
    if (downloadProgress != null && currentStatus != null) {
      logger.fine("Progressbar: Progress: " +
          downloadProgress.toString() +
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
        child: downloadProgress == null || downloadProgress == -1
            ? new LinearProgressIndicator(
                valueColor:
                    new AlwaysStoppedAnimation<Color>(Colors.green[700]),
                backgroundColor: Colors.green[100])
            : new LinearProgressIndicator(
                value: (downloadProgress / 100),
                valueColor:
                    new AlwaysStoppedAnimation<Color>(Colors.green[700]),
                backgroundColor: Colors.green[100]));
  }
}
