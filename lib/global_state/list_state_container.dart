import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/channel_favorite_entity.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/download_manager_flutter.dart';
import 'package:flutter_ws/platform_channels/filesystem_permission_manager.dart';
import 'package:flutter_ws/platform_channels/samsung_tv_cast_manager.dart';
import 'package:flutter_ws/platform_channels/video_preview_manager.dart';
import 'package:flutter_ws/util/device_information.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoListState {
  VideoListState(this.extendetListTiles, this.previewImages);
  Set<String> extendetListTiles;
  Map<String, Image> previewImages;
}

class AppState {
  AppState(
      this.downloadManager,
      this.databaseManager,
      this.videoPreviewManager,
      this.filesystemPermissionManager,
      this.samsungTVCastManager,
      this.isCurrentlyPlayingOnTV,
      this.tvCurrentlyPlayingVideo,
      this.availableTvs,
      this.favoriteChannels);

  TargetPlatform targetPlatform;
  Directory localDirectory;
  DownloadManager downloadManager;
  DatabaseManager databaseManager;
  VideoPreviewManager videoPreviewManager;
  FilesystemPermissionManager filesystemPermissionManager;
  SharedPreferences sharedPreferences;

  // only relevant on Android, always true on other platforms
  bool hasFilesystemPermission;
  Map<String, ChannelFavoriteEntity> favoriteChannels;

  // Samsung TV cast
  SamsungTVCastManager samsungTVCastManager;
  bool isCurrentlyPlayingOnTV;
  Video tvCurrentlyPlayingVideo;
  List<String> availableTvs;

  void setHasFilesystemPermission(bool permission) {
    hasFilesystemPermission = permission;
  }

  void setTargetPlatform(TargetPlatform platform) {
    targetPlatform = platform;
  }

  void setDirectory(Directory dir) {
    localDirectory = dir;
  }

  void setSharedPreferences(SharedPreferences preferences) {
    sharedPreferences = preferences;
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

  void initializeState(BuildContext context) async {
    if (videoListState == null) {
      _initializeListState();
    }

    if (appState != null) {
      return;
    }

    DownloadManager downloadManager = new DownloadManager(context);
    WidgetsFlutterBinding.ensureInitialized();
    FlutterDownloader.initialize();

    DatabaseManager databaseManager = new DatabaseManager();
    var filesystemPermissionManager = new FilesystemPermissionManager(context);

    appState = new AppState(
        downloadManager,
        databaseManager,
        new VideoPreviewManager(context),
        filesystemPermissionManager,
        new SamsungTVCastManager(context),
        false,
        new Video(""),
        new List(),
        new Map());

    // async execution to concurrently open database
    DeviceInformation.getTargetPlatform().then((platform) async {
      appState.setTargetPlatform(platform);

      bool hasPermission = true;
      if (platform == TargetPlatform.android) {
        hasPermission =
            await filesystemPermissionManager.hasFilesystemPermission();
      }

      appState.setHasFilesystemPermission(hasPermission);

      Directory directory;
      if (platform == TargetPlatform.iOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getExternalStorageDirectory();
      }
      appState.setDirectory(directory);

      // create thumbnail directory
      final Directory thumbnailDirectory =
          Directory('${directory.path}/MediathekView/thumbnails/');

      if (!await thumbnailDirectory.exists()) {
        //if folder already exists return path
        await thumbnailDirectory.create(recursive: true).catchError((error) =>
            logger.info(
                "Failed to create thumbnail directory " + error.toString()));
      }
    });

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
