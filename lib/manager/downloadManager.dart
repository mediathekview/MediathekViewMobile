import 'dart:async';
import 'dart:convert';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/model/DownloadStatus.dart';
import 'package:flutter_ws/model/Video.dart';
import 'package:flutter_ws/model/VideoEntity.dart';
import 'package:flutter_ws/widgets/inherited/list_state_container.dart';
import 'package:path_provider/path_provider.dart';

enum DownloadStatusText {
  STATUS_FAILED,
  STATUS_PAUSED,
  STATUS_PENDING,
  STATUS_RUNNING,
  STATUS_SUCCESSFUL,
  STATUS_CANCELED
}

class DownloadManager {
  static DownloadManager _instance;

  //Method Channel
  MethodChannel _downloadMethodChannel;

  //Event channel
  EventChannel _downloadEventChannel;

  //Result Streams
  Stream<DownloadStatus> _progressStream;

  BuildContext _context;

  AppSharedState appWideState;

  //remember video that was intended to be downloaded, but permission was missing
  Video downloadVideoRequestWithoutPermission;


  factory DownloadManager(BuildContext context) {
    if (_instance == null) {
      final MethodChannel downloadMethodChannel =
      const MethodChannel('samples.flutter.io/download');
      final EventChannel downloadEventChannel =
      const EventChannel('samples.flutter.io/downloadEvent');

      _instance = new DownloadManager.private(
          downloadEventChannel, downloadMethodChannel, context, AppSharedStateContainer.of(context));

    }
    return _instance;
  }

  @visibleForTesting
  DownloadManager.private(
      this._downloadEventChannel, this._downloadMethodChannel, this._context, this.appWideState);

  Stream<DownloadStatus> get onDownloadProgressUpdate {
    if (_progressStream == null) {
      _progressStream = _downloadEventChannel
          .receiveBroadcastStream()
          .map((dynamic event) => parseDownloadEvent(event));
    }
    return _progressStream;
  }

  Future<Video> downloadFile(Video video) async {

    Uri videoUrl = Uri.parse(video.url_video);
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("fileName", () => getFileNameForVideo(video.id, video.url_video, video.title));
    requestArguments.putIfAbsent("videoUrl", () => videoUrl.toString());
    requestArguments.putIfAbsent("userDownloadId", () => video.id);

    // same as video id if provided
    String downloadManagerId = await _downloadMethodChannel.invokeMethod(
        'downloadFile', requestArguments);

    if (downloadManagerId == "-1") {
      downloadVideoRequestWithoutPermission = video;
      print("Remembering download attemped video for later use");
      throw new Exception("Permission for accessing local filesystem not granted yet -asking for permission");
    }

    appWideState.appState.currentDownloads
        .putIfAbsent(video.id, () => video);

    print("Requested download of video with id " +
        video.id +
        " and url " +
        video.url_video);

    return video;
  }

  Future<DownloadStatus> getStatus(String downloadId) async {
    print('Requesting Download status synchronously for video with id ' +
        downloadId.toString());

    Map<String, String> requestArguments = getRequestArgument(downloadId);

    Map status;
//    try {
    status =
    await _downloadMethodChannel.invokeMethod('status', requestArguments);

    print('Download status received synchronously for video with id ' +
        downloadId.toString());
//    } on PlatformException catch (e) {
//      print(e.message);
//      return null;
//    }

    return parseDownloadEvent(status);
  }

  Map<String, String> getRequestArgument(String downloadId) {
    Map<String, String> requestArguments = new Map();
    requestArguments.putIfAbsent("id", () => downloadId);
    return requestArguments;
  }

  Future<String> cancelDownload(String downloadId) async {

    Map<String, String> requestArguments = getRequestArgument(downloadId);

    int amountOfRemovedDownloads = await _downloadMethodChannel.invokeMethod(
        'cancelDownload', requestArguments);

      appWideState.appState.currentDownloads.remove(downloadId);

    print("Successfully Stopped " +
        amountOfRemovedDownloads.toString() +
        " download.");
    return downloadId;
  }

