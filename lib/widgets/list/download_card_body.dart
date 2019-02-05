import 'package:flutter/material.dart';
import 'package:flutter_ws/model/download_status.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/model/video_entity.dart';
import 'package:flutter_ws/platform_channels/database_manager.dart';
import 'package:flutter_ws/platform_channels/download_manager.dart';
import 'package:flutter_ws/platform_channels/native_video_manager.dart';
import 'package:flutter_ws/util/text_styles.dart';
import 'package:flutter_ws/widgets/filterMenu/download_progress_bar.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:flutter_ws/widgets/list/metadata_bar.dart';
import 'package:flutter_ws/widgets/reuse/circular_progress_with_text.dart';
import 'package:uuid/uuid.dart';

class DownloadCardBody extends StatefulWidget {
  final Video video;

  DownloadCardBody(this.video);

  @override
  State<StatefulWidget> createState() {
    return new InformationRowBodyState(new Uuid());
  }
}

class InformationRowBodyState extends State<DownloadCardBody> {
  bool switchValue;
  DownloadStatusText status;
  bool permissionDenied;

  NativeVideoPlayer nativeVideoPlayer;

  Uuid uuid;

  AppSharedState appWideState;
  DownloadManager downloadManager;
  DatabaseManager databaseManager;

  InformationRowBodyState(this.uuid);

