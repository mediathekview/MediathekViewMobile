import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/download_manager_flutter.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:flutter_ws/util/video.dart';
import 'package:flutter_ws/widgets/videolist/util/util.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'download/DownloadController.dart';
import 'download/DownloadValue.dart';

const ERROR_MSG = "Löschen fehlgeschlagen";

class DownloadSwitch extends StatefulWidget {
  final Logger logger = new Logger('DownloadSwitch');
  AppSharedState appWideState;

  final Video video;
  final bool isTablet;
  final DownloadManager downloadManager;

  bool isDownloadedAlready;
  bool isCurrentlyDownloading;

  DownloadSwitch(this.appWideState, this.video, this.isCurrentlyDownloading,
      this.isDownloadedAlready, this.downloadManager, this.isTablet);

  @override
  State<StatefulWidget> createState() {
    return new DownloadSwitchState(new Uuid());
  }
}

class DownloadSwitchState extends State<DownloadSwitch> {
  bool permissionDenied = false;
  Uuid uuid;
  bool isLivestreamVideo;
  DownloadValue _latestDownloadValue;
  DownloadController downloadController;

  DownloadSwitchState(this.uuid);

  @override
  void dispose() {
    widget.logger.info("Disposing DownloadSwitch");
    if (downloadController != null) {
      downloadController.removeListener(updateDownloadState);
      downloadController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    isLivestreamVideo = VideoUtil.isLivestreamVideo(widget.video);
    subscribeToDownloadUpdates(
        widget.video.id, widget.video.title, widget.downloadManager);
    super.initState();
  }

  void subscribeToDownloadUpdates(
      String videoId, String videoTitle, DownloadManager downloadManager) {
    downloadController =
        new DownloadController(videoId, videoTitle, downloadManager);
    _latestDownloadValue = downloadController.value;
    downloadController.addListener(updateDownloadState);
    downloadController.initialize();
    updateIfCurrentlyDownloading();
  }

  void updateDownloadState() {
    widget.logger.fine("Download switch: update from DownloadController");
    _latestDownloadValue = downloadController.value;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget download = new Container();
    if (!isLivestreamVideo) {
      ActionChip downloadChip = ActionChip(
        avatar: getAvatar(),
        label: new Text(
          getVideoDownloadText(widget.isDownloadedAlready),
          style: TextStyle(fontSize: 20.0),
        ),
        labelStyle: TextStyle(color: Colors.white),
        onPressed: downloadButtonPressed,
        backgroundColor: getChipBackgroundColor(),
        elevation: 20,
        padding: EdgeInsets.all(10),
      );
      download = downloadChip;

      if (isDownloading()) {
        ActionChip cancleDownloadChip = ActionChip(
          avatar: new Icon(Icons.cancel, color: Colors.white),
          label: new Text(
            "Cancel",
            style: TextStyle(fontSize: 20.0),
          ),
          labelStyle: TextStyle(color: Colors.white),
          onPressed: deleteVideo,
          backgroundColor: Colors.red,
          elevation: 20,
        );
        download = new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              cancleDownloadChip,
              new Container(width: 25),
              downloadChip,
            ]);
      }
    }