   DownloadStatus parseDownloadEvent(Map event) {
    String videoId = event["id"];

    //special case when having to ask for permission first on android
    if (AppSharedStateContainer.of(_context).appState.currentDownloads[videoId] == null && downloadVideoRequestWithoutPermission != null) {
      appWideState.appState.currentDownloads.putIfAbsent(
          videoId, () => downloadVideoRequestWithoutPermission);
      downloadVideoRequestWithoutPermission == null;
      print("Permission for video with id " + videoId + " has been granted - adding to current downloads");
    }

    DownloadStatus downloadStatus = new DownloadStatus(videoId);

    String status = event["statusText"];

    switch (status) {
      case 'STATUS_SUCCESSFUL':

        Video video = appWideState.appState.currentDownloads[videoId];

        print("Download Manager: Download: " + videoId + " is " + status);

        downloadStatus.filePath = event["filePath"];
        downloadStatus.status = DownloadStatusText.STATUS_SUCCESSFUL;
        downloadStatus.totalActiveCount = int.parse(event["totalActiveCount"]);
        downloadStatus.mimeType = event["mimeType"];

        if (video == null){
          //already removed from state - happens N amount of subscriptions to the download manager - 1 times
          return downloadStatus;
        }

        VideoEntity entity = VideoEntity.fromVideo(video);
        entity.filePath = downloadStatus.filePath;
        entity.fileName = DownloadManager.getFileNameForVideo(
            videoId, video.url_video, video.title);
        entity.mimeType = downloadStatus.mimeType;

        appWideState.appState.currentDownloads.remove(videoId);

        appWideState.appState.downloadedVideos
            .putIfAbsent(entity.id, () => entity);

        appWideState.appState.databaseManager.insert(entity).then((dynamic) {

          print("Inserted downloaded video with id " +
              entity.id +
              " and filename " +
              entity.fileName +
              " into db");
        }, onError: (e) {
          print("Save to Database failed for video with id " + videoId + " Error: " + e.toString());
          //TODO need to show error
//          Scaffold.of(_context).showSnackBar(
//            new SnackBar(
//              backgroundColor: Colors.red,
//              content: new Text(
//                  "Lokales speichern fehlgeschlagen!. Die Datei ist dennoch im Ordner /MediathekView verfügbar."),
//            ),
//          );
        });


        break;
      case 'STATUS_RUNNING':
        downloadStatus.status = DownloadStatusText.STATUS_RUNNING;
        var progress = event["progress"];
        if (progress != null) {
          downloadStatus.progress = double.parse(progress);
          print("Download Manager: Download: " + videoId + " is " + status + " with progress " + downloadStatus.progress.toString());
        }
        else
          downloadStatus.progress = -1.0;
        downloadStatus.totalActiveCount = int.parse(event["totalActiveCount"]);
        break;

      case 'STATUS_PENDING':
        downloadStatus.status = DownloadStatusText.STATUS_PENDING;
        break;

      case 'STATUS_PAUSED':
        downloadStatus.status = DownloadStatusText.STATUS_PAUSED;
        downloadStatus.message = event['reasonText'];
        downloadStatus.totalActiveCount = int.parse(event["totalActiveCount"]);
        var progress = event["progress"];
        if (progress != null) {
          downloadStatus.progress = double.parse(progress);
          print("Download Manager: Download: " + videoId + " is " + status + " with progress " + downloadStatus.progress.toString());
        }
        else
          downloadStatus.progress = -1.0;
        break;

      case 'STATUS_FAILED':
        downloadStatus.status = DownloadStatusText.STATUS_FAILED;
        downloadStatus.message = event['reasonText'];
        downloadStatus.totalActiveCount = int.parse(event["totalActiveCount"]);
        appWideState.appState.currentDownloads.remove(videoId);
        print("Download Manager: Download: " + videoId + " is " + status + ". Reason: " + downloadStatus.message);

        break;
      case 'STATUS_CANCELED':
        downloadStatus.status = DownloadStatusText.STATUS_CANCELED;
        downloadStatus.message = event['reasonText'];
        downloadStatus.totalActiveCount = int.parse(event["totalActiveCount"]);
        appWideState.appState.currentDownloads.remove(videoId);
        print("Download Manager: Download: " + videoId + " is " + status);
        break;

      default:
        print('$status is not a valid download status.');
        throw new ArgumentError('$status is not a valid download status.');
    }

    return downloadStatus;
  }

  static String getFileNameForVideo(String videoId, String videoUrl, String videoTitle) {
    String fileExtension = videoUrl.substring(videoUrl.lastIndexOf("."));
    return videoId + fileExtension;
  }
}
