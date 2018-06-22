import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ws/model/DownloadStatus.dart';
import 'package:flutter_ws/manager/downloadManager.dart';
import 'package:uuid/uuid.dart';

typedef  void OnDownloadStateChange(DownloadStatus state);
typedef  void OnDownloadError(var e);
typedef  void OnSubscriptionDone();

class DownloadProgressBar extends StatefulWidget{
  String videoId;
  DownloadManager downloadManager;
  OnDownloadStateChange onDownloadStateChanged;
  OnDownloadError onDownloadError;
  OnSubscriptionDone onSubscriptionDone;

  DownloadProgressBar(this.videoId, this.downloadManager, {this.onDownloadStateChanged,
      this.onDownloadError, this.onSubscriptionDone});

  @override
  State<StatefulWidget> createState() {
    Uuid uuid = new Uuid();
    Key progressIndicatorKey = new Key(uuid.v1());

    return new DownloadProgressBarState(progressIndicatorKey);
  }

}

class DownloadProgressBarState extends State<DownloadProgressBar>{
  StreamSubscription<DownloadStatus> subscription;
  Key progressIndicatorKey;
  DownloadStatusText status;
  double progress;
  DownloadProgressBarState(this.progressIndicatorKey);


  @override
  void initState() {
    super.initState();
    subscribeToProgressChannel();
  }

  @override
  void dispose() {
    super.dispose();
    print("Called dispose on Progress bar for video " + widget.videoId);
    subscription.cancel();
  }

  void subscribeToProgressChannel() {
    subscription = widget.downloadManager.onDownloadProgressUpdate.listen(
            (DownloadStatus state) => this.onDownloaderProgress(state),
        onError: (e) => widget.onDownloadError != null? widget.onDownloadError(e): {},
        onDone: () => widget.onSubscriptionDone != null ? widget.onSubscriptionDone(): {});
  }

  @override
  Widget build(BuildContext context) {
    return status != null && (status == DownloadStatusText.STATUS_RUNNING || status == DownloadStatusText.STATUS_PAUSED)  ? getProgressIndicator(): new Container();
  }

  Widget getProgressIndicator() {
    return new Container(constraints: BoxConstraints.expand(height: 5.0),child:  progress == null || progress == -1 ? new LinearProgressIndicator(key: progressIndicatorKey, valueColor: new AlwaysStoppedAnimation<Color>(Colors.green[700]), backgroundColor: Colors.green[100])
        : new LinearProgressIndicator(key: progressIndicatorKey,value: (progress / 100),  valueColor: new AlwaysStoppedAnimation<Color>(Colors.green[700]), backgroundColor: Colors.green[100]));
  }

  onDownloaderProgress(DownloadStatus state) {

    if (state.id != widget.videoId) return;

    print("DownloadProgressbar : " + widget.videoId + " Status: " + state.status.toString() + " Progress: " + state.progress.toString());

    if (mounted) {
      setState(() {
        status = state.status;
        progress = state.progress;
      });
    }

    //parent decides if it wants to trigger a rerender of its state -> update switvh text
    widget.onDownloadStateChanged != null? widget.onDownloadStateChanged(state): {};
  }


}