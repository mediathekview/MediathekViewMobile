import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_ws/database/database_manager.dart';
import 'package:flutter_ws/database/video_entity.dart';
import 'package:flutter_ws/global_state/list_state_container.dart';
import 'package:flutter_ws/model/video.dart';
import 'package:flutter_ws/platform_channels/filesystem_permission_manager.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

typedef void onFailed(String videoId);
typedef void onComplete(String videoId);
typedef void onCanceled(String videoId);
typedef void onStateChanged(
    String videoId, DownloadTaskStatus status, double progress);

class DownloadManager {
  final Logger logger = new Logger('DownloadManagerFlutter');
  static const String PERMISSION_DENIED_ID = "-1";
  static const SQL_GET_SINGEL_TASK = "SELECT * FROM task WHERE task_id =";
  static String SQL_GET_ALL_RUNNING_TASKS =
      "SELECT * FROM task WHERE status = " +
          DownloadTaskStatus.enqueued.value.toString() +
          " OR status = " +
          DownloadTaskStatus.running.value.toString() +
          " OR status = " +
          DownloadTaskStatus.paused.value.toString();
  static String SQL_GET_ALL_COMPLETED_TASKS =
      "SELECT * FROM task WHERE status = " +
          DownloadTaskStatus.complete.value.toString();
  static String SQL_GET_ALL_FAILED_TASKS =
      "SELECT * FROM task WHERE status = " +
          DownloadTaskStatus.failed.value.toString();

  //Listeners
  static Map<String, MapEntry<Video, onFailed>> onFailedListeners =
      new Map<String, MapEntry<Video, onFailed>>();
  static Map<String, MapEntry<Video, onComplete>> onCompleteListeners =
      Map<String, MapEntry<Video, onComplete>>();
  static Map<String, MapEntry<Video, onCanceled>> onCanceledListeners =
      Map<String, MapEntry<Video, onCanceled>>();
  static Map<String, MapEntry<Video, onStateChanged>> onStateChangedListeners =
      new Map<String, MapEntry<Video, onStateChanged>>();

  // VideoId -> VideoEntity
  static Map<String, VideoEntity> cache = new Map();

  // TaskID -> VideoId
  static Map<String, String> cacheTask = new Map();

  BuildContext _context;

  AppSharedState appWideState;

  DatabaseManager databaseManager;

  //special case Android: remember Video to be able to resume download after grant of file system permission
  VideoEntity rememberedFailedVideoDownload;

  //remember video that was intended to be downloaded, but permission was missing
  Video downloadVideoRequestWithoutPermission;

  DownloadManager(this._context);

  void stopListeningToDownloads() {
    FlutterDownloader.registerCallback((id, status, progress) {
      return null;
    });
  }

  void startListeningToDownloads() {
    appWideState = AppSharedStateContainer.of(this._context);
    databaseManager = appWideState.appState.databaseManager;

    FlutterDownloader.registerCallback(
      (taskId, status, progress) {
        String videoId = cacheTask[taskId];
        VideoEntity entity = cache[videoId];
        if (entity != null) {
          logger.fine("Cache hit for TaskID -> Entity");
          _notify(taskId, status, progress, databaseManager, entity);
        } else {
          databaseManager
              .getVideoEntityForTaskId(taskId)
              .then((VideoEntity entity) {
            if (entity == null) {
              logger.severe(
                  "Received update for task that we do not know of - Ignoring");
              return;
            }
            _notify(taskId, status, progress, databaseManager, entity);
          });
        }
      },
    );
  }

