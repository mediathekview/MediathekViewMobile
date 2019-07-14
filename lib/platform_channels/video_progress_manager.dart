import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/util/connectivity_util.dart';
import 'package:flutter_ws/util/show_snackbar.dart';
import 'package:logging/logging.dart';

class VideoProgressManager {
  final Logger logger = new Logger('VideoProgressManager');
  EventChannel _eventChannel;
  Stream<dynamic> _updateStream;
  StreamSubscription<dynamic> streamSubscription;
  DatabaseManager databaseManager;

  VideoProgressManager(BuildContext context, DatabaseManager dbManager) {
    databaseManager = dbManager;

    _eventChannel =
        const EventChannel('com.mediathekview.mobile/videoProgressEvent');
    streamSubscription =
        _getBroadcastStream().listen((raw) => _onProgress(raw), onError: (e) {
      logger.severe(
          "Receiving video play progress failed. Reason " + e.toString());
      ConnectivityUtil.HasInternetConnectivity().then((isConnected) {
        if (isConnected) {
          SnackbarActions.showError(
              context, "Das Video wurde womöglich aus der Mediathek entfernt");
        } else {
          SnackbarActions.showError(context, "Keine Verbindung zum Internet");
        }
      });
    }, onDone: () {
      logger.info("Video play progress event channel is done.");
    }, cancelOnError: false);

    if (streamSubscription.isPaused) {
      logger.info("IS PAUSED.");
    }
  }

  _onProgress(raw) {
    String videoId = raw['videoId'];
    int progress = raw['progress'];

    if (videoId == null || videoId.isEmpty || progress == 0) {
      logger.warning(
          "Could not update video progress. Video id or progress is not set");
      return;
    }

    updateVideoProgress(videoId, progress);
  }

  updateVideoProgress(String videoId, int progress) {
    return databaseManager
        .updateVideoProgressEntity(new VideoProgressEntity(videoId, progress))
        .then((rowsUpdated) {
      if (rowsUpdated < 1) {
        logger.warning("Could not update video progress. Rows Updated < 1");
        return;
      }
      logger.info("Current playback progress: " + progress.toString());
    }, onError: (err, stackTrace) {
      logger
          .warning("Could not update video progress " + stackTrace.toString());
    });
  }

  Stream<dynamic> _getBroadcastStream() {
    if (_updateStream == null) {
      _updateStream = _eventChannel.receiveBroadcastStream();
    }
    return _updateStream;
  }

  void disableListeningForProgress() {
    if (streamSubscription != null) {
      streamSubscription.cancel();
      streamSubscription = null;
    }
  }
}
