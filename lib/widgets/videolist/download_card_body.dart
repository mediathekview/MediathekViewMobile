import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/download_manager_flutter.dart';
import 'package:flutter_ws/platform_channels/video_manager.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/bars/download_progress_bar.dart';
import 'package:flutter_ws/widgets/bars/metadata_bar.dart';
import 'package:flutter_ws/widgets/videolist/circular_progress_with_text.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

const ERROR_MSG = "Delete of video failed.";
const ERROR_MSG_DOWNLOAD = "Download failed.";

class DownloadCardBody extends StatefulWidget {
  final Logger logger = new Logger('DownloadCardBody');
  final Video video;
  final DownloadManager downloadManager;
  final DatabaseManager databaseManager;
  final NativeVideoPlayer nativeVideoPlayer;
  final tileIsExtendet;
  final bool isDownloadedAlready;
  final bool isCurrentlyDownloading;
  final DownloadTaskStatus currentStatus;
  final double progress;
  Uuid uuid;
  var onDownloadRequested;
  var onDeleteRequested;

  DownloadCardBody(
      this.video,
      this.downloadManager,
      this.databaseManager,
      this.nativeVideoPlayer,
      this.tileIsExtendet,
      this.isDownloadedAlready,
      this.isCurrentlyDownloading,
      this.currentStatus,
      this.progress,
      this.onDownloadRequested,
      this.onDeleteRequested);

  @override
  State<StatefulWidget> createState() {
    return new DownloadCardBodyState(new Uuid());
  }
}

class DownloadCardBodyState extends State<DownloadCardBody> {
  bool switchValue = false;
  bool permissionDenied = false;
  Uuid uuid;

  DownloadCardBodyState(this.uuid);

  @override
  void dispose() {
    super.dispose();
    widget.logger.fine("Disposing download card body for video with name " +
        widget.video.title +
        " and id " +
        widget.video.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDownloadedAlready) {
      switchValue = true;
    } else if (widget.isCurrentlyDownloading) {
      switchValue = true;
    }

    if (permissionDenied != null && permissionDenied == true) {
      switchValue = false;
    }

    return new Column(
        key: new Key(uuid.v1()),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.tileIsExtendet == false
              ? new Container()
              : new Row(
                  key: new Key(uuid.v1()),
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    isLivestreamVideo(widget.video)
                        ? new Container()
                        : new Container(
                            key: new Key(uuid.v1()),
                            padding:
                                new EdgeInsets.only(left: 40.0, right: 12.0),
                            child: widget.currentStatus != null &&
                                    (widget.currentStatus ==
                                            DownloadTaskStatus.running ||
                                        widget.currentStatus ==
                                            DownloadTaskStatus.enqueued ||
                                        widget.currentStatus ==
                                            DownloadTaskStatus.paused)
                                ? new CircularProgressWithText(
                                    new Text(
                                        getVideoDownloadText(
                                            widget.isDownloadedAlready),
                                        style: subHeaderTextStyle.copyWith(
                                            color: Colors.black)),
                                    Colors.white,
                                    Colors.grey)
                                : new Text(
                                    getVideoDownloadText(
                                        widget.isDownloadedAlready),
                                    style: subHeaderTextStyle.copyWith(
                                        color: Colors.black),
                                  ),
                          ),
                    isLivestreamVideo(widget.video)
                        ? new Container()
                        : new Switch(
                            key: new Key(uuid.v1()),
                            activeColor: Colors.green,
                            value: switchValue,
                            onChanged: (newSwitchValue) {
                              setState(() {
                                switchValue = newSwitchValue;
                              });

                              widget.logger.fine("Switch touched with value: " +
                                  newSwitchValue.toString());

                              if (newSwitchValue == true &&
                                  widget.currentStatus == null) {
                                widget.logger.fine(
                                    "Triggering download for video with id " +
                                        widget.video.id);
                                widget.onDownloadRequested();
                                return;
                              }

                              //Delete the video - remove download task, delete from disk & from VideoEntity db
                              widget.onDeleteRequested();
                            },
                          ),
                    widget.currentStatus != null &&
                            widget.currentStatus == DownloadTaskStatus.failed
                        ? new Icon(Icons.warning, color: Colors.red)
                        : new Container(),
                  ],
                ),
          new Flexible(
              key: new Key(uuid.v1()),
              child: new Container(
                  margin:
                      new EdgeInsets.symmetric(vertical: 8.0, horizontal: 40.0),
                  height: 2.0,
                  color: Colors.grey)),
          new MetadataBar(widget.video.duration, widget.video.timestamp),
          new DownloadProgressBar(
              widget.video, widget.currentStatus, widget.progress),
        ]);
  }

  String getVideoDownloadText(bool isAlreadyDownloaded) {
    if (isAlreadyDownloaded ||
        widget.currentStatus == DownloadTaskStatus.complete)
      return "Downloaded";
    else if (widget.currentStatus == DownloadTaskStatus.canceled)
      return "Canceled";
    else if (widget.currentStatus == DownloadTaskStatus.running)
      return "Downloading";
    else if (widget.currentStatus == DownloadTaskStatus.paused)
      return "Downloading";
    else if (widget.currentStatus == DownloadTaskStatus.enqueued)
      return "Pending";
    else if (widget.currentStatus == DownloadTaskStatus.failed)
      return "Download error";
    return "Download";
  }

  bool isLivestreamVideo(Video video) {
    return video.url_video.substring(video.url_video.lastIndexOf(".")) ==
        ".m3u8";
  }
}