  void _notify(String taskId, DownloadTaskStatus status, int progress,
      DatabaseManager databaseManager, VideoEntity entity) {
    if (status == DownloadTaskStatus.failed) {
      //delete from schema first in case we want to try downloading video again
      //_deleteVideo(entity);

      FilesystemPermissionManager filesystemPermissionManager =
          new FilesystemPermissionManager(_context);

      filesystemPermissionManager
          .hasFilesystemPermission()
          .then((bool hasPermission) {
        if (!hasPermission) {
          logger.info("Requesting Filesystem Permissions");
          rememberedFailedVideoDownload = entity;

          // subscribe to event stream to catch update - if granted by user then download again
          Stream<dynamic> broadcastStream =
              filesystemPermissionManager.getBroadcastStream();
          broadcastStream.listen(
            (result) {
              String res = result['Granted'];
              bool granted = res.toLowerCase() == 'true';

              if (granted) {
                logger.info("Filesystem permissions got granted");
                //restart download using the remembered video
                downloadFile(
                    Video.fromMap(rememberedFailedVideoDownload.toMap()));
              } else {
                logger.info("Filesystem Permission denied by User");
              }
            },
            onError: (e) {
              logger.severe(
                  "Listening to User Action regarding Android file system permission failed. Reason " +
                      e.toString());
              //TODO cancel subscription to stream
            },
          );

          //then ask for user permission
          filesystemPermissionManager
              .askUserForPermission()
              .then((bool successfullyAsked) {
            if (!successfullyAsked) {
              logger.severe(
                  "Failed to ask for Filesystem Permissions after failed video download");
            }
          });
        } else {
          // we already got proper filesystem permission - other cause
          logger.fine(
              "Download for video failed & filesystem permission granted");
          deleteVideo(entity.id);
          MapEntry<Video, onFailed> entry = onFailedListeners[entity.id];
          if (entry != null) {
            entry.value(entity.id);
          }
        }
      });
    } else if (status == DownloadTaskStatus.canceled) {
      deleteVideo(entity.id);
      MapEntry<Video, onCanceled> entry = onCanceledListeners[entity.id];
      if (entry != null) {
        entry.value(entity.id);
      }
    } else if (status == DownloadTaskStatus.complete) {
      //status now includes data that we want to add to the entity
      FlutterDownloader.loadTasksWithRawQuery(
              query: SQL_GET_SINGEL_TASK + "'" + taskId + "'")
          .then((List<DownloadTask> list) {
        DownloadTask task = list.elementAt(0);
        entity.filePath = task.savedDir;
        entity.fileName = task.filename;
        entity.timestamp_video_saved =
            new DateTime.now().millisecondsSinceEpoch;
        databaseManager.updateVideoEntity(entity).then((rowsUpdated) {
          logger.fine("Updated " + rowsUpdated.toString() + " relations.");
        });
        //also update cache
        cache.update(entity.id, (oldEntity) => entity);
      });

      MapEntry<Video, onComplete> entry = onCompleteListeners[entity.id];
      if (entry != null) {
        entry.value(entity.id);
      }
    } else if (status == DownloadTaskStatus.enqueued ||
        status == DownloadTaskStatus.running ||
        status == DownloadTaskStatus.paused &&
            onStateChangedListeners.isNotEmpty) {
      MapEntry<Video, onStateChanged> entry =
          onStateChangedListeners[entity.id];
      if (entry != null) {
        entry.value(entity.id, status, progress.toDouble());
      } else {
        logger.fine("No subscriber found for progress update. Video: " +
            entity.title +
            " id: " +
            entity.id);
      }
    }
  }

  // Check first if a entity with that id exists on the db or cache. If yes & task id is set, check Task schema for running, queued or paused status
  Future<DownloadTask> isCurrentlyDownloading(String videoId) async {
    return _getEntityForId(videoId).then((entity) {
      if (entity == null || entity.task_id == '') {
        return null;
      }
      // if already has a filename, then it is already downloaded!
      if (entity.fileName != null && entity.fileName != '') {
        return null;
      }

      //check for right task status
      return FlutterDownloader.loadTasksWithRawQuery(
              query: SQL_GET_SINGEL_TASK + "'" + entity.task_id + "'")
          .then((List<DownloadTask> list) {
        if (list.isEmpty) {
          return null;
        }
        var task = list.first;

        if (task.status == DownloadTaskStatus.running ||
            task.status == DownloadTaskStatus.enqueued ||
            task.status == DownloadTaskStatus.paused) {
          return task;
        }
        return null;
      });
    });
  }

  //Check in DB only if the VideoEntity has a filename associated with it
  Future<bool> isAlreadyDownloaded(String videoId) async {
    return _getEntityForId(videoId).then((entity) {
      if (entity == null || entity.task_id == '') {
        return false;
      }
      // if it has a filename, then it is already downloaded!
      if (entity.fileName != null && entity.fileName != '') {
        return true;
      }
      return false;
    });
  }

