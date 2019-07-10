import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ws/database/channel_favorite_entity.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/model/video_rating.dart';
import 'package:flutter_ws/platform_channels/download_manager_flutter.dart';
import 'package:flutter_ws/platform_channels/video_preview_manager.dart';
import 'package:flutter_ws/platform_channels/video_progress_manager.dart';
import 'package:flutter_ws/util/rating_download_util.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class VideoListState {
  VideoListState(this.extendetListTiles, this.previewImages);
  Set<String> extendetListTiles;
  Map<String, Image> previewImages;
}

class AppState {
  AppState(this.downloadManager, this.databaseManager, this.videoPreviewManager,
      this.progressManager, this.favoriteChannels, this.ratingCache);

  DownloadManager downloadManager;
  DatabaseManager databaseManager;
  VideoProgressManager progressManager;
  VideoPreviewManager videoPreviewManager;
  Map<String, ChannelFavoriteEntity> favoriteChannels;

  //videoId -> Rating
  Map<String, VideoRating> ratingCache;
  Map<String, VideoRating> bestVideosAllTime;
  Map<String, VideoRating> hotVideosToday;

  void setRatingCache(Map<String, VideoRating> cache) {
    ratingCache = cache;
  }

  void setHotVideosToday(Map<String, VideoRating> cache) {
    hotVideosToday = cache;
  }

  void setBestVideosAllTime(Map<String, VideoRating> cache) {
    bestVideosAllTime = cache;
  }
}

class _InheritedWidget extends InheritedWidget {
  final AppSharedState data;

  _InheritedWidget({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedWidget old) {
    return true;
  }
}

class AppSharedStateContainer extends StatefulWidget {
  final Widget child;
  final VideoListState videoListState;
  final AppState appState;

  AppSharedStateContainer(
      {@required this.child, this.videoListState, this.appState});

  static AppSharedState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedWidget)
            as _InheritedWidget)
        .data;
  }

  @override
  AppSharedState createState() => new AppSharedState();
}

class AppSharedState extends State<AppSharedStateContainer> {
  final Logger logger = new Logger('VideoWidget');

  VideoListState videoListState;
  AppState appState;

  @override
  Widget build(BuildContext context) {
    logger.fine("Rendering StateContainerState");
    return new _InheritedWidget(
      data: this,
      child: widget.child,
    );
  }

  void initializeState(BuildContext context) {
    if (appState == null) {
      DownloadManager downloadManager = new DownloadManager(context);

      DatabaseManager databaseManager = new DatabaseManager();
      appState = new AppState(
          downloadManager,
          databaseManager,
          new VideoPreviewManager(context),
          new VideoProgressManager(context, databaseManager),
          new Map(),
          new Map());

      //load ratings only once on application start to reduce requests to backend(costly). Operate on cache when doing ratings.
      loadRatings();

      initializeDatabase().then((init) {
        //start subscription to Flutter Download Manager
        downloadManager.startListeningToDownloads();

        //check for downloads that have been completed while flutter app was not running
        downloadManager.syncCompletedDownloads();

        //check for failed DownloadTasks and retry them
        downloadManager.retryFailedDownloads();

        prefillFavoritedChannels();
      });
    }
    if (videoListState == null) {
      _initializeListState();
    }
  }

  void loadRatings() {
    // All ratings needed for local rating operations
    RatingUtil.loadAllRatings().then((ratings) {
      logger
          .info("All ratings retrieved. Amount: " + ratings.length.toString());

      if (ratings.length == 0) {
        return;
      }

      appState.setRatingCache(ratings);
    });
  }

  void prefillFavoritedChannels() async {
    Set<ChannelFavoriteEntity> channels =
        await appState.databaseManager.getAllChannelFavorites();
    logger.fine("There are " +
        channels.length.toString() +
        " favorited channels in the database");
    channels.forEach((entity) =>
        appState.favoriteChannels.putIfAbsent(entity.name, () => entity));
  }

  Future initializeDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "demo.db");
    //Uncomment when having made changes to the DB Schema
    //appState.databaseManager.deleteDb(path);
    //appState.databaseManager.deleteDb(join(documentsDirectory.path, "task.db"));
    return appState.databaseManager.open(path).then(
          (dynamic) => logger.info("Successfully opened database"),
          onError: (e) => logger.severe("Error when opening database"),
        );
  }

  void _initializeListState() {
    videoListState = new VideoListState(new Set(), new Map());
  }

  void addImagePreview(String videoId, Image preview) {
    logger.fine("Adding preview image to state for video with id " + videoId);
    videoListState.previewImages.putIfAbsent(videoId, () => preview);
  }

  void updateExtendetListTile(String videoId) {
    videoListState.extendetListTiles.contains(videoId)
        ? videoListState.extendetListTiles.remove(videoId)
        : videoListState.extendetListTiles.add(videoId);
  }
}
