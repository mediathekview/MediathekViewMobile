import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/section/live_tv_section.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class NativeVideoPlayer {
  final Logger logger = new Logger('NativeVideoPlayer');
  static NativeVideoPlayer _instance;
  MethodChannel _methodChannel;
  static DatabaseManager databaseManager;

  factory NativeVideoPlayer(DatabaseManager dbManager) {
    if (_instance == null) {
      final MethodChannel channel =
          const MethodChannel('com.mediathekview.mobile/video');

      _instance = new NativeVideoPlayer.private(channel);
      databaseManager = dbManager;
    }
    return _instance;
  }

  @visibleForTesting
  NativeVideoPlayer.private(this._methodChannel);

  Future<void> playVideo(
      {Video video,
      VideoEntity videoEntity,
      String mimeType,
      VideoProgressEntity playbackProgress}) async {
    String path;
    String videoId;
    if (videoEntity != null) {
      path = videoEntity.filePath + "/" + videoEntity.fileName;
      videoId = videoEntity.id;
    } else {
      path = video.url_video;
      videoId = video.id;
    }
    int progress;
    if (playbackProgress == null) {
      progress = 0;
    } else {
      progress = playbackProgress.progress;
    }

    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => path);
      requestArguments.putIfAbsent("videoId", () => videoId);
      requestArguments.putIfAbsent("progress", () => progress.toString());
      await _methodChannel
          .invokeMethod('playVideo', requestArguments)
          .then((v) {
        databaseManager.getVideoProgressEntity(videoId).then((entity) {
          if (entity == null) {
            // insert into database containing all the video information
            VideoProgressEntity videoProgress = video != null
                ? VideoProgressEntity.fromMap(video.toMap())
                : VideoProgressEntity.fromMap(videoEntity.toMap());
            videoProgress.progress = progress;
            databaseManager.insertVideoProgress(videoProgress).then((rowId) {
              logger.info(
                  "Successfully inserted progress entity for video " + videoId);
            }, onError: (err, stackTrace) {
              logger.warning(
                  "Could not insert video progress " + stackTrace.toString());
            });
          } else {
            updateVideoProgress(videoId, progress);
          }
        });
      });
    } on PlatformException catch (e) {
      logger.severe("Platform exception accoured : " + e.toString());
    }
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

  Future<void> playLiveStream(Channel channel) async {
    try {
      Map<String, String> requestArguments = new Map();
      requestArguments.putIfAbsent("filePath", () => channel.url);
      await _methodChannel.invokeMethod('playVideo', requestArguments);
    } on PlatformException catch (e) {
      logger.severe("Platform exception accoured : " + e.toString());
    }
  }
}