  Future<VideoEntity> _getEntityForId(String videoId) async {
    VideoEntity entity = cache[videoId];
    if (entity != null) {
      logger.fine("Cache hit for VideoId -> Entity");
      return entity;
    } else {
      return databaseManager.getVideoEntity(videoId).then((VideoEntity entity) {
        if (entity == null) {
          return null;
        }
        return entity;
      });
    }
  }

  //Delete all in one: as task & file & from VideoEntity schema
  Future<bool> deleteVideo(String videoId) async {
    cache[videoId] = null;
    return _getEntityForId(videoId).then((entity) {
      if (entity == null) {
        logger.severe("Video with id " +
            videoId +
            " does not exist. Cannot fetch taskID to remove it via Downloader from tasks db and local file storage");
        return false;
      }
      return _cancelDownload(entity.task_id)
          .then((dummy) => _deleteVideo(entity));
    });
  }

  Future<bool> _deleteVideo(VideoEntity entity) async {
    return _deleteFromVideoSchema(entity.id).then((deleted) {
      if (deleted == null) {
        return false;
      }

      return _deleteFromFilesystem(entity);
    });
  }

  Future<bool> _deleteFromFilesystem(VideoEntity entity) async {
    if (entity.filePath == null || entity.filePath == '') {
      return true;
    }

    Directory storageDirectory = Directory(entity.filePath);

    if (!await storageDirectory.exists()) {
      logger.severe("Trying to delete video from path that does not exist: " +
          storageDirectory.uri.toString());
    }
    Uri filepath =
        new Uri.file(storageDirectory.uri.toFilePath() + "/" + entity.fileName);
    File fileToBeDeleted = File.fromUri(filepath);

    if (!await fileToBeDeleted.exists()) {
      logger.severe(
          "Trying to delete video from filepath that does not exist: " +
              fileToBeDeleted.uri.toString());
    }

    return fileToBeDeleted.delete().then((FileSystemEntity file) {
      logger.info("Successfully deleted file" +
          file.path +
          " exists: " +
          file.existsSync().toString());
      return true;
    }, onError: (e) {
      logger.severe("Error when deleting file from disk: " +
          fileToBeDeleted.uri.toString() +
          " Error: " +
          e.toString());
      return false;
    });
  }

  Future<int> _deleteFromVideoSchema(String videoId) {
    return databaseManager.deleteVideoEntity(videoId).then((int rowsAffected) {
      return rowsAffected;
    }, onError: (e) {
      logger.severe("Error when deleting video from 'VideoEntity' schema");
      return 0;
    });
  }

