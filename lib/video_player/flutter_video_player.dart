import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/database/video_progress_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/video_player/custom_chewie_player.dart';
import 'package:flutter_ws/video_player/custom_video_controls.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class FlutterVideoPlayer extends StatefulWidget {
  String videoUrl;
  String videoId;
  Video video;
  VideoEntity videoEntity;
  VideoPlayerController controller;
  CustomChewieController chewieController;
  DatabaseManager databaseManager;
  VideoProgressEntity progressEntity;
  AppSharedState appSharedState;
  final Logger log = new Logger('FlutterVideoPlayer');

  final Logger logger = new Logger('FlutterVideoPlayer');

  FlutterVideoPlayer(AppSharedState appSharedState, Video video,
      VideoEntity entity, VideoProgressEntity progress) {
    this.video = video;
    this.videoEntity = entity;
    this.videoId = video != null ? video.id : entity.id;
    this.videoUrl = video != null ? video.url_video : entity.url_video;
    this.databaseManager = appSharedState.appState.databaseManager;
    this.progressEntity = progress;
    this.appSharedState = appSharedState;
    initVideoPlayerController();
  }

  void initVideoPlayerController() {
    if (video != null) {
      controller = VideoPlayerController.network(
        videoUrl,
      );
    } else {
      Uri videoUri = new Uri.file(
          appSharedState.appState.iOsDocumentsDirectory.path +
              "/MediathekView" +
              "/" +
              videoEntity.fileName);
      File file = File.fromUri(videoUri);
      file.exists().then(
        (exists) {
          if (!exists) {
            log.severe("Cannot play video from file. File does not exist: " +
                file.uri.toString());
            controller = VideoPlayerController.network(
              videoUrl,
            );
          }
        },
      );

      controller = VideoPlayerController.file(file);
    }
  }

  @override
  _FlutterVideoPlayerState createState() => _FlutterVideoPlayerState();
}

class _FlutterVideoPlayerState extends State<FlutterVideoPlayer> {
  @override
  void initState() {
    buildControllers();
    super.initState();
  }

  void buildControllers() async {
    widget.controller
      ..addListener(() {
        final bool isPlaying = widget.controller.value.isPlaying;
        final int position = widget.controller.value.position.inMilliseconds;
        if (isPlaying) {
          widget.logger.info("VideoPlayback position:" + position.toString());
          Wakelock.enable();
          widget.databaseManager
              .getVideoProgressEntity(widget.videoId)
              .then((entity) {
            if (entity == null) {
              // insert into database containing all the video information
              insertVideoProgress(position);
            } else {
              updateVideoProgress(position);
            }
          });
        }
      });

    widget.chewieController = new CustomChewieController(
        videoPlayerController: widget.controller,
        autoPlay: true,
        looping: true,
        startAt: widget.progressEntity != null
            ? new Duration(milliseconds: widget.progressEntity.progress)
            : new Duration(milliseconds: 0),
        customControls: new CustomVideoControls(
            backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
            iconColor: Color(0xffffbf00)),
        fullScreenByDefault: true);
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new CustomChewie(
        controller: widget.chewieController,
      ),
    );
  }

  void insertVideoProgress(int position) {
    // insert into database containing all the video information
    VideoProgressEntity videoProgress = widget.video != null
        ? VideoProgressEntity.fromMap(widget.video.toMap())
        : VideoProgressEntity.fromMap(widget.videoEntity.toMap());

    videoProgress.progress = position;
    widget.databaseManager.insertVideoProgress(videoProgress).then((rowId) {
      widget.logger.info(
          "Successfully inserted progress entity for video " + widget.videoId);
    }, onError: (err, stackTrace) {
      widget.logger
          .warning("Could not insert video progress " + stackTrace.toString());
    });
  }

  void updateVideoProgress(int position) {
    widget.databaseManager
        .updateVideoProgressEntity(
            new VideoProgressEntity(widget.videoId, position))
        .then((rowsUpdated) {
      if (rowsUpdated < 1) {
        widget.logger
            .warning("Could not update video progress. Rows Updated < 1");
        return;
      }
    }, onError: (err, stackTrace) {
      widget.logger
          .warning("Could not update video progress " + stackTrace.toString());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