    return new Row(
      key: new Key(uuid.v1()),
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Container(
          key: new Key(uuid.v1()),
          //padding: new EdgeInsets.only(left: 40.0, right: 12.0),
          child: download,
        ),
        downloadFailed()
            ? new Icon(Icons.warning, color: Colors.red)
            : new Container(),
      ],
    );
  }

  void downloadButtonPressed() {
    if (isDownloading()) {
      return;
    }

    if (_latestDownloadValue.status == DownloadTaskStatus.complete ||
        widget.isDownloadedAlready) {
      deleteVideo();
      return;
    }

    widget.logger
        .info("Triggering download for video with id " + widget.video.id);
    downloadVideo();
  }

  bool downloadFailed() {
    if (_latestDownloadValue == null) {
      return false;
    }

    return _latestDownloadValue.status != null &&
        _latestDownloadValue.status == DownloadTaskStatus.failed;
  }

  bool isDownloading() {
    if (_latestDownloadValue == null) {
      return false;
    }
    return _latestDownloadValue.status == DownloadTaskStatus.running ||
        _latestDownloadValue.status == DownloadTaskStatus.enqueued ||
        _latestDownloadValue.status == DownloadTaskStatus.paused;
  }

  String getVideoDownloadText(bool isAlreadyDownloaded) {
    if (_latestDownloadValue == null) {
      return "";
    }
    if (isAlreadyDownloaded ||
        _latestDownloadValue.status == DownloadTaskStatus.complete)
      return "Delete Video";
    else if (_latestDownloadValue.status == DownloadTaskStatus.running &&
        _latestDownloadValue.progress.toInt() == -1)
      return "";
    else if (_latestDownloadValue.status == DownloadTaskStatus.running)
      return "" + _latestDownloadValue.progress.toInt().toString() + "%";
    else if (_latestDownloadValue.status == DownloadTaskStatus.paused)
      return "" + _latestDownloadValue.progress.toInt().toString() + "%";
    else if (_latestDownloadValue.status == DownloadTaskStatus.enqueued)
      return "Waiting...";
    else if (_latestDownloadValue.status == DownloadTaskStatus.failed)
      return "Download failed";
    else if (_latestDownloadValue.status == DownloadTaskStatus.undefined ||
        _latestDownloadValue.status == DownloadTaskStatus.canceled)
      return "Download";
    return "Unknown status";
  }

  Color getChipBackgroundColor() {
    if (widget.isDownloadedAlready) {
      return Colors.green;
    } else if (_latestDownloadValue.status == DownloadTaskStatus.complete) {
      return Colors.green;
    } else {
      return new Color(0xffffbf00);
    }
  }

  Widget getAvatar() {
    if (permissionDenied != null && permissionDenied == true) {
      return new Icon(Icons.error, color: Colors.red);
    } else if (isDownloading()) {
      return CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white));
    } else if (widget.isDownloadedAlready ||
        _latestDownloadValue.status == DownloadTaskStatus.complete) {
      return new Icon(Icons.cancel, color: Colors.red);
    } else {
      return new Icon(Icons.file_download, color: Colors.green);
    }
  }

  void downloadVideo() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      SnackbarActions.showError(context, ERROR_MSG_NO_INTERNET);
      downloadController.value =
          downloadController.value.copyWith(status: DownloadTaskStatus.failed);
      return;
    }

    // also check if video url is accessible
    final response = await http.head(widget.video.url_video);

    if (response.statusCode >= 300) {
      SnackbarActions.showError(context, ERROR_MSG_NOT_AVAILABLE);
      downloadController.value =
          downloadController.value.copyWith(status: DownloadTaskStatus.failed);
      return;
    }

    // start download animation right away.
    if (mounted) {
      setState(() {
        downloadController.value = downloadController.value
            .copyWith(status: DownloadTaskStatus.enqueued);
      });
    }

    // check for filesystem permissions
    // if user grants permission, start downloading right away
    if (!widget.appWideState.appState.hasFilesystemPermission) {
      widget.appWideState.appState.downloadManager
          .checkAndRequestFilesystemPermissions(
              widget.appWideState, widget.video);
      return;
    }

    widget.downloadManager
        .downloadFile(widget.video)
        .then((video) => widget.logger.info("Downloaded request successfull"),
            onError: (e) {
      widget.logger.severe("Error starting download: " +
          widget.video.title +
          ". Error:  " +
          e.toString());
    });
  }

  void deleteVideo() {
    widget.downloadManager
        .deleteVideo(widget.video.id)
        .then((bool deletedSuccessfully) {
      if (!deletedSuccessfully) {
        widget.logger
            .severe("Failed to delete video with title " + widget.video.title);
      }

      downloadController.value = downloadController.value
          .copyWith(status: DownloadTaskStatus.undefined, progress: null);
      widget.isDownloadedAlready = false;
      widget.isCurrentlyDownloading = false;
    });
  }

  void updateIfCurrentlyDownloading() {
    widget.downloadManager
        .isCurrentlyDownloading(widget.video.id)
        .then((status) {
      if (status != null) {
        if (mounted) {
          setState(() {
            _latestDownloadValue = new DownloadValue(
                videoId: widget.video.id, progress: -1, status: status.status);
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _latestDownloadValue = new DownloadValue(
              videoId: widget.video.id,
              progress: -1,
              status: DownloadTaskStatus.undefined);
        });
      }
    });
  }
}