  // Remove from task schema and cancel download if running
  Future _cancelDownload(String taskId) {
    logger.fine("Deleting Task with id " + taskId);
    return FlutterDownloader.cancel(taskId: taskId).then((_) =>
        FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: false));
  }

  void subscribe(
      Video video,
      onStateChanged onDownloadStateChanged,
      onComplete onDownloadComplete,
      onFailed onDownloadFailed,
      onCanceled onDownloadCanceled) {
    logger.fine("Subscribing on updates for video with name: " +
        video.title +
        " and id " +
        video.id);
    onFailedListeners.putIfAbsent(
        video.id, () => new MapEntry(video, onDownloadFailed));
    onCompleteListeners.putIfAbsent(
        video.id, () => new MapEntry(video, onDownloadComplete));
    onStateChangedListeners.putIfAbsent(
        video.id, () => new MapEntry(video, onDownloadStateChanged));
    onCanceledListeners.putIfAbsent(
        video.id, () => new MapEntry(video, onDownloadCanceled));
  }

  void cancelSubscription(String videoId) {
    logger.fine("Cancel subscribtion on updates for video with id: " + videoId);

    onFailedListeners.remove(videoId);
    onCompleteListeners.remove(videoId);
    onStateChangedListeners.remove(videoId);
    onCanceledListeners.remove(videoId);
  }

  Future<Set<VideoEntity>> getCurrentDownloads() async {
    return _getCurrentDownloadTasks().then((tasks) async {
      if (tasks.isEmpty) {
        return new Set();
      }
      return databaseManager.getVideoEntitiesForTaskIds(
          tasks.map((task) => task.taskId).toList());
    });
  }

  Future<List<DownloadTask>> _getCurrentDownloadTasks() async {
    return _getTasksWithRawQuery(SQL_GET_ALL_RUNNING_TASKS);
  }

  Future<List<DownloadTask>> _getFailedTasks() async {
    return _getTasksWithRawQuery(SQL_GET_ALL_FAILED_TASKS);
  }

  Future<List<DownloadTask>> _getCompletedTasks() async {
    return _getTasksWithRawQuery(SQL_GET_ALL_COMPLETED_TASKS);
  }

  Future<List<DownloadTask>> _getTasksWithRawQuery(String query) async {
    return FlutterDownloader.loadTasksWithRawQuery(query: query)
        .then((List<DownloadTask> list) {
      if (list == null) {
        return new List();
      }
      return list;
    });
  }

  //sync completeed DownloadTasks from DownloadManager with VideoEntity - filename and storage location
  syncCompletedDownloads() {
    _getCompletedTasks().then((List<DownloadTask> task) {
      task.forEach((DownloadTask task) {
        databaseManager
            .getVideoEntityForTaskId(task.taskId)
            .then((VideoEntity entity) {
          if (entity == null) {
            logger.severe(
                "Startup sync for completed downloads: task that we do not know of - Ignoring. URL: : " +
                    task.url);
            return;
          }
          if (entity.filePath == null || entity.fileName == null) {
            logger.info(
                "Found download tasks that was completed while flutter app was not running. Syncing with VideoEntity Schema. Title: " +
                    entity.title);
            entity.filePath = task.savedDir;
            entity.fileName = task.filename;
            databaseManager.updateVideoEntity(entity).then((rowsUpdated) {
              logger.fine("Updated " + rowsUpdated.toString() + " relations.");
            });
          }
          //also update cache
          cache.putIfAbsent(entity.id, () => entity);
        });
      });
    });
  }

  retryFailedDownloads() {
    _getFailedTasks().then((List<DownloadTask> taskList) {
      taskList.forEach((DownloadTask task) {
        databaseManager.getVideoEntityForTaskId(task.taskId).then(
          (VideoEntity entity) {
            if (entity == null) {
              logger.severe(
                  "Startup sync for failed downloads: task that we do not know of - Ignoring. URL: : " +
                      task.url);
              return;
            }

            //only retry for downloads we know about
            logger.info("Retrying failed download with url " + task.url);
            FlutterDownloader.retry(taskId: task.taskId);
          },
        );
      });
    });
  }

  Future<Video> downloadFile(Video video) async {
    Uri videoUrl = Uri.parse(video.url_video);

    Directory externalDir = await getExternalStorageDirectory();
    Directory storageDirectory = Directory(externalDir.path + "/MediathekView");
    storageDirectory.createSync();

    // same as video id if provided
    String taskId = await FlutterDownloader.enqueue(
      url: videoUrl.toString(),
      savedDir: storageDirectory
          .path, //  getFileNameForVideo(video.id, video.url_video, video.title)
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          true, // click on notification to open downloaded file (for Android)
    );

    logger.fine("Requested download of video with id " +
        video.id +
        " and url " +
        video.url_video);

    //Insert into db with taskId. Once finsihed downloading, the filepath and filename will be updated
    DatabaseManager databaseManager = appWideState.appState.databaseManager;
    VideoEntity entity = VideoEntity.fromVideo(video);
    entity.task_id = taskId;
    //make sure to not insert duplicate if not deleted properly before
    _deleteFromVideoSchema(entity.id).then((int rowsDeleted) {
      if (rowsDeleted > 0) {
        logger.warning(
            "Had to delete video from 'Video' schema before downloading new video - this should not happen. It should have been deleted before.");
      }
    });
    databaseManager.insert(entity).then((data) {
      logger.fine("Added currently downloading video to Database");
      cache.putIfAbsent(video.id, () {
        return entity;
      });
    });

    cacheTask.putIfAbsent(taskId, () {
      return video.id;
    });
    return video;
  }
}
