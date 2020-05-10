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

import 'TVPlayerController.dart';

class FlutterVideoPlayer extends StatefulWidget {
  String videoId;
  Video video;
  VideoEntity videoEntity;
  CustomChewieController chewieController;
  DatabaseManager databaseManager;
  VideoProgressEntity progressEntity;
  AppSharedState appSharedState;
  bool isAlreadyPlayingDifferentVideoOnTV = false;

  final Logger log = new Logger('FlutterVideoPlayer');

  final Logger logger = new Logger('FlutterVideoPlayer');

  FlutterVideoPlayer(BuildContext context, AppSharedState appSharedState,
      Video video, VideoEntity entity, VideoProgressEntity progress) {
    this.video = video;
    this.videoId = video != null ? video.id : entity.id;
    this.databaseManager = appSharedState.appState.databaseManager;
    this.progressEntity = progress;
    this.videoEntity = entity;
    this.appSharedState = appSharedState;

    if (appSharedState.appState.isCurrentlyPlayingOnTV &&
        videoId != appSharedState.appState.tvCurrentlyPlayingVideo.id) {
      isAlreadyPlayingDifferentVideoOnTV = true;
    }
  }

  @override
  _FlutterVideoPlayerState createState() => _FlutterVideoPlayerState();
}

class _FlutterVideoPlayerState extends State<FlutterVideoPlayer> {
  String videoUrl;
  // castNewVideoToTV indicates that the currently playing video on the TV
  // should be replaced
  bool castNewVideoToTV = false;
  static VideoPlayerController videoController;
  static TvPlayerController tvVideoController;

  @override
  Widget build(BuildContext context) {
    if (widget.isAlreadyPlayingDifferentVideoOnTV) {
      return _showDialog(context);
    }

    this.videoUrl = getVideoUrl(widget.video, widget.videoEntity);
    initVideoPlayerController(context);
    initTvVideoController();
    initChewieController();

    return new Scaffold(
        backgroundColor: Colors.grey[800],
        body: new Container(
          child: new CustomChewie(
            controller: widget.chewieController,
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }

  String getVideoUrl(Video video, VideoEntity entity) {
    if (video != null) {
      if (video.url_video_hd != null && video.url_video_hd.isNotEmpty) {
        return video.url_video_hd;
      } else {
        return video.url_video;
      }
    } else {
      if (entity.url_video_hd != null && entity.url_video_hd.isNotEmpty) {
        return entity.url_video_hd;
      } else {
        return entity.url_video;
      }
    }
  }

  void initTvVideoController() {
    tvVideoController = new TvPlayerController(
      widget.appSharedState.appState.availableTvs,
      widget.appSharedState.appState.samsungTVCastManager,
      widget.appSharedState.appState.databaseManager,
      videoUrl,
      widget.video != null
          ? widget.video
          : Video.fromMap(widget.videoEntity.toMap()),
      widget.progressEntity != null
          ? new Duration(milliseconds: widget.progressEntity.progress)
          : new Duration(milliseconds: 0),
    );

    tvVideoController.startTvDiscovery();

    // replace the currently playing video on TV
    if (widget.appSharedState.appState.isCurrentlyPlayingOnTV &&
        castNewVideoToTV) {
      widget.appSharedState.appState.samsungTVCastManager.stop();
      tvVideoController.initialize();
      tvVideoController.startPlayingOnTV();
      return;
    }

    // case: do not replace the currently playing video on TV
    if (widget.appSharedState.appState.isCurrentlyPlayingOnTV) {
      tvVideoController.initialize();
    }
  }

  void initVideoPlayerController(BuildContext context) {
    if (videoController != null) {
      videoController.dispose();
    }
    // always use network datasource if should be casted to TV
    // TV needs accessible video URL
    if (widget.videoEntity == null ||
        widget.appSharedState.appState.isCurrentlyPlayingOnTV &&
            widget.video != null) {
      videoController = VideoPlayerController.network(
        videoUrl,
      );
      return;
    }

    String path;
    if (widget.appSharedState.appState.targetPlatform ==
        TargetPlatform.android) {
      path = widget.videoEntity.filePath + "/" + widget.videoEntity.fileName;
    } else {
      path = widget.appSharedState.appState.iOsDocumentsDirectory.path +
          "/MediathekView" +
          "/" +
          widget.videoEntity.fileName;
    }

    Uri videoUri = new Uri.file(path);

    File file = File.fromUri(videoUri);
    file.exists().then(
      (exists) {
        if (!exists) {
          widget.log.severe(
              "Cannot play video from file. File does not exist: " +
                  file.uri.toString());
          videoController = VideoPlayerController.network(
            videoUrl,
          );
        }
      },
    );

    videoController = VideoPlayerController.file(file);
  }

  void initChewieController() {
    widget.chewieController = new CustomChewieController(
        context: context,
        videoPlayerController: videoController,
        tvPlayerController: tvVideoController,
        looping: false,
        startAt: tvVideoController.startAt,
        customControls: new CustomVideoControls(
            backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
            iconColor: Color(0xffffbf00)),
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        isCurrentlyPlayingOnTV:
            widget.appSharedState.appState.isCurrentlyPlayingOnTV,
        video: widget.video != null
            ? widget.video
            : Video.fromMap(widget.videoEntity.toMap()));
  }

  AlertDialog _showDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[800],
      title: Text('Fernseher Verbunden',
          style: new TextStyle(color: Colors.white, fontSize: 18.0)),
      content: new Text('Soll die aktuelle TV Wiedergabe unterbrochen werden?',
          style: new TextStyle(color: Colors.white, fontSize: 16.0)),
      actions: <Widget>[
        RaisedButton(
          child: const Text('Nein'),
          onPressed: () async {
            widget.isAlreadyPlayingDifferentVideoOnTV = false;
            // replace widget.video with the currently playing video
            // to not interrupt the video playback
            widget.video =
                widget.appSharedState.appState.tvCurrentlyPlayingVideo;

            // get the video entity
            widget.videoEntity = await widget
                .appSharedState.appState.databaseManager
                .getDownloadedVideo(widget.videoId);

            // get the video progress
            widget.progressEntity = await widget
                .appSharedState.appState.databaseManager
                .getVideoProgressEntity(widget.video.id);

            // start initializing players with the video playing on the TV
            setState(() {});
          },
        ),
        RaisedButton(
          child: const Text('Ja'),
          onPressed: () {
            widget.appSharedState.appState.samsungTVCastManager.stop();

            setState(() {
              widget.isAlreadyPlayingDifferentVideoOnTV = false;
              castNewVideoToTV = true;
            });
          },
        )
      ],
    );
  }
}