  @override
  Widget build(BuildContext context) {
    appWideState = AppSharedStateContainer.of(context);
    VideoEntity videoEntity =
        appWideState.appState.downloadedVideos[widget.video.id];

    bool isAlreadyDownloaded = false;

    if (videoEntity != null) {
      isAlreadyDownloaded = true;
      switchValue = true;
      status = DownloadStatusText.STATUS_SUCCESSFUL;
    }

    downloadManager = appWideState.appState.downloadManager;
    databaseManager = appWideState.appState.databaseManager;

    // appWideState = AppSharedappWideState.of(context);

    if (appWideState.appState.currentDownloads.containsKey(widget.video.id)) {
      switchValue = true;
//      status = DownloadStatusText.STATUS_RUNNING;
    }

    VideoListState videoListState = appWideState.videoListState;

    bool isExtendet = false;
    if (videoListState != null) {
      Set<String> extendetTiles = videoListState.extendetListTiles;
      isExtendet = extendetTiles.contains(widget.video.id);
    }

    if (permissionDenied != null && permissionDenied == true)
      switchValue = false;

//    downloadManager.getStatus(widget.video.id).then((akt) {
//      if (!mounted) return;
//
//      if (akt == null || akt.status == null) {
//        //print("Video with id " + widget.video.id + " is not downloading");
//        return;
//      }
//
//      setState(() {
//        status = akt.status;
//        switchValue = true;
//      });
//    }, onError: (e) => print("Error: Video with id " + widget.video.id + " is not downloading"));

    return new Column(
        key: new Key(uuid.v1()),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          isExtendet == false
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
                              child: status != null &&
                                      (status ==
                                              DownloadStatusText
                                                  .STATUS_RUNNING ||
                                          status ==
                                              DownloadStatusText
                                                  .STATUS_PENDING ||
                                          status ==
                                              DownloadStatusText.STATUS_PAUSED)
                                  ? new CircularProgressWithText(
                                      new Text(
                                          getVideoDownloadText(
                                              isAlreadyDownloaded),
                                          style: subHeaderTextStyle.copyWith(
                                              color: Colors.black)),
                                      Colors.white,
                                      Colors.grey)
                                  : new Text(
                                      getVideoDownloadText(isAlreadyDownloaded),
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

                                print("Switch touched with value: " +
                                    newSwitchValue.toString());

                                if (newSwitchValue == true && status == null) {
                                  print(
                                      "Triggering download for video with id " +
                                          widget.video.id);
                                  onDownloadRequested();
                                  return;
                                }

                                if (isAlreadyDownloaded) {
                                  print("Deleting download for video with id " +
                                      videoEntity.id);

                                  appWideState.appState.downloadedVideos
                                      .remove(videoEntity.id);

                                  databaseManager.delete(videoEntity.id).then(
                                      (id) {
                                    print("Deleted from Database");

                                    new NativeVideoPlayer()
                                        .deleteVideo(videoEntity.fileName)
                                        .then((bool) {
                                      if (bool) {
                                        print(
                                            "Deleted video also from local storage");
                                      } else {
                                        print(
                                            "Failed to Delete video also from local storage");
                                      }
                                    },
                                            onError: (e) => print(
                                                "Deleting video failed. Reason " +
                                                    e.toString()));
                                  },
                                      onError: (e) => print(
                                          "Error when deleting videos from Db"));

                                  status = null;

                                  //NativeVideoPlayer().playVideo(videoEntity.filePath, videoEntity.mimeType);
                                  return;
                                }

                                if (status == null) {
                                  //should not happen. Just remove from active downloads
                                  appWideState.appState.currentDownloads
                                      .remove(widget.video.id);
                                }

                                if (status != null &&
                                    (status ==
                                            DownloadStatusText.STATUS_RUNNING ||
                                        status ==
                                            DownloadStatusText.STATUS_PENDING ||
                                        status ==
                                            DownloadStatusText.STATUS_PAUSED)) {
                                  print(
                                      "Canceling download for video with id " +
                                          widget.video.id);

                                  cancleActiveDownload(context);

                                  return;
                                }
                              }),
                      status != null &&
                              status == DownloadStatusText.STATUS_FAILED
                          ? new Icon(Icons.warning, color: Colors.red)
                          : new Container(),
                    ]),
          new Flexible(
              key: new Key(uuid.v1()),
              child: new Container(
                  margin:
                      new EdgeInsets.symmetric(vertical: 8.0, horizontal: 40.0),
                  height: 2.0,
                  color: Colors.grey)),
          new MetadataBar(widget.video.duration, widget.video.timestamp),
          new DownloadProgressBar(widget.video.id, downloadManager,
              onDownloadStateChanged: onDownloadStateChanged,
              onDownloadError: onDOwnloaderError,
              onSubscriptionDone: onSubscriptionDone),
        ]);
  }

  void cancleActiveDownload(BuildContext context) {
    downloadManager.cancelDownload(widget.video.id).then((id) {
      status = null;
      print("Chanceled download");
    }, onError: (e) {
//      OsChecker.getTargetPlatform().then((platform) {
//        Firebase.logPlatformChannelException(
//            'cancelDownload', e.toString(), platform.toString());
//      });
      showSnackBar(context, "Abbruch des aktiven Downloads ist fehlgeschlagen");
    });
  }

  void showSnackBar(BuildContext context, String text) {
    Scaffold.of(context).showSnackBar(
      new SnackBar(
        backgroundColor: Colors.red,
        content: new Text(text),
      ),
    );
  }

  @override
  void initState() {
    switchValue = false;
  }

  void onDownloadStateChanged(DownloadStatus updatedStatus) {
//    if (updatedStatus.id != widget.video.id) return;

//    print("Download with id " +
//        updatedStatus.id +
//        " has " +
//        updatedStatus.status.toString());

    if (updatedStatus.status == DownloadStatusText.STATUS_SUCCESSFUL) {
      print("Download Card Body: Download with id" +
          widget.video.id +
          " is successfull");
//      Video video = appWideState.appState.currentDownloads[updatedStatus.id];
//
//      VideoEntity entity = VideoEntity.fromVideo(video);
//      entity.filePath = updatedStatus.filePath;
//      entity.fileName = DownloadManager.getFileNameForVideo(
//          video.id, video.url_video, video.title);
//      entity.mimeType = updatedStatus.mimeType;
//
//      appWideState.appState.currentDownloads.remove(updatedStatus.id);
//      appWideState.appState.downloadedVideos
//          .putIfAbsent(entity.id, () => entity);
//
//      appWideState.appState.databaseManager.insert(entity).then((dynamic) {
//        print("Inserted downloaded video with id " +
//            entity.id +
//            " and filename " +
//            entity.fileName +
//            " into db");
//      });

//      setState(() {
////        switchValue = true;
//        status = DownloadStatusText.STATUS_SUCCESSFUL;
//      });
    }

    if (updatedStatus.status == DownloadStatusText.STATUS_CANCELED) {
      switchValue = false;
      updateStatus(null);
      return;
    } else if (updatedStatus.status == DownloadStatusText.STATUS_FAILED) {
      switchValue = false;
      updateStatus(updatedStatus.status);
      showSnackBar(context, "Download fehlgeschlagen");
      return;
    }

    if ((updatedStatus.status == DownloadStatusText.STATUS_RUNNING ||
            updatedStatus.status == DownloadStatusText.STATUS_PAUSED ||
            updatedStatus.status == DownloadStatusText.STATUS_PENDING) &&
        switchValue == false) {
      print("Putting switch value on - download is already running");
      setState(() {
        permissionDenied = false;
//        switchValue = true;
      });
      return;
    }

    updateStatus(updatedStatus.status);
  }

  void updateStatus(DownloadStatusText updatedStatus) {
    if (updatedStatus != status) {
      print("Update Status: new : " +
          updatedStatus.toString() +
          " old: " +
          status.toString());
      if (mounted) {
        setState(() {
          status = updatedStatus;
        });
      }
    }
  }

  @override
  void dispose() {
//    print("Disposing information row body");
    super.dispose();
  }

  void onSubscriptionDone() {
    //whole stream is done - cannot recieve any download updates any more!
    print("Received close signal from download manager");
  }

  //
  void onDOwnloaderError(e) {
    //Code == video ID & Message is the error message from the ios/android downloader
    print("Received error signal from download manager. Message: " +
        e.toString());

    updateStatus(DownloadStatusText.STATUS_FAILED);
  }

  void onDownloadRequested() {
    downloadManager
        .downloadFile(widget.video)
        .then((video) => print("Downloaded request successfull"), onError: (e) {
      print("Error starting download: " +
          widget.video.title +
          ". Error:  " +
          e.toString());

//      OsChecker.getTargetPlatform().then((platform) {
//        Firebase.logPlatformChannelException(
//            'downloadFile', e.toString(), platform.toString());
//      });

      setState(() {
        permissionDenied = true;
      });
    });
  }

  String getVideoDownloadText(bool isAlreadyDownloaded) {
    if (isAlreadyDownloaded || status == DownloadStatusText.STATUS_SUCCESSFUL)
      return "Downloaded";
    else if (status == DownloadStatusText.STATUS_CANCELED)
      return "Canceled";
    else if (status == DownloadStatusText.STATUS_RUNNING)
      return "Downloading";
    else if (status == DownloadStatusText.STATUS_PAUSED)
      return "Downloading";
    else if (status == DownloadStatusText.STATUS_PENDING)
      return "Pending";
    else if (status == DownloadStatusText.STATUS_FAILED)
      return "Download error";
    return "Download";
  }

  bool isLivestreamVideo(Video video) {
    return video.url_video.substring(video.url_video.lastIndexOf(".")) ==
        ".m3u8";
  }
}
